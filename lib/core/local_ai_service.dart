import 'dart:async';
import 'package:flutter/foundation.dart';

/// 온디바이스 인지 발화 분석 서비스 (규칙 기반 엔진)
///
/// 한국어 발화 특성(TTR, WPM, 문장완결성 등) 기반으로
/// 인지 건강 지표를 산출합니다.
///
/// TFLite 통합은 호환 버전 확보 후 재도입 예정.
/// 모델 파일: assets/models/cognitive_classifier.tflite (보관용)
class LocalAIService {
  static const _riskKeywords = [
    '모르겠', '기억이 안', '생각이 안', '뭐였더라', '깜빡', '헷갈',
  ];

  static const _fillerWords = [
    '어', '음', '그', '뭐', '저', '아', '에', '이제',
  ];

  static Future<void> initialize() async {
    debugPrint('[LocalAI] 규칙 기반 엔진 준비 완료');
  }

  /// 발화 텍스트 분석
  Future<Map<String, dynamic>> analyzeText({
    required String text,
    required double ttr,
    required double wpm,
    required int totalWords,
    int durationSeconds = 30,
  }) async {
    if (text.trim().isEmpty) {
      return {
        'cognitive_score': 0.0,
        'risk_score': 1.0,
        'analysis': '발화 내용이 없습니다.',
        'model': 'MemoryLink-Rules-v2',
        'is_local': true,
      };
    }

    final features = _extractFeatures(
      text: text,
      ttr: ttr,
      wpm: wpm,
      totalWords: totalWords,
      durationSeconds: durationSeconds,
    );

    return _analyze(features, ttr, wpm, totalWords);
  }

  _FeatureSet _extractFeatures({
    required String text,
    required double ttr,
    required double wpm,
    required int totalWords,
    required int durationSeconds,
  }) {
    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

    // 문장 완결성
    final sentences = text.split(RegExp(r'[.。!?]')).where((s) => s.trim().isNotEmpty).toList();
    int closedCount = 0;
    for (final s in sentences) {
      final t = s.trim();
      if (t.endsWith('다') || t.endsWith('요') || t.endsWith('죠') ||
          t.endsWith('네') || t.endsWith('군')) {
        closedCount++;
      }
    }
    final completionRatio = sentences.isEmpty ? 0.0 : closedCount / sentences.length;

    // 반복 어구
    final wordFreq = <String, int>{};
    for (final w in words) {
      final lower = w.toLowerCase();
      if (lower.length >= 2) wordFreq[lower] = (wordFreq[lower] ?? 0) + 1;
    }
    final repeatedKinds = wordFreq.values.where((c) => c >= 3).length;

    // 위험 키워드
    final lowerText = text.toLowerCase();
    int riskHits = 0;
    for (final kw in _riskKeywords) {
      if (lowerText.contains(kw)) riskHits++;
    }

    // 충전어
    int fillerCount = 0;
    for (final w in words) {
      if (_fillerWords.contains(w)) fillerCount++;
    }

    return _FeatureSet(
      completionRatio: completionRatio,
      repeatedKinds: repeatedKinds,
      riskHits: riskHits,
      fillerCount: fillerCount,
    );
  }

  Map<String, dynamic> _analyze(_FeatureSet f, double ttr, double wpm, int totalWords) {
    // 어휘 다양성 (40점)
    final double ttrScore = (ttr / 0.6 * 40).clamp(0, 40);

    // 발화 속도 (25점) — 한국어 정상 범위 80~160 wpm
    double speedScore;
    if (wpm >= 80 && wpm <= 160) {
      speedScore = 25.0;
    } else if ((wpm >= 50 && wpm < 80) || (wpm > 160 && wpm <= 200)) {
      speedScore = 18.0;
    } else if (wpm > 0) {
      speedScore = 10.0;
    } else {
      speedScore = 5.0;
    }

    // 발화량 (20점)
    final double volumeScore = (totalWords / 30.0 * 20).clamp(0, 20);

    // 문장 완결성 (10점)
    final double completionScore = (f.completionRatio * 10).clamp(0, 10);

    // 반복 어구 페널티 (최대 -5점)
    final double repeatPenalty = (f.repeatedKinds * 1.5).clamp(0, 5);

    final cognitiveScore =
        (ttrScore + speedScore + volumeScore + completionScore - repeatPenalty)
            .clamp(0.0, 100.0);

    final riskScore = (f.riskHits * 0.15).clamp(0.0, 0.6);

    return {
      'cognitive_score': cognitiveScore,
      'risk_score': riskScore,
      'analysis': _buildDetail(f, ttr, wpm, totalWords),
      'model': 'MemoryLink-Rules-v2',
      'is_local': true,
    };
  }

  String _buildDetail(_FeatureSet f, double ttr, double wpm, int totalWords) {
    final ttrGrade = ttr >= 0.6 ? '양호' : (ttr >= 0.4 ? '보통' : '부족');
    final speedGrade = (wpm >= 80 && wpm <= 160) ? '정상' : (wpm > 0 ? '주의' : '측정불가');
    final lines = [
      '• 어휘 다양성(TTR): ${(ttr * 100).toStringAsFixed(1)}% — $ttrGrade',
      '• 발화 속도: ${wpm.toStringAsFixed(0)} 단어/분 — $speedGrade',
      '• 총 발화량: $totalWords단어',
      '• 문장 완결성: ${(f.completionRatio * 100).toStringAsFixed(0)}%',
    ];
    if (f.repeatedKinds > 0) lines.add('• 반복 표현: ${f.repeatedKinds}종 감지');
    if (f.riskHits > 0) lines.add('• 기억 관련 표현: ${f.riskHits}회 감지');
    if (f.fillerCount > 2) lines.add('• 충전어(어·음·그 등): ${f.fillerCount}회');
    return lines.join('\n');
  }
}

class _FeatureSet {
  final double completionRatio;
  final int repeatedKinds;
  final int riskHits;
  final int fillerCount;

  const _FeatureSet({
    required this.completionRatio,
    required this.repeatedKinds,
    required this.riskHits,
    required this.fillerCount,
  });
}
