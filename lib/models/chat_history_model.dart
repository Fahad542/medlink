import 'package:medlink/core/constants/app_url.dart';

class ChatHistoryDoctorModel {
  final int id;
  final String fullName;
  final String? profilePhotoUrl;

  ChatHistoryDoctorModel({
    required this.id,
    required this.fullName,
    this.profilePhotoUrl,
  });

  factory ChatHistoryDoctorModel.fromJson(Map<String, dynamic> json) {
    return ChatHistoryDoctorModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      fullName: json['fullName'] ?? 'Unknown Doctor',
      profilePhotoUrl: AppUrl.getFullUrl(json['profilePhotoUrl']),
    );
  }
}

class ChatHistoryModel {
  final String id; // Potential appointmentId
  final ChatHistoryDoctorModel doctor;
  final String lastMessage;
  final DateTime lastMessageDate;

  ChatHistoryModel({
    required this.id,
    required this.doctor,
    required this.lastMessage,
    required this.lastMessageDate,
  });

  factory ChatHistoryModel.fromJson(Map<String, dynamic> json) {
    return ChatHistoryModel(
      id: json['id']?.toString() ?? '',
      doctor: ChatHistoryDoctorModel.fromJson(json['doctor'] ?? {}),
      lastMessage: json['lastMessage'] ?? '',
      lastMessageDate: json['lastMessageDate'] != null 
          ? DateTime.tryParse(json['lastMessageDate'])?.toLocal() ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
