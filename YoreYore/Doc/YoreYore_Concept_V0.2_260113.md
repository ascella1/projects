# YoreYore

# 기능구현

# 1️⃣ Flutter 패키지 구성

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.0
  flutter_dotenv: ^5.1.0

```

👉 **이유**

- `http` : ChatGPT API 호출
- `dotenv` : API Key 보안 처리

---

# 2️⃣ OpenAI API Key 설정 (.env)

```
OPENAI_API_KEY=sk-xxxxxxxxxxxxxxxx

```

```dart
// main.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  runApp(const MyApp());
}

```

---

# 3️⃣ 재료 입력 파싱 로직 (핵심)

### ✔ 입력 예시 처리

| 입력 | 결과 |
| --- | --- |
| `파 계란` | `["파", "계란"]` |
| `파,계란` | `["파", "계란"]` |
| `파 / 계란` | `["파", "계란"]` |

### ✅ 파싱 함수

```dart
List<String> parseIngredients(String input) {
  return input
      .replaceAll(RegExp(r'[,/|]'), ' ')
      .split(RegExp(r'\s+'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toSet() // 중복 제거
      .toList();
}

```

---

# 4️⃣ GPT API 호출 서비스

```dart
class OpenAIService {
  static const _url = 'https://api.openai.com/v1/chat/completions';

  static Future<String> generateRecipe(List<String> ingredients) async {
    final response = await http.post(
      Uri.parse(_url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization':
            'Bearer ${dotenv.env['OPENAI_API_KEY']}',
      },
      body: jsonEncode({
        "model": "gpt-4o-mini",
        "messages": [
          {
            "role": "system",
            "content":
                "너는 요리 전문가다. 사용자가 제공한 재료만 사용하여 레시피를 만들어라."
          },
          {
            "role": "user",
            "content":
                "다음 재료만 사용해서 요리 레시피를 만들어줘: ${ingredients.join(', ')}"
          }
        ],
        "temperature": 0.7
      }),
    );

    final data = jsonDecode(response.body);
    return data['choices'][0]['message']['content'];
  }
}

```

🔥 **중요 포인트**

- ❌ 없는 재료 사용 방지 → **프롬프트에서 강제**
- ✔ GPT가 요리사 역할로 행동하도록 system prompt 지정

---

# 5️⃣ UI 구현 (검색 + 결과)

```dart
class RecipePage extends StatefulWidget {
  const RecipePage({super.key});

  @override
  State<RecipePage> createState() => _RecipePageState();
}

class _RecipePageState extends State<RecipePage> {
  final TextEditingController _controller = TextEditingController();
  String recipe = '';
  bool isLoading = false;

  Future<void> _search() async {
    setState(() => isLoading = true);

    final ingredients = parseIngredients(_controller.text);
    recipe = await OpenAIService.generateRecipe(ingredients);

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI 요리 레시피')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: '재료를 입력하세요 (예: 파 계란)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: isLoading ? null : _search,
              child: const Text('레시피 생성'),
            ),
            const SizedBox(height: 20),
            if (isLoading)
              const CircularProgressIndicator()
            else
              Expanded(
                child: SingleChildScrollView(
                  child: Text(recipe),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

```

---

# 6️⃣ 앱 실행 화면 흐름

1. 재료 입력
    
    👉 `파 계란`
    
2. GPT 요청
    
    👉 **파 + 계란만 사용한 레시피 생성**
    
3. 결과 표시
    
    👉 요리 이름 / 재료 / 조리 순서
    

---

# 🚀 다음 단계 (확장 아이디어)

이건 **진짜 서비스로 발전 가능한 포인트**야:

### 🔹 기능 확장

- [ ]  사용자가 직접 레시피 작성 → AI 추천 우선 노출
- [ ]  칼로리 / 난이도 / 조리 시간 옵션
- [ ]  이미지 생성 (DALL·E)
- [ ]  즐겨찾기 / 히스토리
- [ ]  로그인 (Firebase)

### 🔹 기술 확장

- Riverpod / Bloc 상태관리
- GPT Function Calling
- 서버 분리 (Node / FastAPI)

---

# 0. History

| Date | SW Version | Notes |
| --- | --- | --- |
| 26/01/11 | V1.0 | 초기 Service concept 정의 |
|  |  |  |

## 1️⃣ 서비스 한 줄 요약 (Value Proposition)

냉장고에 있는 재료만 입력하면, 지금 당장 만들 수 있는 요리를 AI가 만들어주는 앱

- 매일 “뭐 해먹지?” 고민 해결
- 재료 낭비 감소
- 검색 피로 제거

---

## 2️⃣ 타깃 사용자 (10만+ 가능 근거)

| 타깃 | 이유 |
| --- | --- |
| 1인 가구 / 자취생 | 냉장고 재료 한정 |
| 맞벌이 직장인 | 빠른 의사결정 필요 |
| 요리 초보 | 검색보다 가이드 필요 |
| 다이어트/헬스 유저 | 재료 기반 식단 관리 |
| 주부 | 재료 소진 목적 |

---

## 3️⃣ 핵심 기능 상세 설계

### ✅ 1. 재료 입력 & 자동 인식

**UX 포인트**

- 텍스트 입력: `파, 계란, 두부`
- 자동 처리:
    - 공백/쉼표/엔터 구분
    - 동의어 처리 (대파=파)
    - AI 재료 정규화

**추가 기능(중독성)**

- 📷 사진으로 재료 인식 (추후)
- 자주 쓰는 재료 자동 추천

---

### ✅ 2. AI 레시피 추천 시스템 (핵심)

### 🔹 2-1. 사용자 작성 레시피 우선 노출

- 사용자가 이전에 작성한 레시피가
    - 입력 재료와 70% 이상 일치 AND 평점이 높은 순서를 상단에 위치
    
    → **추후 옵션 기능 중 재료 완벽 일치/일부 일치 와 같은 기능 추가** 
    
- 커뮤니티 기여자 보상 구조 가능

### 🔹 2-2. AI 생성 레시피

**출력 구성**

- 요리명
- 난이도 / 소요시간
- 필요한 추가 재료
- 조리 단계 (Step-by-step)
- 팁 / 대체 재료

**차별화 포인트**

- “지금 가진 재료 기준”으로 생성
- 부족한 재료 최소화 옵션
- 🔥 인기/평점 기반 조합 강화

---

### ✅ 3. 레시피 게시글 작성 기능 (커뮤니티화)

**왜 중요한가?**

> AI 앱 → 콘텐츠 플랫폼으로 진화
> 
> 
> → SEO + 유저 체류시간 + 수익화 핵심
> 

**게시글 기능**

- AI 레시피 → “내 레시피로 저장”
- 사진 첨부
- 태그 (#자취요리 #다이어트)
- 좋아요 / 북마크 / 댓글

📌 **장기적으로 AI 비용 절감 효과도 있음**

---

## 4️⃣ 반드시 필요한 “10만 유저 요소” (중독성 설계)

### 🔥 재방문을 만드는 장치

- 오늘의 추천 요리 (푸시)
- 냉장고 재료 저장 → 자동 알림
- “이 재료 오늘 안 쓰면 버려짐” 알림
- 레시피 streak (연속 요리 기록)

## 5️⃣ 수익화 모델 (❗핵심)

### 💰 1. 프리미엄 구독 (가장 현실적)

| 무료 | 유료 |
| --- | --- |
| 하루 3회 AI 생성 | 무제한 |
| ~~기본 레시피~~ | ~~고급 레시피~~ |
| 광고 포함 | 광고 제거 |
| ~~커뮤니티 읽기~~ | ~~작성/저장 무제한~~ |

👉 **월 3,900~5,900원**

👉 전환율 2%만 돼도 10만 MAU → 월 수익 수천만 원 가능

---

### 💰 2. 광고 (보조 수익)

- 레시피 보기 전 네이티브 광고
- 재료/마트 광고
- “이 재료 할인 중” 배너

# Unsorted

- 검색창에 재료 입력 및 레시피를 입력
1. if 레시피 있음 → 레시피 랭킹 보여주기
2. if 레시피 없음 → AI 기반 추천 레시피 
    - 레시피를 제공받은 경우 나만보기/글올리기 옵션 → 글올리기를 기반으로 인기메뉴 보여줌

→ app 이름 : 요래요레(요래 요리레시피) 

flutter 언어 기반으로 AI 를 통해 요리 레시피를 만들어주는 어플을 만들려고 해.

핵심 기능으로는 

1. 검색창에 요리 재료를 입력 ( ex : 파, 계란 → 복수인 경우 알아서 문자열 처리 후 인식 )
2. 검색 결과로 AI 추천 레시피를 알려줌
    1. 만약 사용자가 기재한 레시피가 있는경우 우선 표시 
3. 결과 레시피 제공 후, 사용자의 요청에 따라 게시글로 기재 할 수 있는 기능있음