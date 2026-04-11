enum MessageType { TEXT, IMAGE, FILE }

class ChatMessageModel {
  final int id;
  final int? appointmentId;
  final int? sosId;
  final int? tripId;
  final int senderId;
  final MessageType messageType;
  final String? body;
  final String? mediaUrl;
  final DateTime sentAt;

  ChatMessageModel({
    required this.id,
    this.appointmentId,
    this.sosId,
    this.tripId,
    required this.senderId,
    required this.messageType,
    this.body,
    this.mediaUrl,
    required this.sentAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: _asInt(json['id']),
      appointmentId: _asIntOrNull(json['appointmentId']),
      sosId: _asIntOrNull(json['sosId']),
      tripId: _asIntOrNull(json['tripId']),
      senderId: _asInt(json['senderId']),
      messageType: _parseMessageType(json['messageType']),
      body: json['body'],
      mediaUrl: json['mediaUrl'],
      sentAt: DateTime.parse(json['sentAt'].toString()),
    );
  }

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  static int? _asIntOrNull(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  static MessageType _parseMessageType(String? type) {
    switch (type) {
      case 'IMAGE':
        return MessageType.IMAGE;
      case 'FILE':
        return MessageType.FILE;
      case 'TEXT':
      default:
        return MessageType.TEXT;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'appointmentId': appointmentId,
      'senderId': senderId,
      'messageType': messageType.toString().split('.').last,
      'body': body,
      'mediaUrl': mediaUrl,
      'sentAt': sentAt.toIso8601String(),
    };
  }
}
