class InAppNotificationModel {
  final String id;
  final String title;
  final String body;
  final String? type;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;

  InAppNotificationModel({
    required this.id,
    required this.title,
    required this.body,
    this.type,
    this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory InAppNotificationModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedAt = DateTime.now();
    final raw = json['createdAt'];
    if (raw != null) {
      final d = DateTime.tryParse(raw.toString());
      if (d != null) parsedAt = d.toLocal();
    }
    Map<String, dynamic>? dataMap;
    final dm = json['data'];
    if (dm is Map) {
      dataMap = Map<String, dynamic>.from(dm);
    }
    return InAppNotificationModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      type: json['type']?.toString(),
      data: dataMap,
      isRead: json['isRead'] == true ||
          json['read'] == true ||
          json['is_read'] == true ||
          json['seen'] == true,
      createdAt: parsedAt,
    );
  }

  InAppNotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    String? type,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return InAppNotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
