import 'package:medlink/core/constants/app_url.dart';

class DoctorChatHistoryModel {
  bool? success;
  List<DoctorChatHistoryData>? data;

  DoctorChatHistoryModel({this.success, this.data});

  DoctorChatHistoryModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['data'] != null) {
      data = <DoctorChatHistoryData>[];
      final raw = json['data'];
      if (raw is List) {
        for (final v in raw) {
          if (v is Map<String, dynamic>) {
            try {
              data!.add(DoctorChatHistoryData.fromJson(v));
            } catch (e) {
              // Skip malformed rows; keep rest of list
            }
          } else if (v is Map) {
            try {
              data!.add(DoctorChatHistoryData.fromJson(
                  Map<String, dynamic>.from(v)));
            } catch (_) {}
          }
        }
      }
    }
  }

  /// Handles list body, `{ success, data }`, or alternate keys from the API.
  factory DoctorChatHistoryModel.fromResponse(dynamic response) {
    if (response == null) {
      return DoctorChatHistoryModel(success: false, data: []);
    }
    if (response is List) {
      return DoctorChatHistoryModel(
        success: true,
        data: _parseDataList(response),
      );
    }
    if (response is Map) {
      final m = Map<String, dynamic>.from(response);
      if (m['data'] is List) {
        return DoctorChatHistoryModel(
          success: m['success'] == true || m['success'] == null,
          data: _parseDataList(m['data'] as List),
        );
      }
      for (final key in ['conversations', 'items', 'threads', 'chats']) {
        if (m[key] is List) {
          return DoctorChatHistoryModel(
            success: m['success'] == true || m['success'] == null,
            data: _parseDataList(m[key] as List),
          );
        }
      }
      return DoctorChatHistoryModel.fromJson(m);
    }
    return DoctorChatHistoryModel(success: false, data: []);
  }

  /// Parses GET /chat/conversations for a logged-in doctor (`other` + nested `lastMessage`).
  static DoctorChatHistoryModel fromConversationsApi(dynamic response) {
    List<dynamic>? list;
    if (response is Map) {
      final m = Map<String, dynamic>.from(response);
      if (m['data'] is List) {
        list = m['data'] as List;
      }
    } else if (response is List) {
      list = response;
    }
    if (list == null) {
      return DoctorChatHistoryModel(success: false, data: []);
    }
    final out = <DoctorChatHistoryData>[];
    for (final raw in list) {
      if (raw is! Map) continue;
      final item = Map<String, dynamic>.from(raw);
      final other = item['other'];
      if (other is! Map) continue;
      final om = Map<String, dynamic>.from(other);
      if (om['role']?.toString().toUpperCase() != 'PATIENT') continue;
      final normalized = <String, dynamic>{
        'patient': om,
        'lastMessage': item['lastMessage'],
        'lastMessageDate': item['lastMessageDate'],
        'unreadCount': item['unreadCount'] ?? 0,
      };
      try {
        out.add(DoctorChatHistoryData.fromJson(normalized));
      } catch (_) {}
    }
    return DoctorChatHistoryModel(success: true, data: out);
  }

  static List<DoctorChatHistoryData> _parseDataList(List list) {
    final out = <DoctorChatHistoryData>[];
    for (final v in list) {
      if (v is! Map) continue;
      try {
        out.add(DoctorChatHistoryData.fromJson(Map<String, dynamic>.from(v)));
      } catch (_) {}
    }
    return out;
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
    patient = Patient.maybeFromJson(json);
    if (patient == null) {
      final pid = json['patientId'] ?? json['patient_id'] ?? json['userId'];
      if (pid != null) {
        patient = Patient(id: pid.toString(), fullName: null, profilePhotoUrl: null);
      }
    }
    final lm = json['lastMessage'];
    if (lm is Map) {
      final m = Map<String, dynamic>.from(lm);
      lastMessage = m['body']?.toString();
      lastMessageDate = m['sentAt']?.toString() ??
          json['lastMessageDate']?.toString() ??
          json['last_message_at']?.toString();
    } else {
      lastMessage = lm?.toString() ??
          json['last_message']?.toString() ??
          json['preview']?.toString() ??
          json['message']?.toString();
      lastMessageDate = json['lastMessageDate']?.toString() ??
          json['last_message_at']?.toString() ??
          json['updatedAt']?.toString() ??
          json['updated_at']?.toString();
    }
    final u = json['unreadCount'] ?? json['unread_count'] ?? json['unread'];
    unreadCount = u is int ? u : int.tryParse(u?.toString() ?? '') ?? 0;
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
  /// Patient / user id as returned by API (numeric or string).
  String? id;
  String? fullName;
  String? profilePhotoUrl;

  Patient({this.id, this.fullName, this.profilePhotoUrl});

  static Patient? maybeFromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? p;
    if (json['patient'] is Map) {
      p = Map<String, dynamic>.from(json['patient'] as Map);
    } else if (json['user'] is Map) {
      p = Map<String, dynamic>.from(json['user'] as Map);
    } else if (json['patientUser'] is Map) {
      p = Map<String, dynamic>.from(json['patientUser'] as Map);
    } else if (json['participant'] is Map) {
      p = Map<String, dynamic>.from(json['participant'] as Map);
    } else if (json.containsKey('fullName') ||
        json.containsKey('name') ||
        json.containsKey('id')) {
      p = json;
    }
    if (p == null) return null;
    return Patient.fromPatientMap(p);
  }

  factory Patient.fromJson(Map<String, dynamic> json) => Patient.fromPatientMap(json);

  static Patient fromPatientMap(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['_id'] ?? json['userId'] ?? json['patientId'];
    final name = json['fullName'] ??
        json['full_name'] ??
        json['name'] ??
        json['displayName'] ??
        '';
    final photo = json['profilePhotoUrl'] ??
        json['profileImage'] ??
        json['profile_image'] ??
        json['profile_image_url'] ??
        json['avatar'];
    return Patient(
      id: rawId?.toString(),
      fullName: name.toString().isEmpty ? null : name.toString(),
      profilePhotoUrl: AppUrl.getFullUrl(photo?.toString()),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['fullName'] = fullName;
    data['profilePhotoUrl'] = profilePhotoUrl;
    return data;
  }
}
