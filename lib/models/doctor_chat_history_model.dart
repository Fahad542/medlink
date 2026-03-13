import 'package:medlink/core/constants/app_url.dart';

class DoctorChatHistoryModel {
  bool? success;
  List<DoctorChatHistoryData>? data;

  DoctorChatHistoryModel({this.success, this.data});

  DoctorChatHistoryModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['data'] != null) {
      data = <DoctorChatHistoryData>[];
      json['data'].forEach((v) {
        data!.add(DoctorChatHistoryData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class DoctorChatHistoryData {
  Patient? patient;
  String? lastMessage;
  String? lastMessageDate;
  int? unreadCount;

  DoctorChatHistoryData({
    this.patient,
    this.lastMessage,
    this.lastMessageDate,
    this.unreadCount,
  });

  DoctorChatHistoryData.fromJson(Map<String, dynamic> json) {
    patient = json['patient'] != null ? Patient.fromJson(json['patient']) : null;
    lastMessage = json['lastMessage'];
    lastMessageDate = json['lastMessageDate'];
    unreadCount = json['unreadCount'] ?? 0;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (patient != null) {
      data['patient'] = patient!.toJson();
    }
    data['lastMessage'] = lastMessage;
    data['lastMessageDate'] = lastMessageDate;
    data['unreadCount'] = unreadCount;
    return data;
  }
}

class Patient {
  int? id;
  String? fullName;
  String? profilePhotoUrl;

  Patient({this.id, this.fullName, this.profilePhotoUrl});

  Patient.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    fullName = json['fullName'];
    profilePhotoUrl = AppUrl.getFullUrl(json['profilePhotoUrl']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['fullName'] = fullName;
    data['profilePhotoUrl'] = profilePhotoUrl;
    return data;
  }
}
