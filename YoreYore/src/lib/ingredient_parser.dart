List<String> parseIngredients(String input) {
  return input
      .replaceAll(RegExp(r'[,/|]'), ' ')
      .split(RegExp(r'\s+'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toSet()
      .toList();
}
