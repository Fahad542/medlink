enum MessageType { TEXT, IMAGE, FILE }

class ChatMessageModel {
  final int id;
  final int appointmentId;
  final int senderId;
  final MessageType messageType;
  final String? body;
  final String? mediaUrl;
  final DateTime sentAt;

  ChatMessageModel({
    required this.id,
    required this.appointmentId,
    required this.senderId,
    required this.messageType,
    this.body,
    this.mediaUrl,
    required this.sentAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'],
      appointmentId: json['appointmentId'],
      senderId: json['senderId'],
      messageType: _parseMessageType(json['messageType']),
      body: json['body'],
      mediaUrl: json['mediaUrl'],
      sentAt: DateTime.parse(json['sentAt']),
    );
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
