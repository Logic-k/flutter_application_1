// ─────────────────────────────────────────────────────────────────────────
// [TTA 표준 적용] TTAK.KO-10.1497 「인공지능 시스템 신뢰성 제고를 위한 요구사항」
//
// 적용 지점: 지표 해석의 오독 차단.
//   - 면책 고지를 코드 상수(MedicalDisclaimer)로 강제 삽입한다. 화면 문구가 아니라
//     상수라서 리포트 생성 경로에서 누락될 수 없다. 1페이지 지수 아래
//     (_buildIndexDisclaimerStrip)와 부록(_buildDisclaimerBox) 두 곳에 인쇄된다.
//   - 임상 해석 대상인 인지 점수와 동기부여용 XP를 분리 저장해 상호 해석을 금지한다.
//   - 측정 경로가 없는 영역은 값을 만들지 않고 '데이터 없음'으로 인쇄한다.
//   AI 환각과 지표 오독이 의료적 오판으로 이어지는 경로를 세 지점에서 차단한 것이다.
//
// 같은 표준의 폴백 요구사항은 core/ai/ai_chat_service.dart 에 적용.
// ─────────────────────────────────────────────────────────────────────────
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'models/clinical_report_data.dart';

/// 의료진/보호자용 4페이지 인지 활동 요약 리포트 생성기.
///
/// 이 리포트는 진단·선별 도구가 아니다. 앱 안에서 수행한 훈련 결과를 정리해
/// 상담 자리에서 참고할 수 있게 만드는 것이 목적이다.
/// 모든 pw.Text에 Pretendard를 명시 적용하여 한글 깨짐 방지
class ClinicalReportGenerator {
  // 색상 팔레트 (모두 불투명 – PdfColor.withOpacity 미지원)
  static const _primary = PdfColor.fromInt(0xFF006064);
  static const _primaryDark = PdfColor.fromInt(0xFF004D51);
  static const _primaryLight = PdfColor.fromInt(0xFFE0F7FA);
  static const _green = PdfColor.fromInt(0xFF2E7D32);
  static const _greenBg = PdfColor.fromInt(0xFFE8F5E9);
  static const _amber = PdfColor.fromInt(0xFFF57F17);
  static const _amberBg = PdfColor.fromInt(0xFFFFF8E1);
  static const _orange = PdfColor.fromInt(0xFFE65100);
  static const _orangeBg = PdfColor.fromInt(0xFFFBE9E7);
  static const _red = PdfColor.fromInt(0xFFC62828);
  static const _redBg = PdfColor.fromInt(0xFFFFEBEE);
  static const _gray = PdfColors.grey600;
  static const _lightGray = PdfColors.grey100;
  static const _borderGray = PdfColors.grey300;

  static pw.Font? _ttf;
  static pw.Font? _ttfBold;

  // 화면과 같은 서체를 쓴다. pdf 패키지의 pw.Font.ttf() 는 TrueType 만 읽으므로
  // 여기 넘기는 자산은 반드시 .ttf 여야 한다 (.otf 는 CFF 라 파싱에 실패한다).
  static Future<void> _loadFonts() async {
    _ttf ??= pw.Font.ttf(
        await rootBundle.load('assets/fonts/Pretendard-Regular.ttf'));
    _ttfBold ??= pw.Font.ttf(
        await rootBundle.load('assets/fonts/Pretendard-Bold.ttf'));
  }

  /// 모든 텍스트에 Pretendard를 명시 적용 (한글 깨짐 방지 핵심)
  pw.TextStyle _ts({
    double fontSize = 10,
    bool bold = false,
    PdfColor? color,
  }) {
    return pw.TextStyle(
      font: bold ? _ttfBold! : _ttf!,
      fontBold: _ttfBold!,
      fontSize: fontSize,
      color: color,
    );
  }

  static Future<File> generate(ClinicalReportData data) async {
    await _loadFonts();
    return ClinicalReportGenerator()._build(data);
  }

  Future<File> _build(ClinicalReportData data) async {
    final pdf = pw.Document();

    // pw.ThemeData로 전역 폰트 설정 – 빠짐없이 한글 적용
    final theme = pw.ThemeData.withFont(
      base: _ttf!,
      bold: _ttfBold!,
      italic: _ttf!,
      boldItalic: _ttfBold!,
    );

    final dateStr = DateFormat('yyyy-MM-dd').format(data.assessmentDate);
    final typeLabel =
        data.reportType == ReportType.doctor ? '의료진용' : '보호자용';

    const margin =
        pw.EdgeInsets.symmetric(horizontal: 40, vertical: 36);

    // ── 페이지 1: 핵심 요약 ──
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: margin,
      theme: theme,
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildHeader(dateStr, typeLabel),
          pw.SizedBox(height: 14),
          _buildPatientInfoBox(data, dateStr),
          pw.SizedBox(height: 14),
          _buildActivityIndexBox(data),
          pw.SizedBox(height: 8),
          _buildIndexDisclaimerStrip(),
          pw.SizedBox(height: 14),
          _buildDomainBars(data),
          pw.Spacer(),
          _buildFooter(dateStr, 1, 4),
        ],
      ),
    ));

    // ── 페이지 2: 점수 상세 + 추이 ──
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: margin,
      theme: theme,
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _sectionTitle('영역별 상세 점수'),
          pw.SizedBox(height: 10),
          _buildDomainTable(data),
          pw.SizedBox(height: 18),
          _sectionTitle('인지 훈련 점수 추이'),
          pw.SizedBox(height: 10),
          _buildTrendChart(data.sessionHistory),
          pw.SizedBox(height: 18),
          _sectionTitle('점수 해석 기준'),
          pw.SizedBox(height: 10),
          _buildInterpretationTable(),
          pw.Spacer(),
          _buildFooter(dateStr, 2, 4),
        ],
      ),
    ));

    // ── 페이지 3: 위험요인 + 권고사항 ──
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: margin,
      theme: theme,
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _sectionTitle('위험요인 확인'),
          pw.SizedBox(height: 10),
          _buildRiskFactorsPanel(data.riskFactors),
          pw.SizedBox(height: 18),
          _sectionTitle(data.reportType == ReportType.doctor
              ? '임상 권고사항 (의료진용)'
              : '가족/보호자를 위한 안내'),
          pw.SizedBox(height: 10),
          data.reportType == ReportType.doctor
              ? _buildDoctorRecommendations(data)
              : _buildCaregiverRecommendations(data),
          pw.Spacer(),
          _buildFooter(dateStr, 3, 4),
        ],
      ),
    ));

    // ── 페이지 4: 부록 + 면책 ──
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: margin,
      theme: theme,
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _sectionTitle('검사 도구 설명'),
          pw.SizedBox(height: 10),
          _buildToolDescriptions(),
          pw.SizedBox(height: 18),
          _buildDisclaimerBox(),
          pw.SizedBox(height: 14),
          _buildSupportInfo(),
          pw.Spacer(),
          _buildFooter(dateStr, 4, 4),
        ],
      ),
    ));

    final output = await getTemporaryDirectory();
    final file = File(
        '${output.path}/MemoryLink_Clinical_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  // ── 공통 컴포넌트 ──

  pw.Widget _buildHeader(String dateStr, String typeLabel) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const pw.BoxDecoration(
        color: _primary,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('MemoryLink',
                  style: _ts(fontSize: 10, bold: true, color: PdfColors.white)),
              pw.SizedBox(height: 3),
              pw.Text('인지 활동 요약 리포트',
                  style: _ts(fontSize: 18, bold: true, color: PdfColors.white)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              // withOpacity 대신 불투명 진한 색상 사용
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: const pw.BoxDecoration(
                  color: _primaryDark,
                  borderRadius:
                      pw.BorderRadius.all(pw.Radius.circular(20)),
                ),
                child: pw.Text(typeLabel,
                    style: _ts(
                        fontSize: 10,
                        bold: true,
                        color: PdfColors.white)),
              ),
              pw.SizedBox(height: 5),
              pw.Text('발행일: $dateStr',
                  style: _ts(fontSize: 9, color: PdfColors.white)),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPatientInfoBox(ClinicalReportData data, String dateStr) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _borderGray),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        color: _lightGray,
      ),
      child: pw.Column(
        children: [
          _infoRow('성함', data.userName, '나이', '${data.age}세'),
          pw.SizedBox(height: 6),
          _infoRow('검사일', dateStr, '보호자 동반',
              data.caregiverPresent ? '예' : '아니오'),
          pw.SizedBox(height: 6),
          _infoRow(
            '검사 기간',
            data.assessmentPeriod,
            '복용 약물',
            (data.medications?.isNotEmpty == true)
                ? data.medications!
                : '해당 없음',
          ),
        ],
      ),
    );
  }

  pw.Widget _infoRow(
      String label1, String val1, String label2, String val2) {
    return pw.Row(
      children: [
        pw.Expanded(
          child: pw.RichText(
            text: pw.TextSpan(children: [
              pw.TextSpan(
                  text: '$label1: ',
                  style: _ts(fontSize: 9, color: _gray)),
              pw.TextSpan(
                  text: val1, style: _ts(fontSize: 9, bold: true)),
            ]),
          ),
        ),
        pw.Expanded(
          child: pw.RichText(
            text: pw.TextSpan(children: [
              pw.TextSpan(
                  text: '$label2: ',
                  style: _ts(fontSize: 9, color: _gray)),
              pw.TextSpan(
                  text: val2, style: _ts(fontSize: 9, bold: true)),
            ]),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildActivityIndexBox(ClinicalReportData data) {
    final index = data.activityIndex;
    final band = CognitiveBandExt.fromScore(index);
    final bg = _bandBg(band);
    final fg = _bandFg(band);

    String deltaText = '';
    if (data.prevActivityIndex != null) {
      final d = index - data.prevActivityIndex!;
      final sign = d >= 0 ? '↑ +' : '↓ ';
      deltaText = '$sign${d.abs().toStringAsFixed(0)}점 (전회 대비)';
    }

    // borderRadius는 균일한 Border에만 사용 가능
    // → 왼쪽 강조선을 별도 Container로 분리, 외곽에만 borderRadius 적용
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: bg,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        children: [
          pw.Container(width: 5, color: fg),
          pw.Expanded(
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(16),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('MemoryLink 인지활동 지수',
                            style: _ts(fontSize: 10, color: _gray)),
                        pw.SizedBox(height: 4),
                        pw.RichText(
                          text: pw.TextSpan(children: [
                            pw.TextSpan(
                                text: index.toStringAsFixed(0),
                                style: _ts(fontSize: 28, bold: true, color: fg)),
                            pw.TextSpan(
                                text: ' / 100',
                                style: _ts(fontSize: 13, color: _gray)),
                          ]),
                        ),
                        if (deltaText.isNotEmpty) ...[
                          pw.SizedBox(height: 4),
                          pw.Text(deltaText,
                              style: _ts(fontSize: 9, color: _gray)),
                        ],
                      ],
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: pw.BoxDecoration(
                      color: fg,
                      borderRadius:
                          const pw.BorderRadius.all(pw.Radius.circular(20)),
                    ),
                    child: pw.Text(band.label,
                        style: _ts(
                            fontSize: 11,
                            bold: true,
                            color: PdfColors.white)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildDomainBars(ClinicalReportData data) {
    final domains = [
      data.memory,
      data.attention,
      data.executive,
      data.language,
      data.visuospatial,
    ];
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('영역별 인지 지표',
            style: _ts(fontSize: 11, bold: true)),
        pw.SizedBox(height: 10),
        ...domains.map(_buildDomainBarRow),
      ],
    );
  }

  pw.Widget _buildDomainBarRow(DomainScore domain) {
    final score = domain.score ?? 0;
    final fg = domain.hasData ? _bandFg(domain.band) : _gray;
    final scoreText =
        domain.hasData ? '${score.toStringAsFixed(0)}/100' : '--';
    final statusText =
        domain.hasData ? domain.band.label : '검사 기록 없음';

    // pw.FractionallySizedBox 미지원 → pw.Flexible flex값으로 비율 구현
    final filled = score.round().clamp(0, 100);
    final empty = (100 - filled).clamp(0, 100);

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 72,
            child: pw.Text(domain.domainName,
                style: _ts(fontSize: 9, bold: true)),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Row(
              children: [
                if (filled > 0)
                  pw.Flexible(
                    flex: filled,
                    child: pw.Container(
                      height: 10,
                      decoration: pw.BoxDecoration(
                        color: domain.hasData ? fg : _lightGray,
                        borderRadius: const pw.BorderRadius.only(
                          topLeft: pw.Radius.circular(5),
                          bottomLeft: pw.Radius.circular(5),
                        ),
                      ),
                    ),
                  ),
                if (empty > 0)
                  pw.Flexible(
                    flex: empty,
                    child: pw.Container(
                      height: 10,
                      decoration: pw.BoxDecoration(
                        color: _lightGray,
                        borderRadius: pw.BorderRadius.only(
                          topLeft: filled == 0
                              ? const pw.Radius.circular(5)
                              : pw.Radius.zero,
                          bottomLeft: filled == 0
                              ? const pw.Radius.circular(5)
                              : pw.Radius.zero,
                          topRight: const pw.Radius.circular(5),
                          bottomRight: const pw.Radius.circular(5),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          pw.SizedBox(width: 8),
          pw.SizedBox(
            width: 44,
            child: pw.Text(scoreText,
                style: _ts(fontSize: 9, bold: true, color: fg),
                textAlign: pw.TextAlign.right),
          ),
          pw.SizedBox(width: 8),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(
                horizontal: 7, vertical: 2),
            decoration: pw.BoxDecoration(
              color: domain.hasData ? _bandBg(domain.band) : _lightGray,
              borderRadius:
                  const pw.BorderRadius.all(pw.Radius.circular(10)),
            ),
            child: pw.Text(statusText,
                style: _ts(
                    fontSize: 8,
                    color: domain.hasData ? fg : _gray)),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildDomainTable(ClinicalReportData data) {
    final domains = [
      data.memory,
      data.attention,
      data.executive,
      data.language,
      data.visuospatial,
    ];

    return pw.Table(
      border: pw.TableBorder.all(color: _borderGray, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(2.5),
        1: pw.FlexColumnWidth(1.5),
        2: pw.FlexColumnWidth(1.5),
        3: pw.FlexColumnWidth(1.5),
        4: pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _primary),
          children: ['영역', '현재 점수', '이전 점수', '변화', '평가']
              .map((h) => pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(h,
                        style: _ts(
                            fontSize: 9,
                            bold: true,
                            color: PdfColors.white)),
                  ))
              .toList(),
        ),
        ...domains.asMap().entries.map((e) {
          final i = e.key;
          final d = e.value;
          final bg = i.isOdd ? _lightGray : PdfColors.white;
          final current =
              d.hasData ? '${d.score!.toStringAsFixed(0)}점' : '--';
          final prev = (d.prevScore != null)
              ? '${d.prevScore!.toStringAsFixed(0)}점'
              : '--';
          final fg = d.hasData ? _bandFg(d.band) : _gray;
          String deltaStr = '--';
          if (d.delta != null) {
            final sign = d.delta! >= 0 ? '↑ +' : '↓ ';
            deltaStr =
                '$sign${d.delta!.abs().toStringAsFixed(0)}점';
          }
          return pw.TableRow(
            decoration: pw.BoxDecoration(color: bg),
            children: [
              pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(d.domainName,
                      style: _ts(fontSize: 9, bold: true))),
              pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(current,
                      style: _ts(fontSize: 9, color: fg))),
              pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(prev,
                      style: _ts(fontSize: 9))),
              pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(deltaStr,
                      style: _ts(fontSize: 9))),
              pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(
                      d.hasData ? d.band.label : '검사 기록 없음',
                      style: _ts(fontSize: 9, color: fg))),
            ],
          );
        }),
      ],
    );
  }

  /// 추이 차트: pw.CustomPainter 미지원 → 컬러 셀 표 기반 시각화
  pw.Widget _buildTrendChart(List<ClinicalSessionData> sessions) {
    if (sessions.length < 2) {
      return pw.Container(
        height: 60,
        alignment: pw.Alignment.center,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _borderGray),
          borderRadius:
              const pw.BorderRadius.all(pw.Radius.circular(8)),
          color: _lightGray,
        ),
        child: pw.Text(
          '추이 분석을 위해 최소 2회 이상의 측정이 필요합니다.',
          style: _ts(fontSize: 9, color: _gray),
        ),
      );
    }

    // 최근 6세션만 표시
    final displayed = sessions.length > 6
        ? sessions.sublist(sessions.length - 6)
        : sessions;

    final domainDefs = [
      ('기억력', displayed.map((s) => s.memory).toList()),
      ('주의집중력', displayed.map((s) => s.attention).toList()),
      ('실행기능', displayed.map((s) => s.executive).toList()),
      ('언어능력', displayed.map((s) => s.language).toList()),
    ];

    // 날짜 헤더 행
    final headerRow = pw.TableRow(
      decoration: const pw.BoxDecoration(color: _primary),
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text('영역',
              style: _ts(
                  fontSize: 8, bold: true, color: PdfColors.white)),
        ),
        ...displayed.map((s) => pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(s.dateLabel,
                  style: _ts(
                      fontSize: 7,
                      bold: true,
                      color: PdfColors.white),
                  textAlign: pw.TextAlign.center),
            )),
      ],
    );

    // 도메인 데이터 행 (데이터 있는 도메인만)
    final dataRows = domainDefs
        .where((d) => d.$2.any((v) => v != null))
        .map((domain) {
      return pw.TableRow(
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.all(5),
            child: pw.Text(domain.$1,
                style: _ts(fontSize: 8, bold: true)),
          ),
          ...domain.$2.map((score) {
            final band =
                score != null ? CognitiveBandExt.fromScore(score) : null;
            final bg =
                band != null ? _bandBg(band) : _lightGray;
            final fg =
                band != null ? _bandFg(band) : _gray;
            return pw.Container(
              color: bg,
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                score != null
                    ? score.toStringAsFixed(0)
                    : '--',
                style: _ts(fontSize: 8, color: fg),
                textAlign: pw.TextAlign.center,
              ),
            );
          }),
        ],
      );
    }).toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Table(
          border: pw.TableBorder.all(color: _borderGray, width: 0.5),
          children: [headerRow, ...dataRows],
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          '※ 셀 색상: 초록=양호, 노랑=주의 관찰, 주황=변화가 관찰됨, 빨강=상담 권유',
          style: _ts(fontSize: 7, color: _gray),
        ),
      ],
    );
  }

  pw.Widget _buildInterpretationTable() {
    final rows = [
      ['75–100점', '양호', '현재 수준 유지, 훈련 지속'],
      ['55–74점', '주의 관찰', '3개월 후 재확인 권장'],
      ['35–54점', '변화가 관찰됨', '치매안심센터 무료 상담(CIST) 안내'],
      ['0–34점', '상담 권유', '보호자와 함께 전문기관 상담 권유'],
    ];
    final bgColors = [_greenBg, _amberBg, _orangeBg, _redBg];
    final fgColors = [_green, _amber, _orange, _red];

    return pw.Table(
      border: pw.TableBorder.all(color: _borderGray, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.5),
        1: pw.FlexColumnWidth(1.5),
        2: pw.FlexColumnWidth(4),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _primary),
          children: ['점수 구간', '분류', '권장 조치']
              .map((h) => pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(h,
                        style: _ts(
                            fontSize: 9,
                            bold: true,
                            color: PdfColors.white)),
                  ))
              .toList(),
        ),
        ...rows.asMap().entries.map((e) {
          final i = e.key;
          final r = e.value;
          return pw.TableRow(
            decoration: pw.BoxDecoration(color: bgColors[i]),
            children: [
              pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(r[0],
                      style:
                          _ts(fontSize: 9, color: fgColors[i]))),
              pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(r[1],
                      style: _ts(
                          fontSize: 9,
                          bold: true,
                          color: fgColors[i]))),
              pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(r[2],
                      style: _ts(fontSize: 9))),
            ],
          );
        }),
      ],
    );
  }

  /// 지수 바로 아래에 붙는 고지. 사용자는 판단 근거보다 숫자를 먼저 읽으므로
  /// 고지가 숫자와 같은 화면에 있어야 한다. 4페이지 부록만으로는 늦다.
  pw.Widget _buildIndexDisclaimerStrip() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const pw.BoxDecoration(
        color: _lightGray,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: MedicalDisclaimer.sentences
            .map((s) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 1.5),
                  child: pw.Text('· $s', style: _ts(fontSize: 7.5, color: _gray)),
                ))
            .toList(),
      ),
    );
  }

  pw.Widget _buildRiskFactorsPanel(RiskFactors rf) {
    final items = [
      (rf.poorSleep, '수면 문제', 'WHO 권장: 하루 7–9시간 수면'),
      (rf.depressiveMood, '우울한 기분', '정신건강의학과 상담 또는 지역 정신건강복지센터 이용'),
      (rf.hearingDifficulty, '청력 저하', '청력 검사 및 보청기 착용 고려'),
      (rf.lowExercise, '운동 부족', '주 150분 이상 유산소 운동 권장 (걷기 포함)'),
      (rf.socialIsolation, '사회적 고립', '정기적 사회활동 및 가족 교류 증가'),
      (rf.hypertension, '고혈압', '약물 복용 준수, 정기적 혈압 측정'),
      (rf.diabetes, '당뇨', '혈당 모니터링 및 식이 관리'),
    ];

    return pw.Column(
      children: items.map((item) {
        final checked = item.$1;
        final label = item.$2;
        final note = item.$3;
        return pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 3),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 16,
                height: 16,
                margin: const pw.EdgeInsets.only(top: 1, right: 8),
                decoration: pw.BoxDecoration(
                  shape: pw.BoxShape.circle,
                  color: checked ? _orange : _lightGray,
                ),
                child: pw.Center(
                  child: pw.Text(
                    checked ? '!' : '-',
                    style: _ts(
                        fontSize: 9,
                        bold: true,
                        color: checked
                            ? PdfColors.white
                            : _gray),
                  ),
                ),
              ),
              pw.Expanded(
                child: pw.RichText(
                  text: pw.TextSpan(children: [
                    pw.TextSpan(
                        text: '$label  ',
                        style: _ts(
                            fontSize: 9,
                            bold: true,
                            color: checked ? _orange : _gray)),
                    pw.TextSpan(
                        text: checked ? note : '해당 없음',
                        style: _ts(
                            fontSize: 8,
                            color: checked
                                ? PdfColors.grey700
                                : _gray)),
                  ]),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  pw.Widget _buildDoctorRecommendations(ClinicalReportData data) {
    final index = data.activityIndex;
    final reassessDate = DateTime.now().add(const Duration(days: 90));
    final reassessStr = DateFormat('yyyy-MM-dd').format(reassessDate);
    final band = CognitiveBandExt.fromScore(index);
    final needsAttention = band == CognitiveBand.specialistReferral;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _recItem(
          '1. 재확인 권장',
          band == CognitiveBand.normal
              ? '앱 내 수행이 안정적입니다. 6개월 후 재확인을 권장합니다.'
              : '인지활동 지수 ${index.toStringAsFixed(0)}점 → ${band.label} 구간\n권장 재확인일: $reassessStr',
        ),
        pw.SizedBox(height: 8),
        _recItem(
          '2. 표준 선별 도구 안내',
          // MMSE는 배타적 저작권 대상이라 안내에서 뺀다. CIST는 보건복지부가
          // 저작권 문제를 해소하려고 개발·보급한 국내 표준 선별도구이며
          // 전국 치매안심센터에서 무료로 시행한다.
          'CIST(한국형 인지선별검사): 전국 치매안심센터 무료 시행\n'
              '그 밖의 표준 도구 시행 여부는 담당 의료진 판단에 따릅니다.\n'
              '본 리포트의 지수는 위 도구들과 등가성이 검증되지 않았습니다.',
        ),
        pw.SizedBox(height: 8),
        _recItem(
          '3. 상담을 고려할 때',
          needsAttention
              ? '⚠ 인지활동 지수 ${index.toStringAsFixed(0)}점: 보호자와 함께 전문기관 상담을 권유드립니다.'
              : '인지활동 지수 35점 미만 또는 3개월 내 15점 이상 하락 시\n'
                  '2개 이상 영역에서 하위 구간이 확인될 때\n'
                  '일상생활 기능 저하(ADL)가 관찰될 때',
        ),
        if (data.riskFactors.checkedCount > 0) ...[
          pw.SizedBox(height: 8),
          _recItem(
            '4. 조절 가능 위험요인',
            '${data.riskFactors.checkedCount}개 위험요인이 확인되었습니다.\n'
                'WHO 권고에 따라 생활습관 개선이 인지 저하 예방에 효과적입니다.',
          ),
        ],
      ],
    );
  }

  pw.Widget _buildCaregiverRecommendations(ClinicalReportData data) {
    final stepNote = data.averageSteps > 0
        ? '이번 달 평균 ${data.averageSteps}보 (목표: 6,000보)\n'
            '${data.averageSteps < 6000 ? "목표보다 ${6000 - data.averageSteps}보 부족합니다. 규칙적인 산책을 함께해 주세요." : "목표를 달성하고 있습니다. 잘 하고 계세요!"}'
        : '걸음 데이터가 없습니다. 가능하면 함께 걷기를 시작해 보세요.';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _recItem(
          '1. 일상 기능 변화 체크리스트',
          '- 같은 질문이나 이야기를 반복하는지\n'
              '- 익숙한 장소에서 길을 잃거나 헤매는지\n'
              '- 돈 계산이나 약 복용 관리가 어려워졌는지\n'
              '- 성격이나 기분이 평소와 달리 변했는지\n'
              '- 낮에 주로 자거나 밤에 잠들지 못하는지',
        ),
        pw.SizedBox(height: 8),
        _recItem(
          '2. 오늘의 점수 요약',
          '기억력: ${_domainSimple(data.memory)}\n'
              '집중력: ${_domainSimple(data.attention)}\n'
              '실행기능: ${_domainSimple(data.executive)}',
        ),
        pw.SizedBox(height: 8),
        _recItem(
          '3. 즉시 병원 방문이 필요한 신호',
          '⚠ 갑자기 말이 어눌해지거나 이해하지 못하는 경우\n'
              '⚠ 집 안에서 가족을 알아보지 못하는 경우\n'
              '⚠ 심한 혼돈, 환각, 또는 자해 위험 행동',
        ),
        pw.SizedBox(height: 8),
        _recItem('4. 도움이 되는 일상 활동', stepNote),
      ],
    );
  }

  String _domainSimple(DomainScore d) {
    if (!d.hasData) return '측정 기록 없음';
    switch (d.band) {
      case CognitiveBand.normal:
        return '${d.score!.toStringAsFixed(0)}점 – 잘 하고 있어요';
      case CognitiveBand.borderline:
        return '${d.score!.toStringAsFixed(0)}점 – 조금 더 주의가 필요해요';
      case CognitiveBand.needsFollowUp:
        return '${d.score!.toStringAsFixed(0)}점 – 변화를 지켜봐 주세요';
      case CognitiveBand.specialistReferral:
        return '${d.score!.toStringAsFixed(0)}점 – 보호자와 함께 상담을 권유드려요';
    }
  }

  pw.Widget _recItem(String title, String body) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _borderGray, width: 0.5),
        borderRadius:
            const pw.BorderRadius.all(pw.Radius.circular(8)),
        color: _lightGray,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title,
              style: _ts(fontSize: 9, bold: true, color: _primary)),
          pw.SizedBox(height: 5),
          pw.Text(body, style: _ts(fontSize: 8.5)),
        ],
      ),
    );
  }

  pw.Widget _buildToolDescriptions() {
    final tools = [
      ('기억력', 'MemoryLink 단어 회상 과제 및 그림 스도쿠 기반 측정'),
      ('주의집중력', 'MemoryLink 모양 찾기 과제 기반 측정'),
      ('실행기능', 'MemoryLink 수 비교·구구단 계산 과제 기반 측정'),
      ('언어능력', '문장 소리 내어 읽기 과제 (미완료 시 측정 불가)'),
      ('시공간 지각', '별도 측정 과제 없음 (현재 측정 불가)'),
      ('MemoryLink 인지활동 지수',
          '측정된 각 영역의 0–100점 평균값(앱 내부 지표).\n표준화 검사와의 등가성은 검증되지 않았습니다.'),
    ];

    return pw.Table(
      border: pw.TableBorder.all(color: _borderGray, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(2),
        1: pw.FlexColumnWidth(5),
      },
      children: tools.asMap().entries.map((e) {
        final i = e.key;
        final t = e.value;
        return pw.TableRow(
          decoration: pw.BoxDecoration(
              color: i.isOdd ? _lightGray : PdfColors.white),
          children: [
            pw.Padding(
                padding: const pw.EdgeInsets.all(7),
                child: pw.Text(t.$1,
                    style: _ts(fontSize: 9, bold: true))),
            pw.Padding(
                padding: const pw.EdgeInsets.all(7),
                child: pw.Text(t.$2,
                    style: _ts(fontSize: 9))),
          ],
        );
      }).toList(),
    );
  }

  pw.Widget _buildDisclaimerBox() {
    const lines = [
      MedicalDisclaimer.notDiagnostic,
      MedicalDisclaimer.notEquivalent,
      '본 리포트는 디지털 기기를 통한 인지 훈련 활동 기록의 요약입니다.',
      '치매 등 신경인지 장애의 확진은 반드시 의료 전문가에 의해 이루어져야 합니다.',
      '이 결과만으로 치료 또는 치료 중단을 결정하지 마십시오.',
      '임상 증상, 병력, 보호자 진술과 함께 해석해야 합니다.',
      MedicalDisclaimer.whereToGo,
    ];
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _orange, width: 1.5),
        borderRadius:
            const pw.BorderRadius.all(pw.Radius.circular(8)),
        color: _orangeBg,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('중요 고지사항',
              style:
                  _ts(fontSize: 11, bold: true, color: _orange)),
          pw.SizedBox(height: 8),
          ...lines.map((l) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('•  ',
                        style: _ts(fontSize: 9, color: _orange)),
                    pw.Expanded(
                        child: pw.Text(l,
                            style: _ts(fontSize: 9))),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  pw.Widget _buildSupportInfo() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: const pw.BoxDecoration(
        color: _primaryLight,
        borderRadius:
            pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('도움이 필요하신 경우',
                    style: _ts(
                        fontSize: 9, bold: true, color: _primary)),
                pw.SizedBox(height: 5),
                pw.Text('치매안심센터: 1899-9988',
                    style: _ts(fontSize: 9)),
                pw.Text('정신건강위기상담전화: 1577-0199',
                    style: _ts(fontSize: 9)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(String dateStr, int page, int total) {
    return pw.Column(
      children: [
        pw.Divider(color: _borderGray, thickness: 0.5),
        pw.SizedBox(height: 3),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'MemoryLink 인지 훈련 기록  |  발행: $dateStr',
              style: _ts(fontSize: 7, color: _gray),
            ),
            pw.Text(
              '진단·선별 검사가 아니며 의학적 진단을 대체하지 않습니다.',
              style: _ts(fontSize: 7, color: _gray),
            ),
            pw.Text(
              '페이지 $page / $total',
              style: _ts(fontSize: 7, color: _gray),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _sectionTitle(String title) {
    return pw.Container(
      padding:
          const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      decoration: const pw.BoxDecoration(
        color: _primaryLight,
        border: pw.Border(
            left: pw.BorderSide(color: _primary, width: 4)),
      ),
      child: pw.Text(title,
          style: _ts(fontSize: 11, bold: true, color: _primary)),
    );
  }

  // ── 밴드 헬퍼 ──
  //
  // 구간 판정은 CognitiveBandExt.fromScore 한 곳에만 둔다.
  // 예전에는 여기에 30점 척도(25/20/14)와 100점 척도(75/55/35) 두 벌이 따로
  // 있어, 같은 사용자의 종합 밴드와 영역 밴드가 서로 다르게 나올 수 있었다.

  static PdfColor _bandFg(CognitiveBand band) {
    switch (band) {
      case CognitiveBand.normal:
        return _green;
      case CognitiveBand.borderline:
        return _amber;
      case CognitiveBand.needsFollowUp:
        return _orange;
      case CognitiveBand.specialistReferral:
        return _red;
    }
  }

  static PdfColor _bandBg(CognitiveBand band) {
    switch (band) {
      case CognitiveBand.normal:
        return _greenBg;
      case CognitiveBand.borderline:
        return _amberBg;
      case CognitiveBand.needsFollowUp:
        return _orangeBg;
      case CognitiveBand.specialistReferral:
        return _redBg;
    }
  }
}
