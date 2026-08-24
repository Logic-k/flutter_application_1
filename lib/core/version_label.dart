import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_config.dart';

/// 화면 하단의 버전 표기. 관리자 포털이 켜진 빌드에서만 롱프레스로
/// 포털 로그인이 열린다.
///
/// 내 정보·설정 두 화면이 같은 GestureDetector를 복사해 쓰고 있었다.
/// 진입 조건을 한쪽에만 걸면 다른 쪽에 구멍이 남기 때문에 위젯으로 합쳤다.
/// 버전 문자열도 같은 이유로 여기 한 곳에만 둔다.
class MLVersionLabel extends StatelessWidget {
  const MLVersionLabel({super.key});

  static const String version = 'v1.0.0';

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onLongPress: AppConfig.isAdminPortalEnabled
            ? () => context.push('/admin_login')
            : null,
        child: Text(
          'MemoryLink $version',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}
