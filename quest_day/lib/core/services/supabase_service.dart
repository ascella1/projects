import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/supabase_config.dart';
import '../models/special_mission.dart';

class SupabaseService {
  static const _table = 'special_mission_claims';

  Map<String, String> get _headers => {
        'apikey': SupabaseConfig.anonKey,
        'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
        'Content-Type': 'application/json',
      };

  Uri _uri(String path, [Map<String, String>? query]) => Uri.parse(
        '${SupabaseConfig.projectUrl}/rest/v1/$path',
      ).replace(queryParameters: query);

  // 오늘 선착순 현황 조회
  Future<SpecialMissionClaim?> fetchTodayClaim(String date) async {
    final resp = await http
        .get(_uri(_table, {'date': 'eq.$date', 'limit': '1'}), headers: _headers)
        .timeout(const Duration(seconds: 8));

    if (resp.statusCode != 200) {
      throw Exception('fetchTodayClaim: ${resp.statusCode} ${resp.body}');
    }
    final list = jsonDecode(resp.body) as List;
    if (list.isEmpty) return null;
    return SpecialMissionClaim.fromJson(list.first as Map<String, dynamic>);
  }

  // 선착순 도전 — 201: 내가 1등, 409: 이미 누군가 했음
  Future<({bool isWinner, SpecialMissionClaim? existingClaim})> claimMission({
    required String date,
    required String nickname,
    required String deviceId,
  }) async {
    final resp = await http
        .post(
          _uri(_table),
          headers: {..._headers, 'Prefer': 'return=minimal'},
          body: jsonEncode({
            'date': date,
            'claimer_nickname': nickname,
            'claimer_device_id': deviceId,
          }),
        )
        .timeout(const Duration(seconds: 8));

    if (resp.statusCode == 201) {
      // 내가 1등
      return (
        isWinner: true,
        existingClaim: SpecialMissionClaim(
          claimerNickname: nickname,
          claimerDeviceId: deviceId,
          claimedAt: DateTime.now(),
        ),
      );
    }

    if (resp.statusCode == 409) {
      // 이미 누군가 완료 — 누구인지 조회
      final existing = await fetchTodayClaim(date);
      return (isWinner: false, existingClaim: existing);
    }

    throw Exception('claimMission: ${resp.statusCode} ${resp.body}');
  }
}
