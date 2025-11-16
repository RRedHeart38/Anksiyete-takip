// lib/services/report_generator.dart

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:fl_chart/fl_chart.dart';

Future<File> generateAnxietyReport(List<FlSpot> chartSpots, List<Map<String, dynamic>> aiAnalyses) async {
  final pdf = pw.Document();

  // Fontları yükle (Türkçe karakterler için)
  final fontData = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
  final ttf = pw.Font.ttf(fontData);

  // Başlık Sayfası
  pdf.addPage(
    pw.Page(
      build: (pw.Context context) {
        return pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text('Kişisel Anksiyete Raporu', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, font: ttf)),
              pw.SizedBox(height: 10),
              pw.Text('Hazırlayan: Nefes', style: pw.TextStyle(font: ttf)),
              pw.SizedBox(height: 5),
              pw.Text('Tarih: ${DateTime.now().toString().substring(0, 10)}', style: pw.TextStyle(font: ttf)),
            ],
          ),
        );
      },
    ),
  );

  // Çizgi Grafiği Sayfası
  final chartImage = await _generateChartImage(chartSpots);
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Haftalık Kaygı Seviyesi Grafiği', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, font: ttf)),
            pw.SizedBox(height: 20),
            pw.Center(
              child: pw.Image(chartImage, height: 250),
            ),
            pw.SizedBox(height: 20),
            pw.Text('Grafik, son 7 gün içinde kaydedilen ortalama kaygı seviyelerini göstermektedir. Bu veriler, ruh halinizin zaman içindeki değişimini anlamanıza yardımcı olur.', style: pw.TextStyle(font: ttf)),
          ],
        );
      },
    ),
  );

  // Yapay Zeka Analizleri Sayfası
  if (aiAnalyses.isNotEmpty) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Yapay Zeka Analizleri', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, font: ttf)),
              pw.SizedBox(height: 20),
              ...aiAnalyses.map((analysis) {
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 15),
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400), borderRadius: pw.BorderRadius.circular(5)),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Tetikleyici: ${analysis['user_data']['tetikleyici'] ?? 'Belirtilmedi'}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: ttf)),
                      pw.SizedBox(height: 5),
                      pw.Text('Kaygı Seviyesi: ${analysis['user_data']['kaygiSeviyesi'] ?? '-'}', style: pw.TextStyle(font: ttf)),
                      pw.SizedBox(height: 5),
                      if (analysis['user_data']['notlar'] != null && analysis['user_data']['notlar'].isNotEmpty)
                        pw.Text('Notlar: ${analysis['user_data']['notlar']}', style: pw.TextStyle(font: ttf)),
                      pw.SizedBox(height: 10),
                      pw.Text('Yapay Zeka Analizi:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: ttf)),
                      pw.Text(analysis['ai_response'] ?? 'Analiz mevcut değil.', style: pw.TextStyle(font: ttf)),
                    ],
                  ),
                );
              }).toList(),
            ],
          );
        },
      ),
    );
  }

  // PDF dosyasını kaydetme
  final output = await getTemporaryDirectory();
  final file = File("${output.path}/duygusal_rapor.pdf");
  await file.writeAsBytes(await pdf.save());

  return file;
}

// Bu fonksiyon, grafik verilerini bir resme dönüştürmek için tasarlanmıştır.
// fl_chart'ın bu işlevi doğrudan desteklemediğini unutmayın.
// Gerçek bir uygulamada, bu grafik verilerini bir widget'a çizip o widget'ın
// resim çıktısını almanız gerekebilir. Bu bir placeholder fonksiyondur.
Future<pw.ImageProvider> _generateChartImage(List<FlSpot> spots) async {
  // Burası, çizgi grafiğini bir resim olarak oluşturmak için
  // daha karmaşık bir mantık gerektirebilir.
  // Bu örnekte, sadece bir yer tutucu resim kullanıyoruz.
  final ByteData byteData = await rootBundle.load('assets/images/chart_placeholder.png');
  final Uint8List list = byteData.buffer.asUint8List();
  return pw.MemoryImage(list);
}