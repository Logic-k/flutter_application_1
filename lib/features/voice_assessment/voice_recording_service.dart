import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// 음성 녹음 관리 서비스
///
/// [agency-mobile-app-builder]: 실제 'record' 패키지를 사용하여 
/// 가짜 데이터가 아닌 실제 하드웨어의 오디오 데이터를 획득합니다.
class VoiceRecordingService {
  final AudioRecorder _audioRecorder = AudioRecorder();

  /// 녹음 시작
  Future<void> start() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
        final String path = '${appDocumentsDir.path}/voice_assessment_${DateTime.now().millisecondsSinceEpoch}.m4a';

        const RecordConfig config = RecordConfig();

        // Start recording to file
        await _audioRecorder.start(config, path: path);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// 녹음 중지 및 파일 경로 반환
  Future<String?> stop() async {
    try {
      final String? path = await _audioRecorder.stop();
      return path;
    } catch (e) {
      return null;
    }
  }

  /// 현재 녹음 상태 확인
  Future<bool> isRecording() => _audioRecorder.isRecording();

  /// 리소스 해제
  void dispose() {
    _audioRecorder.dispose();
  }
}
