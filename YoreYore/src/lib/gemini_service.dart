/*JSON 문자열 <-> Dart 객체 변환을 위함*/
import 'dart:convert';
/*Http 통신을 하기 위한 package */
import 'package:http/http.dart' as http;
/*.env 파일에서 API Key 를 읽기 위한 package*/
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  /*Future<String> -> 비동기 함수*/
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
    // Http Post 요청
    // await -> 요청이 끝날때까지 기다림.
    final response = await http.post(
      //Uri 객체로 url 을 변환
      Uri.parse(url),
      // JSON 형식으로 보냄
      headers: {'Content-Type': 'application/json'},
      // Dart -> JSON 형태로 변환
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

    // response.statusCode == 200 인 경우 Positive response 가 온 경우.
    if (response.statusCode != 200) {
      return '❌ API 오류 발생 (${response.statusCode})\n${response.body}';
    }
    // JSON 문자열 -> Dart Map 형태로 변환
    final data = jsonDecode(response.body);

    // Gemini 응답에서 candidates 부분 꺼내기
    // Candidates = AI가 생성한 결과 목록
    final candidates = data['candidates'];
    if (candidates == null || candidates.isEmpty) {
      return '❌ 레시피를 생성하지 못했습니다.';
    }
    //candidates의 0번째 인자인 이유 -> gemini 에서 여러 답변을 준 경우를 상정
    return candidates[0]['content']['parts'][0]['text'];
  }
}
