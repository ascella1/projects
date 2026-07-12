import 'dart:convert';
import 'package:http/http.dart' as http;

class ClaudeAIService {
  final String _apiKey;
  final String _endpoint = 'https://api.anthropic.com/v1/messages';
  final String _model = 'claude-haiku-4-5';

  ClaudeAIService(this._apiKey);

  Future<Map<String, dynamic>> generateQuestTree({
    required String goal,
    required String job,
    required String level,
    required String duration,
    required int weeklyHours,
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception('CLAUDE_API_KEY is empty');
    }

    final prompt = '''
너는 현실적이고 감성적인 라이프 코칭 RPG 게임의 게임마스터 AI다.
사용자의 목표를 대목표 1개, 중목표 2개, 소목표 2개, 일일 퀘스트 최소 10개(최대 15개)로 세분화하라.
일일 퀘스트는 오늘 바로 실천할 수 있는 아주 작고 구체적인 습관 단위(예: 물 한 컵 마시기, 5분 스트레칭)로 최소 10개 이상 만들어야 한다.

사용자 정보:
- 직업: $job
- 숙련도: $level
- 목표 기한: $duration
- 가용 시간: ${weeklyHours}시간/주
- 목표: $goal
''';

    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': _apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': _model,
        'max_tokens': 4096,
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
        'output_config': {
          'format': {
            'type': 'json_schema',
            'schema': {
              'type': 'object',
              'properties': {
                'quests': {
                  'type': 'array',
                  'items': {
                    'type': 'object',
                    'properties': {
                      'title': {'type': 'string'},
                      'depth': {'type': 'integer'},
                      'difficulty': {
                        'type': 'string',
                        'enum': ['easy', 'medium', 'hard'],
                      },
                      'rewardStats': {
                        'type': 'array',
                        'items': {'type': 'string'},
                      },
                      'rewardExp': {'type': 'integer'},
                    },
                    'required': [
                      'title',
                      'depth',
                      'difficulty',
                      'rewardStats',
                      'rewardExp',
                    ],
                    'additionalProperties': false,
                  },
                },
              },
              'required': ['quests'],
              'additionalProperties': false,
            },
          },
        },
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Claude API request failed: ${response.body}');
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));

    if (decoded['stop_reason'] == 'refusal') {
      throw Exception('Claude refused the request');
    }

    final content = decoded['content'] as List<dynamic>? ?? [];
    final textBlock = content.firstWhere(
      (b) => b['type'] == 'text',
      orElse: () => null,
    );

    if (textBlock == null) {
      throw Exception('No text content returned from Claude API');
    }

    return jsonDecode(textBlock['text'] as String) as Map<String, dynamic>;
  }
}
