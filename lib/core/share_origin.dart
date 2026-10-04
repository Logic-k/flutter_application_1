import 'package:flutter/widgets.dart';

/// 공유 시트의 기준 위치(`sharePositionOrigin`)를 계산한다.
///
/// iPad와 iOS 26 이상의 iPhone에서는 공유 시트(UIActivityViewController)가
/// 팝오버로 떠서 기준 사각형이 반드시 필요하다. 넘기지 않으면 share_plus가
/// `PlatformException(sharePositionOrigin: argument must be set ...)`을 던지고
/// 공유가 실패한다 (iPhone 17 / iOS 26.4 시뮬레이터에서도 확인). Android에서는
/// 무시되는 값이라 모든 공유 호출에 넘겨도 안전하다.
///
/// 비동기 작업 뒤에는 버튼이 트리에서 사라질 수 있으므로(예: 생성 중 스피너로
/// 교체) 반드시 탭 직후, 첫 `await` 이전에 계산해 둔다.
Rect? shareOriginOf(BuildContext context) {
  final renderObject = context.findRenderObject();
  if (renderObject is! RenderBox || !renderObject.hasSize) return null;
  return renderObject.localToGlobal(Offset.zero) & renderObject.size;
}
