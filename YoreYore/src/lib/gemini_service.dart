import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  static Future<Map<String, dynamic>> generateRecipe(
      List<String> ingredients) async {

    final apiKey = dotenv.env['GEMINI_API_KEY'];

    final url =
        'https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent?key=$apiKey';

    final prompt = '''
너는 한국과 일본 가정식 전문 요리사다.

다음 규칙을 반드시 지켜라.

[식재료 판별 규칙]
1. 입력값이 실제 식재료인지 판단하라.
2. 한국/일본에서 일반적으로 식재료로 사용하는 재료도 모두 허용한다.
예:
된장, 고추장, 미림, 시소, 낫토, 다시마, 곤약, 유부, 가쓰오부시, 우엉 등

3. 아래와 같은 경우 식재료가 아니다.
- 사람
- 동물(반려동물 포함)
- 사물
- 장소
- 직업
- 추상 개념

식재료가 아니면 반드시 아래 문장만 정확히 출력:
INVALID_INPUT

[레시피 생성 규칙]
1. 입력된 재료만 사용하라.
2. 없는 재료를 절대 추가하지 마라.
'''+
/*3. 조미료(소금, 후추, 간장 등)도 입력되지 않았다면 추가 금지*/
        '''
4. 한국 또는 일본 가정에서 현실적으로 만들 수 있어야 한다.
5. 초보자도 따라할 수 있게 작성하라.
6. 조리 시간은 15분 이내 우선
7. 가장 맛있고 자연스러운 조합 1개만 제시하라.

재료:
${ingredients.join(', ')}

아래 형식을 정확히 지켜라.

요리 이름:
(한 줄)

예상 조리 시간:
(분)

난이도:
(쉬움/보통)

조리 방법:
1.
2.
3.

팁:
(있으면 작성)
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

    if (response.statusCode != 200) {
      return {
        'success': false,
        'message': 'API 오류 발생 (${response.statusCode})'
      };
    }

    final data = jsonDecode(response.body);
    final candidates = data['candidates'];

    if (candidates == null || candidates.isEmpty) {
      return {
        'success': false,
        'message': '레시피 생성 실패'
      };
    }

    final text = candidates[0]['content']['parts'][0]['text'];

    if (text.contains('INVALID_INPUT')) {
      return {
        'success': false,
        'message': '❌ 식재료만 입력해주세요.'
      };
    }

    return {
      'success': true,
      'message': text
    };
  }
}