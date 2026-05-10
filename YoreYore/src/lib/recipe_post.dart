class RecipePost {
  final String title;
  final String content;
  int likes;
  final String author;

  RecipePost({
    required this.title,
    required this.content,
    required this.author,
    this.likes = 0,
  });
}