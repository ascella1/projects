import 'package:flutter/material.dart';
import 'recipe_post.dart';

class PostDetailPage extends StatelessWidget {
  final RecipePost post;

  const PostDetailPage({
    super.key,
    required this.post,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(post.title),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                '작성자: ${post.author}',
                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),

              const Divider(height: 30),

              Text(
                post.content,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}