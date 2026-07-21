import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/network/api_client.dart';

typedef SourceCache = ({List<Map<String, dynamic>> items, DateTime? syncedAt});

/// 서버가 해당 소스의 API 키를 아직 설정하지 않아 503을 반환했을 때 (다른 네트워크 오류와 구분해
/// UI가 "동기화 실패"가 아니라 "키 미설정"으로 보여줄 수 있게 함).
class SourceKeyMissingException implements Exception {
  final String sourceId;
  const SourceKeyMissingException(this.sourceId);
}

String _cacheKey(String sourceId) => 'gov_benefits_cache_v1_$sourceId';

/// 프록시 서버(`hyetaek/server/`)의 소스 레지스트리(`/api/sources/:id`)를 통해 정부 오픈API
/// 최신 데이터를 받아오고, 오프라인에서도 마지막 동기화 결과를 보여줄 수 있도록 소스별로 로컬 캐시한다
/// (docs/04 5번 원칙). seed 데이터는 이 repository가 전혀 건드리지 않는다 — 병합은 provider 쪽 책임.
class BenefitSyncRepository {
  const BenefitSyncRepository();

  Future<List<Map<String, dynamic>>> fetchSourceItems(String sourceId) async {
    try {
      final response = await apiClient.get('/api/sources/$sourceId');
      return (response.data['items'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 503) throw SourceKeyMissingException(sourceId);
      rethrow;
    }
  }

  Future<void> saveCache(String sourceId, List<Map<String, dynamic>> items, DateTime syncedAt) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode({'syncedAt': syncedAt.toIso8601String(), 'items': items});
    await prefs.setString(_cacheKey(sourceId), payload);
  }

  Future<SourceCache> loadCache(String sourceId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey(sourceId));
    if (raw == null) return (items: <Map<String, dynamic>>[], syncedAt: null);

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final syncedAt = DateTime.tryParse(decoded['syncedAt'] as String? ?? '');
      final items = (decoded['items'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      return (items: items, syncedAt: syncedAt);
    } catch (_) {
      return (items: <Map<String, dynamic>>[], syncedAt: null);
    }
  }
}
