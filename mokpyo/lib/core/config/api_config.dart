// =====================================================
//  AI API 키 설정 파일
//  키는 빌드 시 --dart-define으로 전달하세요.
//
//  Claude API 키 발급: https://console.anthropic.com/settings/keys
//  Gemini API 키 발급: https://aistudio.google.com/app/apikey
//  OpenAI API 키 발급: https://platform.openai.com/api-keys
//
//  예: flutter run --dart-define=CLAUDE_API_KEY=... --dart-define=GEMINI_API_KEY=...
//  키가 있는 것만 전달해도 됩니다.
//  우선순위: Claude → Gemini → OpenAI → 키워드 기반 기본 퀘스트
// =====================================================

const String claudeApiKey = String.fromEnvironment('CLAUDE_API_KEY');
const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
const String openAiApiKey = String.fromEnvironment('OPENAI_API_KEY');
