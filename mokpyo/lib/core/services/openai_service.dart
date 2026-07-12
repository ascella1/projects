import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenAIService {
  final String _apiKey;
  final String _endpoint = "https://api.openai.com/v1/chat/completions";

  OpenAIService(this._apiKey);

  Future<Map<String, dynamic>> generateQuestTree({
    required String goal,
    required String job,
    required String level,
    required String duration,
    required int weeklyHours,
  }) async {
    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $_apiKey",
      },
      body: jsonEncode({
        "model": "gpt-4o-mini",
        "response_format": {"type": "json_object"},
        "messages": [
          {
            "role": "system",
            "content": "너는 현실적이고 감성적인 라이프 코칭 RPG 게임의 게임마스터 AI이다. 사용자의 거대한 현실 목표를 계층화(대목표 -> 중목표 -> 소목표 -> 일일 퀘스트)하여 분해하고 JSON 형태로만 응답하라. 사용자의 직업, 가용 시간, 목표 기간 등을 감안하여 아주 구체적이고 바로 실천 가능한 퀘스트로 쪼개야 한다. 응답 포맷: {'quests': [{'title': '...', 'depth': 4, 'difficulty': 'easy', 'rewardStats': ['knowledge'], 'rewardExp': 10}]}"
          },
          {
            "role": "user",
            "content": "사용자 정보: 직업: $job, 숙련도: $level, 목표 기한: $duration, 가용 시간: ${weeklyHours}시간/주. 목표: $goal. 위 정보를 기준으로 목표를 대목표 1개, 중목표 2개, 소목표 각 2개로 분해하고, 그리고 당장 오늘부터 실천할 아주 작고 구체적인 습관 단위의 일일 퀘스트를 최소 10개(최대 15개, 난이도 포함)로 상세 분해하며, 완료 시 올라갈 능력치(career, health, knowledge, money, communication 중 1~2개 선택)를 지정하라."
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final String content = decoded['choices'][0]['message']['content'];
      return jsonDecode(content);
    } else {
      throw Exception("OpenAI API request failed: ${response.body}");
    }
  }

  Future<String> generateCoachingMessage({
    required String questTitle,
    required int failedDays,
    required String characterType,
  }) async {
    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $_apiKey",
      },
      body: jsonEncode({
        "model": "gpt-4o-mini",
        "messages": [
          {
            "role": "system",
            "content": "너는 '고양이와 스프' 풍의 따뜻하고 감성적인 다독여주는 힐링 코치 AI이다. 사용자가 특정 퀘스트를 지속적으로 실패해 낙담했을 때 다정한 말과 난이도 하향 대안을 친절하게 제시한다. 3문장 이내로 작성하라."
          },
          {
            "role": "user",
            "content": "실패한 퀘스트: '$questTitle', 실패 일수: $failedDays일, 유저 캐릭터: $characterType. 따뜻한 위로와 난이도를 절반으로 줄일 수 있는 대안을 제시해줘."
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      return decoded['choices'][0]['message']['content'].toString().trim();
    } else {
      throw Exception("OpenAI API request failed: ${response.body}");
    }
  }
}
