import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

/// 치매안심센터 표준 양식 기반 임상 리포트 생성기
/// 
/// [agency-analytics-reporter]: 수집된 보행 바이오마커와 인지 훈련 데이터를 
/// 의료진이 판독하기 쉬운 표준 리포트(PDF)로 변환합니다.
class ClinicalReportGenerator {
  
  static Future<File> generateStandardReport({
    required String userName,
    required String birthDate,
    required int averageSteps,
    required double gaitStability, // 0.0 ~ 1.0
    required int mmseScore,
    required int gdsLevel,
    required List<Map<String, dynamic>> dailyRoutineData,
  }) async {
    final pdf = pw.Document();
    
    // 한국어 나눔고딕 폰트 로드
    final fontData = await rootBundle.load("assets/fonts/NanumGothic-Regular.ttf");
    final fontBoldData = await rootBundle.load("assets/fonts/NanumGothic-Bold.ttf");
    final ttf = pw.Font.ttf(fontData);
    final ttfBold = pw.Font.ttf(fontBoldData);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        // 기본 테마에 폰트 설정
        theme: pw.ThemeData.withFont(
          base: ttf,
          bold: ttfBold,
        ),
        build: (pw.Context context) => [
          _buildHeader(),
          pw.SizedBox(height: 20),
          _buildPatientInfo(userName, birthDate),
          pw.SizedBox(height: 30),
          _buildSummarySection(averageSteps, gaitStability, gdsLevel),
          pw.SizedBox(height: 30),
          _buildDetailTable(dailyRoutineData),
          pw.SizedBox(height: 40),
          _buildAIInterpretation(gaitStability, mmseScore),
          pw.Spacer(),
          _buildFooter(),
        ],
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/MemoryLink_Report_${DateTime.now().millisecondsSinceEpoch}.pdf");
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static pw.Widget _buildHeader() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('MemoryLink 임상 리포트', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
        pw.Divider(thickness: 2),
        pw.Text('발행일: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 10)),
      ],
    );
  }

  static pw.Widget _buildPatientInfo(String name, String birth) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey)),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('성함: $name'),
          pw.Text('생년월일: $birth'),
          pw.Text('검사 기관: MemoryLink 디지털 환경'),
        ],
      ),
    );
  }

  static pw.Widget _buildSummarySection(int steps, double stability, int gds) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('1. 종합 상태 요약 (Summary Indicators)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
          children: [
            _buildIndicatorCard('평균 걸음수', '$steps보', steps > 5000 ? PdfColors.green : PdfColors.orange),
            _buildIndicatorCard('보행 안정성', '${(stability * 100).toStringAsFixed(1)}%', stability > 0.8 ? PdfColors.blue : PdfColors.red),
            _buildIndicatorCard('GDS 단계', '$gds단계', gds <= 3 ? PdfColors.green : PdfColors.amber),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildIndicatorCard(String title, String value, PdfColor color) {
    return pw.Container(
      width: 120,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        children: [
          pw.Text(title, style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 5),
          pw.Text(value, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  static pw.Widget _buildDetailTable(List<Map<String, dynamic>> data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('2. 일일 활동 상세 (Activity Logs)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.TableHelper.fromTextArray(
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
          data: <List<String>>[
            <String>['날짜', '총 걸음', '운동 시간', '인지 훈련', '달성도'],
            ...data.map((item) => [
              item['date'].toString(),
              "${item['steps']}보",
              "${item['duration']}분",
              item['training_score'].toString(),
              "${item['achievement']}%"
            ]),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildAIInterpretation(double stability, int mmse) {
    String interpretation = "";
    if (stability < 0.7) {
      interpretation = "보행 변동성이 높은 상태로 관찰되어 낙상 위험이 있으니 주의가 필요합니다. ";
    } else {
      interpretation = "보행 패턴이 연령대 평균 대비 안정적입니다. ";
    }
    
    if (mmse < 24) {
      interpretation += "인지 점수가 기준치 대비 낮아 정밀 문진을 권장합니다.";
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      color: PdfColors.blue100,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('3. 디지털 바이오마커 기반 AI 종합 소견', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Text(interpretation, style: const pw.TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Divider(),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('MemoryLink: AI Powered Dementia Prevention', style: const pw.TextStyle(fontSize: 8)),
            pw.Text('Page 1 of 1', style: const pw.TextStyle(fontSize: 8)),
          ],
        ),
      ],
    );
  }
}
