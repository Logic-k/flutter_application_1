# MemoryLink 릴리스 빌드 R8 규칙
#
# flutter_gemma(MediaPipe LLM)와 그 의존성이 참조하지만 Android 런타임에는
# 존재하지 않는 클래스들. 실제 실행 경로에서 사용되지 않으므로 경고만 억제한다.

# MediaPipe 프로파일러/그래프 템플릿 proto — LLM 추론 경로에서 미사용
-dontwarn com.google.mediapipe.proto.**

# javax.lang.model / AutoValue — JVM 컴파일 타임 전용 (어노테이션 프로세서 잔재)
-dontwarn javax.lang.model.**
-dontwarn autovalue.shaded.**

# MediaPipe는 JNI로 클래스를 참조하므로 이름 변경/제거 금지
-keep class com.google.mediapipe.** { *; }

# flutter_local_notifications: 예약 알림 복원 시 리플렉션 사용
-keep class com.dexterous.flutterlocalnotifications.** { *; }
