import 'package:flutter/material.dart';
import 'post_repository.dart';
import 'post_detail_page.dart';

class BoardPage extends StatefulWidget {
  const BoardPage({super.key});

  @override
  State<BoardPage> createState() => _BoardPageState();
}

class _BoardPageState extends State<BoardPage> {
  void likePost(int index) {
    setState(() {
      PostRepository.likePost(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final posts = PostRepository.posts;

    return Scaffold(
      appBar: AppBar(title: const Text('게시판')),

      body: ListView.builder(
        itemCount: posts.length,

        itemBuilder: (context, index) {
          final post = posts[index];

          return Card(
            child: ListTile(
              title: Text(post.title),
              subtitle: Text('추천 ${post.likes}'),

              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PostDetailPage(post: post),
                  ),
                );
              },

              trailing: IconButton(
                icon: const Icon(Icons.star),
                onPressed: () => likePost(index),
              ),
            ),
          );
        },
      ),
    );
  }
}