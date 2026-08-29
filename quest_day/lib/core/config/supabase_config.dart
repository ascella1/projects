// ⚠️  Supabase 프로젝트 생성 후 아래 두 값을 채워주세요.
// 1. https://supabase.com → New project 생성
// 2. Settings > API 에서 URL / anon key 복사
class SupabaseConfig {
  static const projectUrl = 'https://YOUR_PROJECT_ID.supabase.co';
  static const anonKey    = 'YOUR_ANON_KEY';

  // 설정 전 여부 체크 (개발 편의용)
  static bool get isConfigured =>
      !projectUrl.contains('YOUR_') && !anonKey.contains('YOUR_');
}
