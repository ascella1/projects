import 'package:flutter/material.dart';
import 'gemini_service.dart';
import 'ingredient_parser.dart';

class RecipePage extends StatefulWidget {
  const RecipePage({super.key});

  @override
  State<RecipePage> createState() => _RecipePageState();
}

class _RecipePageState extends State<RecipePage> {
  final TextEditingController _controller = TextEditingController();
  String result = '';
  bool isLoading = false;

  Future<void> _generateRecipe() async {
    setState(() => isLoading = true);

    final ingredients = parseIngredients(_controller.text);
    final recipe = await GeminiService.generateRecipe(ingredients);

    setState(() {
      result = recipe;
      isLoading = false;
    });
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
                hintText: '재료 입력 (예: 파 계란)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: isLoading ? null : _generateRecipe,
              child: const Text('레시피 생성'),
            ),
            const SizedBox(height: 20),
            if (isLoading)
              const CircularProgressIndicator()
            else
              Expanded(
                child: SingleChildScrollView(
                  child: Text(result),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
