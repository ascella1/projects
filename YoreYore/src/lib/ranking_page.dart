import 'package:flutter/material.dart';
import 'post_repository.dart';

class RankingPage extends StatelessWidget {
  const RankingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final sorted = [...PostRepository.posts]
      ..sort((a, b) => b.likes.compareTo(a.likes));

    return Scaffold(
      appBar: AppBar(title: const Text('랭킹')),

      body: ListView.builder(
        itemCount: sorted.length,

        itemBuilder: (context, index) {
          final post = sorted[index];

          return ListTile(
            leading: Text('${index + 1}'),
            title: Text(post.title),
            subtitle: Text('추천 ${post.likes}'),
          );
        },
      ),
    );
  }
}