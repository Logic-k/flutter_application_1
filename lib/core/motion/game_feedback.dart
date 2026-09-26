import 'package:flutter/foundation.dart';

enum GameFeedbackKind { correct, wrong }

/// 한 번의 정답·오답 신호. [serial] 이 달라야 같은 종류가 연달아 와도 새 이벤트로 본다.
@immutable
class GameFeedbackEvent {
  const GameFeedbackEvent(this.kind, this.message, this.serial);

  final GameFeedbackKind kind;
  final String message;
  final int serial;
}

/// 게임이 "맞았다/틀렸다"만 알리면 햅틱·효과음·배지·파티클·흔들림은 `GameTemplate` 이
/// 한 곳에서 처리한다. 07 계획 F-02 — 7종 게임이 제각각 피드백을 만들던 것을 모은다.
///
/// 게임 State 가 소유하고(`dispose` 포함) `GameTemplate(feedback: ...)` 으로 넘긴다.
/// 배지는 색 + 아이콘 + 문구 세 겹이다(DESIGN.md §5 "색만으로 정보를 전달하지 않는다").
class GameFeedbackController extends ChangeNotifier {
  GameFeedbackEvent? _event;
  int _serial = 0;

  GameFeedbackEvent? get event => _event;

  void correct([String message = '정답입니다']) =>
      _emit(GameFeedbackKind.correct, message);

  void wrong([String message = '아쉬워요, 오답입니다']) =>
      _emit(GameFeedbackKind.wrong, message);

  void _emit(GameFeedbackKind kind, String message) {
    _event = GameFeedbackEvent(kind, message, ++_serial);
    notifyListeners();
  }
}
