class FirstAidTopic {
  final String id;
  final String title;
  final String subline;
  final String guide;

  FirstAidTopic({
    required this.id,
    required this.title,
    required this.subline,
    required this.guide,
  });

  factory FirstAidTopic.fromJson(Map<String, dynamic> json) {
    return FirstAidTopic(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      subline: json['subline'] ?? '',
      guide: json['guide'] ?? '',
    );
  }
}
