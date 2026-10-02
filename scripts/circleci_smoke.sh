#!/usr/bin/env bash
# One disposable-emulator, no-auth smoke. No login, production service, or APK upload.
set -Eeuo pipefail
umask 077

readonly ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
readonly OUT="$ROOT/build/ci-smoke"
mkdir -p "$OUT/test-results" "$OUT/maestro"
exec > >(tee "$OUT/runner.log") 2>&1

STAGE=preflight
EMULATOR_PID=""
EMULATOR_STARTED=false
readonly SERIAL=emulator-5554
export ANDROID_SERIAL="$SERIAL"

finish() {
  local status=$?
  trap - EXIT INT TERM
  set +e
  printf 'exit_code=%s\nstage=%s\nfinished_at=%s\n' "$status" "$STAGE" "$(date -u +%FT%TZ)" > "$OUT/result.txt"
  if [[ "$EMULATOR_STARTED" == true ]]; then
    timeout 15s adb -s "$SERIAL" logcat -d -v threadtime > "$OUT/logcat.txt" 2>&1
    timeout 15s adb -s "$SERIAL" exec-out screencap -p > "$OUT/final-screen.png" 2> "$OUT/screenshot-error.txt"
    timeout 10s adb -s "$SERIAL" shell dumpsys activity activities > "$OUT/activities.txt" 2>&1
    timeout 10s adb -s "$SERIAL" emu kill > "$OUT/emulator-stop.txt" 2>&1
    [[ -z "$EMULATOR_PID" ]] || kill "$EMULATOR_PID" 2>/dev/null
  fi
  printf 'Smoke finished: stage=%s exit=%s\n' "$STAGE" "$status"
  exit "$status"
}
trap finish EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
step() { STAGE="$1"; printf '\n[%s] %s\n' "$(date -u +%FT%TZ)" "$STAGE"; }

# Verify before downloading tools or compiling. Use the NEW trial commit, not the
# unavailable laptop base SHA or the old main/release-hardening SHA.
[[ "${CIRCLECI:-}" == true ]] || die 'Run only in the isolated CircleCI machine job.'
[[ "${EXPECTED_SOURCE_SHA:-}" =~ ^[0-9a-f]{40}$ ]] || die 'expected_source_sha must be a full lowercase 40-character commit SHA.'
[[ "${CIRCLE_BRANCH:-}" == "${EXPECTED_TRIAL_BRANCH:-ci/memorylink-circleci-trial-20261002}" ]] || die 'Wrong branch.'
ACTUAL_SHA="$(git rev-parse HEAD)"
[[ "$ACTUAL_SHA" == "$EXPECTED_SOURCE_SHA" && "${CIRCLE_SHA1:-}" == "$EXPECTED_SOURCE_SHA" ]] || die 'Checkout does not match the approved trial commit.'
git diff --quiet && git diff --cached --quiet || die 'Tracked checkout is dirty.'
printf 'commit=%s\nbranch=%s\nstarted_at=%s\n' "$ACTUAL_SHA" "$CIRCLE_BRANCH" "$(date -u +%FT%TZ)" > "$OUT/source.txt"
[[ "$(uname -m)" == x86_64 ]] || die 'This trial requires x86_64.'
[[ -c /dev/kvm && -r /dev/kvm && -w /dev/kvm ]] || die 'Accessible /dev/kvm is required; do not fall back to slow software emulation.'
for tool in git curl unzip python3 timeout sha256sum java; do
  command -v "$tool" >/dev/null || die "Missing required tool: $tool"
done
[[ -f android/app/google-services.json ]] || die 'Reviewed dummy google-services.json is missing. Do not retrieve production credentials.'
[[ -f android/app/proguard-rules.pro ]] || die 'Restore the reviewed public ProGuard rules before this trial.'
[[ -f capstone_project_plan_renewal.md ]] || die 'Restore the required documentation with provenance before the full test gate.'

step setup
readonly TOOLS="$(mktemp -d /tmp/memorylink-ci-tools.XXXXXX)"
# Select image-provided Java 17 where available; no system package or permission changes.
for candidate in "${JAVA_HOME_17_X64:-}" /usr/lib/jvm/java-17-openjdk-amd64; do
  if [[ -n "$candidate" && -x "$candidate/bin/java" ]]; then export JAVA_HOME="$candidate"; break; fi
done
if [[ -z "${JAVA_HOME:-}" ]]; then JAVA_HOME="$(dirname "$(dirname "$(readlink -f "$(command -v java)")")")"; export JAVA_HOME; fi
export PATH="$JAVA_HOME/bin:$PATH"
java -version
JAVA_MAJOR="$(java -version 2>&1 | sed -n 's/.*version "\([0-9]*\).*/\1/p' | head -n 1)"
[[ "$JAVA_MAJOR" =~ ^[0-9]+$ && "$JAVA_MAJOR" -ge 17 ]] || die 'Java 17 or newer is required.'

export ANDROID_HOME="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
[[ -n "$ANDROID_HOME" && -d "$ANDROID_HOME" ]] || die 'Android machine image SDK is missing.'
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH"
for tool in sdkmanager avdmanager adb emulator; do command -v "$tool" >/dev/null || die "Missing Android tool: $tool"; done
timeout 20s emulator -accel-check > "$OUT/kvm.txt" 2>&1
# CircleCI supplies accepted SDK licenses. Fail rather than auto-accept new terms.
timeout 8m sdkmanager --install 'platform-tools' 'emulator' 'platforms;android-36' 'build-tools;36.0.0' 'system-images;android-33;google_apis;x86_64' </dev/null

readonly FLUTTER_REVISION=2c9eb20739dfec95e2c74bd3dfa4601b0a8a36aa
GIT_TERMINAL_PROMPT=0 timeout 5m git -c credential.helper= clone --depth 1 --branch 3.41.5 https://github.com/flutter/flutter.git "$TOOLS/flutter"
[[ "$(git -C "$TOOLS/flutter" rev-parse HEAD)" == "$FLUTTER_REVISION" ]] || die 'Flutter 3.41.5 revision changed.'
export PATH="$TOOLS/flutter/bin:$PATH"
export CI=true FLUTTER_SUPPRESS_ANALYTICS=true DART_SUPPRESS_ANALYTICS=true
timeout 5m flutter --version --machine > "$OUT/flutter-version.json"
timeout 60s flutter config --no-analytics --jdk-dir "$JAVA_HOME"

readonly MAESTRO_VERSION=2.11.0
readonly MAESTRO_SHA256=5384593cb4e7a106489e75a821d157dd43f4e438df6bc308b72e82c685e1283a
timeout 5m curl --fail --location --retry 2 --connect-timeout 20 --max-time 240 "https://github.com/mobile-dev-inc/Maestro/releases/download/cli-$MAESTRO_VERSION/maestro.zip" -o "$TOOLS/maestro.zip"
printf '%s  %s\n' "$MAESTRO_SHA256" "$TOOLS/maestro.zip" | sha256sum --check -
unzip -q "$TOOLS/maestro.zip" -d "$TOOLS"
export PATH="$TOOLS/maestro/bin:$PATH"
export MAESTRO_CLI_NO_ANALYTICS=1
timeout 60s maestro --version > "$OUT/maestro-version.txt"
grep -F "$MAESTRO_VERSION" "$OUT/maestro-version.txt" >/dev/null || die 'Unexpected Maestro version.'

# The project requests an 8 GiB Gradle heap, exceeding medium's 7.5 GiB RAM.
# User-home properties take precedence; constrain only this disposable job.
export GRADLE_USER_HOME="$TOOLS/gradle-home"
mkdir -p "$GRADLE_USER_HOME"
cat > "$GRADLE_USER_HOME/gradle.properties" <<'GRADLE'
org.gradle.jvmargs=-Xmx2048m -XX:MaxMetaspaceSize=768m -XX:ReservedCodeCacheSize=256m
org.gradle.workers.max=2
org.gradle.daemon=false
kotlin.daemon.jvm.options=-Xmx512m
GRADLE

step dependencies
timeout 8m flutter pub get --enforce-lockfile
git diff --exit-code -- pubspec.lock

# A smoke does not replace the pre-push full-suite gate. Keep these assertions and
# the existing tests intact; do not publish until the sanitized fixture issues pass.
step analyze
timeout 5m flutter analyze --no-fatal-infos
step unit-and-widget-tests
timeout 8m flutter test --reporter expanded

step debug-build
timeout 15m flutter build apk --debug --dart-define=IS_EMULATOR=true --target-platform android-x64
readonly APK="$ROOT/build/app/outputs/flutter-apk/app-debug.apk"
[[ -s "$APK" ]] || die 'APK not produced.'
sha256sum "$APK" > "$OUT/apk-sha256.txt"
# Never copy the APK into OUT. Only logs, reports, and synthetic emulator screenshots.

step emulator-boot
export ANDROID_AVD_HOME="$TOOLS/avd"
mkdir -p "$ANDROID_AVD_HOME"
printf 'no\n' | timeout 60s avdmanager create avd --name memorylink-smoke --package 'system-images;android-33;google_apis;x86_64' --device pixel_6
emulator -avd memorylink-smoke -port 5554 -no-window -no-audio -no-boot-anim -no-snapshot -wipe-data -gpu swiftshader_indirect -memory 2048 -cores 2 > "$OUT/emulator.txt" 2>&1 &
EMULATOR_PID=$!
EMULATOR_STARTED=true
timeout 180s adb -s "$SERIAL" wait-for-device
timeout 180s bash -c 'until [[ "$(adb -s "$ANDROID_SERIAL" shell getprop sys.boot_completed 2>/dev/null | tr -d "\r")" == 1 ]]; do sleep 2; done'
timeout 15s adb -s "$SERIAL" shell input keyevent 82
timeout 10s adb -s "$SERIAL" shell settings put global window_animation_scale 0
timeout 10s adb -s "$SERIAL" shell settings put global transition_animation_scale 0
timeout 10s adb -s "$SERIAL" shell settings put global animator_duration_scale 0
timeout 120s adb -s "$SERIAL" install -r "$APK"

step first-launch-smoke
# Reuse existing UI text selectors. No demo password, signup, or backend writes.
cat > "$OUT/first-launch.yaml" <<'FLOW'
appId: com.teammemorylink.memorylink
name: Unauthenticated first launch
---
- launchApp:
    clearState: true
- extendedWaitUntil:
    visible: "사용자 아이디"
    timeout: 90000
- assertVisible: "비밀번호"
- assertVisible: "로그인"
- assertNotVisible:
    id: "memory_opening"
- takeScreenshot: login-screen
FLOW
timeout 4m maestro --device "$SERIAL" test --format junit --output "$OUT/test-results/smoke.xml" --debug-output "$OUT/maestro" --test-output-dir "$OUT/maestro" "$OUT/first-launch.yaml"
step complete
