import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  static Future<String> generateRecipe(List<String> ingredients) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];

    final url =
        'https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent?key=$apiKey';

    final prompt = '''
너는 요리 전문가다.
아래 재료만 사용해서 요리 레시피를 만들어라.
없는 재료는 절대 추가하지 마라.

재료: ${ingredients.join(', ')}

출력 형식:
- 요리 이름
- 조리 방법
''';

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": prompt}
            ]
          }
        ]
      }),
    );

    // 🔴 에러 응답 방어
    if (response.statusCode != 200) {
      return '❌ API 오류 발생 (${response.statusCode})\n${response.body}';
    }

    final data = jsonDecode(response.body);

    // 🔴 안전하게 접근
    final candidates = data['candidates'];
    if (candidates == null || candidates.isEmpty) {
      return '❌ 레시피를 생성하지 못했습니다.';
    }

    return candidates[0]['content']['parts'][0]['text'];
  }
}
