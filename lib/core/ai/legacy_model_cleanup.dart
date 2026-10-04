import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 예전 빌드가 남긴 온디바이스 모델(약 1.5GB)과 HuggingFace 토큰을 지운다.
///
/// 온디바이스 AI(flutter_gemma)는 16KB 페이지 기기 호환 문제로 출시 범위에서 뺐다(LAUNCH_AUDIT P0-11).
/// 기능을 지운 뒤에도 기기에 큰 파일과 외부 서비스 토큰이 남지 않게, 앱을 열 때마다 확인한다.
class LegacyOnDeviceModelCleanup {
  LegacyOnDeviceModelCleanup._();

  static const modelFileNames = ['gemma-model.bin', 'gemma-model.bin.download'];
  static const tokenPrefKey = 'hf_token';

  static Future<void> run({Future<Directory> Function()? documentsDirectory}) async {
    try {
      await (await SharedPreferences.getInstance()).remove(tokenPrefKey);
      final dir = await (documentsDirectory ?? getApplicationDocumentsDirectory)();
      for (final name in modelFileNames) {
        final file = File('${dir.path}${Platform.pathSeparator}$name');
        if (await file.exists()) await file.delete();
      }
    } catch (e) {
      debugPrint('[LegacyModelCleanup] 예전 모델 정리 실패(다음 실행 때 다시 시도): $e');
    }
  }
}
