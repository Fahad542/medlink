class QuickInstructionModel {
  final int id;
  final String title;
  final String content;
  final String createdAt;

  QuickInstructionModel({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
  });

  factory QuickInstructionModel.fromJson(Map<String, dynamic> json) {
    return QuickInstructionModel(
      id: json['id'],
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      createdAt: json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt,
    };
  }
}
