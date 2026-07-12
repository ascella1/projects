import 'dart:convert';
import 'package:http/http.dart' as http;

class GoogleAIService {
  final String _apiKey;
  final String _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  GoogleAIService(this._apiKey);

  Future<Map<String, dynamic>> generateQuestTree({
    required String goal,
    required String job,
    required String level,
    required String duration,
    required int weeklyHours,
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY is empty');
    }

    final prompt = '''
너는 현실적이고 감성적인 라이프 코칭 RPG 게임의 게임마스터 AI다.
사용자의 목표를 대목표 1개, 중목표 2개, 소목표 2개, 일일 퀘스트 최소 10개(최대 15개)로 세분화하고 JSON 형식으로만 응답하라.
일일 퀘스트는 오늘 바로 실천할 수 있는 아주 작고 구체적인 습관 단위(예: 물 한 컵 마시기, 5분 스트레칭)로 최소 10개 이상 만들어야 한다.
반드시 다음 JSON 형태로만 응답한다.
{"quests":[{"title":"...","depth":1,"difficulty":"hard","rewardStats":["knowledge"],"rewardExp":100}]}

사용자 정보:
- 직업: $job
- 숙련도: $level
- 목표 기한: $duration
- 가용 시간: ${weeklyHours}시간/주
- 목표: $goal
''';

    final response = await http.post(
      Uri.parse('$_endpoint?key=$_apiKey'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt},
            ],
          }
        ],
        'generationConfig': {
          'responseMimeType': 'application/json',
          'temperature': 0.7,
        },
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Google AI API request failed: ${response.body}');
    }

    return parseQuestTreeResponse(utf8.decode(response.bodyBytes));
  }

  static Map<String, dynamic> parseQuestTreeResponse(String responseBody) {
    final decoded = jsonDecode(responseBody);

    if (decoded is Map<String, dynamic> && decoded.containsKey('quests')) {
      return decoded;
    }

    final candidates = decoded['candidates'] as List<dynamic>? ?? [];
    if (candidates.isEmpty) {
      throw Exception('No candidates returned from Google AI API');
    }

    final content = candidates.first['content'];
    final parts = content?['parts'] as List<dynamic>? ?? [];
    final text = parts.isNotEmpty ? parts.first['text']?.toString() ?? '' : '';

    if (text.isEmpty) {
      throw Exception('Empty content returned from Google AI API');
    }

    final cleaned = text.trim();
    final jsonText = cleaned.replaceFirst(RegExp(r'^```json\s*'), '').replaceFirst(RegExp(r'\s*```$'), '');

    return jsonDecode(jsonText);
  }
}
