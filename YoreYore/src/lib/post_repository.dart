import 'recipe_post.dart';

class PostRepository {
  // private
  static final List<RecipePost> _posts = [];

  // 읽기 전용
  static List<RecipePost> get posts => _posts;

  static void addPost(RecipePost post) {
    _posts.add(post);
  }

  static void likePost(int index) {
    _posts[index].likes++;
  }
}