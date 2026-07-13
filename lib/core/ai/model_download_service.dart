import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ModelDownloadService {
  static const String _modelFileName = 'gemma-model.bin';
  static const String _tokenPrefKey = 'hf_token';

  // HuggingFace Gemma 2B IT GPU INT4 (MediaPipe 호환 .bin 포맷)
  // 다운로드 전 https://huggingface.co/google/gemma-1.1-2b-it 에서 약관 동의 필요
  static const String modelDownloadUrl =
      'https://huggingface.co/google/gemma-1.1-2b-it/resolve/main/gemma-1.1-2b-it-gpu-int4.bin';

  static Future<String> get modelPath async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/$_modelFileName';
  }

  static Future<bool> isModelReady() async {
    final path = await modelPath;
    return File(path).existsSync();
  }

  static Future<void> deleteModel() async {
    final path = await modelPath;
    final file = File(path);
    if (file.existsSync()) await file.delete();
    // 중단된 다운로드의 임시 파일도 정리
    final tmp = File('$path.download');
    if (tmp.existsSync()) await tmp.delete();
  }

  static Future<String?> getSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenPrefKey);
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenPrefKey, token.trim());
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenPrefKey);
  }

  /// 모델을 스트리밍 다운로드합니다.
  /// [hfToken] HuggingFace Access Token (Bearer)
  /// [onProgress] 0.0~1.0 진행률 콜백
  ///
  /// 임시 파일(.download)에 받은 뒤 완료 시에만 최종 경로로 rename 한다.
  /// 앱 강제 종료 등으로 다운로드가 중단되어도 부분 파일이 모델로
  /// 인식되는 일(isModelReady == true)이 없다.
  static Future<void> downloadModel({
    required String hfToken,
    void Function(double progress)? onProgress,
  }) async {
    final path = await modelPath;
    final file = File(path);
    final tmpFile = File('$path.download');

    final request = http.Request('GET', Uri.parse(modelDownloadUrl));
    request.headers['Authorization'] = 'Bearer $hfToken';

    final response = await http.Client().send(request);

    if (response.statusCode == 401) {
      throw Exception('토큰이 유효하지 않거나 Gemma 약관 동의가 필요합니다.');
    }
    if (response.statusCode == 403) {
      throw Exception('접근 권한이 없습니다. HuggingFace에서 Gemma 약관에 동의해 주세요.');
    }
    if (response.statusCode != 200) {
      throw Exception('다운로드 실패: HTTP ${response.statusCode}');
    }

    final total = response.contentLength ?? 0;
    int received = 0;

    final sink = tmpFile.openWrite();
    try {
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) onProgress?.call(received / total);
      }
      await sink.close();
    } catch (e) {
      await sink.close();
      if (tmpFile.existsSync()) await tmpFile.delete();
      rethrow;
    }

    // 수신 크기 검증 (서버가 Content-Length를 준 경우)
    if (total > 0 && received != total) {
      if (tmpFile.existsSync()) await tmpFile.delete();
      throw Exception('다운로드가 불완전합니다 ($received/$total bytes). 다시 시도해 주세요.');
    }

    // 완료된 파일만 최종 경로로 이동
    if (file.existsSync()) await file.delete();
    await tmpFile.rename(path);
  }
}
