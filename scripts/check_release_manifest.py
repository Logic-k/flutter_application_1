"""출시 빌드의 병합 매니페스트가 Play 신고(PLAY_CONSOLE.md 8·9번)와 같은지 검사한다.

플러그인을 올리면 그 플러그인의 매니페스트가 권한을 몰래 더할 수 있다. 앱 매니페스트만 보는
android_manifest_guard_test 로는 못 잡으므로 병합 결과를 본다(LAUNCH_AUDIT P0-02·P0-09·P0-12·P0-13).
권한이 바뀌어야 한다면 PLAY_CONSOLE.md 와 RELEASE_CHECKLIST.md 권한 정당화를 먼저 고치고 아래 목록을 고친다.

사용: python scripts/check_release_manifest.py build/app/intermediates/merged_manifests/release/processReleaseManifest/AndroidManifest.xml
종료 코드: 통과 0, 어긋나면 1.
"""
import sys
import xml.etree.ElementTree as ET

ANDROID = '{http://schemas.android.com/apk/res/android}'

ALLOWED_PERMISSIONS = {
    'android.permission.ACCESS_NETWORK_STATE',
    'android.permission.ACTIVITY_RECOGNITION',
    'android.permission.FOREGROUND_SERVICE',
    'android.permission.FOREGROUND_SERVICE_HEALTH',
    'android.permission.INTERNET',
    'android.permission.POST_NOTIFICATIONS',
    'android.permission.RECEIVE_BOOT_COMPLETED',
    'android.permission.RECORD_AUDIO',
    'android.permission.VIBRATE',
    'android.permission.WAKE_LOCK',
    'com.google.android.providers.gsf.permission.READ_GSERVICES',
    'com.teammemorylink.memorylink.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION',
}

REQUIRED_QUERY_ACTIONS = {
    'android.speech.RecognitionService',
    'android.intent.action.TTS_SERVICE',
}


def main(path: str) -> int:
    root = ET.parse(path).getroot()
    problems = []

    declared = {
        element.get(ANDROID + 'name')
        for tag in ('uses-permission', 'uses-permission-sdk-23')
        for element in root.iter(tag)
    }
    for name in sorted(declared - ALLOWED_PERMISSIONS):
        problems.append(f'신고에 없는 권한: {name}')
    for name in sorted(ALLOWED_PERMISSIONS - declared):
        problems.append(f'신고했지만 빠진 권한: {name}')

    query_actions = {
        action.get(ANDROID + 'name')
        for queries in root.iter('queries')
        for action in queries.iter('action')
    }
    for name in sorted(REQUIRED_QUERY_ACTIONS - query_actions):
        problems.append(f'패키지 조회 누락: {name}')

    for intent_filter in root.iter('intent-filter'):
        if intent_filter.get(ANDROID + 'autoVerify') == 'true':
            problems.append('App Link(autoVerify) 인텐트 필터가 있다. 보호자 링크는 브라우저 전용이다')

    if problems:
        for problem in problems:
            print(f'FAIL {problem}')
        return 1
    print(f'OK 권한 {len(declared)}개가 신고 목록과 같고, 음성 엔진 조회가 있으며 App Link가 없다')
    return 0


if __name__ == '__main__':
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(2)
    sys.exit(main(sys.argv[1]))
