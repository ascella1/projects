import 'package:flutter/material.dart';
import 'recipe_post.dart';
import 'post_repository.dart';

class WritePostPage extends StatefulWidget {
  final String recipe;

  const WritePostPage({
    super.key,
    required this.recipe,
  });

  @override
  State<WritePostPage> createState() => _WritePostPageState();
}

class _WritePostPageState extends State<WritePostPage> {
  final titleController = TextEditingController();

  void submitPost() {
    PostRepository.addPost(
      RecipePost(
        title: titleController.text,
        content: widget.recipe,
        author: '익명',
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('게시글 작성')),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                hintText: '제목 입력',
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: submitPost,
              child: const Text('등록'),
            ),
          ],
        ),
      ),
    );
  }
}