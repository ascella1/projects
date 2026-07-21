import 'package:dio/dio.dart';

/// 정부 오픈API 키를 앱에 직접 넣지 않기 위한 프록시 서버(`hyetaek/server/`) 전용 클라이언트.
/// 로컬 개발 기본값은 `http://localhost:8787`이며, 배포 시 프록시 주소를 바꾸려면
/// `flutter run --dart-define=PROXY_BASE_URL=https://...` 로 override 한다.
const _proxyBaseUrl = String.fromEnvironment(
  'PROXY_BASE_URL',
  defaultValue: 'http://localhost:8787',
);

final Dio apiClient = Dio(
  BaseOptions(
    baseUrl: _proxyBaseUrl,
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
  ),
);
