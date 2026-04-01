import 'package:medlink/models/user_model.dart';

class ConversationModel {
  final String id;
  final String? lastMessage;
  final String? lastMessageTime;
  final String? lastMessageType;
  final int? unreadCount;
  final UserModel? otherUser;
  final String? appointmentId;

  ConversationModel({
    required this.id,
    this.lastMessage,
    this.lastMessageTime,
    this.lastMessageType,
    this.unreadCount,
    this.otherUser,
    this.appointmentId,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id']?.toString() ?? '',
      lastMessage: json['lastMessage'] ?? json['body'],
      lastMessageTime: json['lastMessageTime'] ?? json['sentAt'],
      lastMessageType: json['lastMessageType'] ?? json['messageType'],
      unreadCount: json['unreadCount'] ?? 0,
      otherUser: json['otherUser'] != null ? UserModel.fromJson(json['otherUser']) : null,
      appointmentId: json['appointmentId']?.toString(),
    );
  }
}
