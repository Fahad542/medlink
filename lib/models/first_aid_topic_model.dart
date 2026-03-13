class FirstAidTopic {
  final int id;
  final String title;
  final String content;
  final String category;

  FirstAidTopic({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
  });

  factory FirstAidTopic.fromJson(Map<String, dynamic> json) {
    return FirstAidTopic(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      category: json['category'] ?? '',
    );
  }
}
