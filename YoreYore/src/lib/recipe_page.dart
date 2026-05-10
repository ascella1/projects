import 'package:flutter/material.dart';
import 'gemini_service.dart';
import 'ingredient_parser.dart';
import 'write_post_page.dart';

class RecipePage extends StatefulWidget {
  const RecipePage({super.key});

  @override
  State<RecipePage> createState() => _RecipePageState();
}

class _RecipePageState extends State<RecipePage> {
  // 입력창 컨트롤러
  final TextEditingController _controller = TextEditingController();

  // 화면에 표시될 결과
  String result = '';

  // 로딩 여부
  bool isLoading = false;

  // 실제 레시피 생성 성공 여부
  bool isRecipeValid = false;

  Future<void> _generateRecipe() async {
    setState(() {
      isLoading = true;
      result = '';
      isRecipeValid = false;
    });

    // 재료 파싱
    final ingredients = parseIngredients(_controller.text);

    // Gemini 호출
    final response = await GeminiService.generateRecipe(ingredients);

    setState(() {
      result = response['message'];
      isRecipeValid = response['success'];
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('레시피 검색'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 입력창
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: '재료 입력',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            // 생성 버튼
            ElevatedButton(
              onPressed: isLoading ? null : _generateRecipe,
              child: const Text('레시피 생성'),
            ),

            const SizedBox(height: 20),

            // 로딩
            if (isLoading)
              const CircularProgressIndicator()

            // 결과 출력
            else if (result.isNotEmpty)
              Expanded(
                child: SingleChildScrollView(
                  child: Text(result),
                ),
              ),

            // 성공한 레시피일 때만 게시글 버튼 표시
            if (isRecipeValid) ...[
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WritePostPage(recipe: result),
                    ),
                  );
                },
                child: const Text('게시글 작성'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}