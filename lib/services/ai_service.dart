// services/ai_service.dart

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIService {
  static Future<String?> generateSuggestions(String chatHistory) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: dotenv.env['GEMINI_API_KEY']!,
      );

      final prompt = """
      Sen destekleyici bir zihinsel sağlık asistanısın. Aşağıdaki sohbet geçmişine dayanarak, kullanıcının ruh halini ve durumunu iyileştirmesine yardımcı olacak 3 ila 5 kısa, uygulanabilir ve nazik öneri listesi oluştur. Önerileri numaralandırılmış bir liste formatında sun.

      Örnek:
      1. Meditasyon yap.
      2. Bir arkadaşınla konuş.

      Sohbet geçmişi:
      $chatHistory
      """;

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      if (response.text != null) {
        return response.text;
      }
    } catch (e) {
      print('Öneri oluşturulurken hata oluştu: $e');
    }
    return null;
  }
}