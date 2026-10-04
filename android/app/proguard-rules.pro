# MemoryLink 릴리스 빌드 R8 규칙
#
# 2026-10-04: 온디바이스 AI(flutter_gemma, MediaPipe LLM)를 빼면서 MediaPipe 전용 규칙을 지웠다
# (LAUNCH_AUDIT P0-11). 아래 두 줄은 컴파일 타임 전용 클래스 경고 억제로, 다른 의존성이
# 참조할 수 있어 남긴다.

# javax.lang.model / AutoValue — JVM 컴파일 타임 전용 (어노테이션 프로세서 잔재)
-dontwarn javax.lang.model.**
-dontwarn autovalue.shaded.**

# flutter_local_notifications: 예약 알림 복원 시 리플렉션 사용
-keep class com.dexterous.flutterlocalnotifications.** { *; }
