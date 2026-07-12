import 'package:flutter_test/flutter_test.dart';
import 'package:mokpyo/core/services/google_ai_service.dart';

void main() {
  group('GoogleAIService', () {
    test('parses a Gemini JSON response into a quest tree payload', () {
      const rawResponse = '{"quests":[{"title":"매일 30분 공부하기","depth":4,"difficulty":"easy","rewardStats":["knowledge"],"rewardExp":10}]}';

      final parsed = GoogleAIService.parseQuestTreeResponse(rawResponse);

      expect(parsed['quests'], isA<List>());
      expect(parsed['quests'][0]['title'], '매일 30분 공부하기');
      expect(parsed['quests'][0]['depth'], 4);
      expect(parsed['quests'][0]['rewardStats'], ['knowledge']);
    });
  });
}
