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
  /// Unread messages from the doctor in this thread (server + local socket merge).
  final int unreadCount;

  ChatHistoryModel({
    required this.id,
    required this.doctor,
    required this.lastMessage,
    required this.lastMessageDate,
    this.unreadCount = 0,
  });

  ChatHistoryModel copyWith({
    String? id,
    ChatHistoryDoctorModel? doctor,
    String? lastMessage,
    DateTime? lastMessageDate,
    int? unreadCount,
  }) {
    return ChatHistoryModel(
      id: id ?? this.id,
      doctor: doctor ?? this.doctor,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageDate: lastMessageDate ?? this.lastMessageDate,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  factory ChatHistoryModel.fromJson(Map<String, dynamic> json) {
    final rawLm = json['lastMessage'];
    String lastText;
    if (rawLm is Map) {
      final m = Map<String, dynamic>.from(rawLm);
      final t = m['messageType']?.toString() ?? 'TEXT';
      lastText = t == 'IMAGE'
          ? '📷 Photo'
          : (m['body']?.toString() ?? '');
    } else {
      lastText = rawLm?.toString() ?? '';
    }
    final rawDate = json['lastMessageDate'] ??
        (rawLm is Map
            ? Map<String, dynamic>.from(rawLm)['sentAt']
            : null);
    final u = json['unreadCount'] ?? json['unread_count'] ?? json['unread'];
    final uc = u is int ? u : int.tryParse(u?.toString() ?? '') ?? 0;
    return ChatHistoryModel(
      id: json['id']?.toString() ?? '',
      doctor: ChatHistoryDoctorModel.fromJson(json['doctor'] ?? {}),
      lastMessage: lastText,
      lastMessageDate: rawDate != null
          ? DateTime.tryParse(rawDate.toString())?.toLocal() ?? DateTime.now()
          : DateTime.now(),
      unreadCount: uc,
    );
  }

  /// Parses GET /chat/conversations for a logged-in patient (`other` + nested `lastMessage`).
  static List<ChatHistoryModel> fromConversationsApi(dynamic response) {
    List<dynamic>? list;
    if (response is Map && response['data'] is List) {
      list = response['data'] as List;
    } else if (response is List) {
      list = response;
    }
    if (list == null) return <ChatHistoryModel>[];

    final out = <ChatHistoryModel>[];
    for (final raw in list) {
      if (raw is! Map) continue;
      final item = Map<String, dynamic>.from(raw);
      final other = item['other'];
      if (other is! Map) continue;
      final om = Map<String, dynamic>.from(other);
      if (om['role']?.toString().toUpperCase() != 'DOCTOR') continue;

      final normalized = <String, dynamic>{
        'id': item['appointmentId'],
        'doctor': om,
        'lastMessage': item['lastMessage'],
        'lastMessageDate': item['lastMessageDate'],
        'unreadCount': item['unreadCount'] ?? 0,
      };
      try {
        out.add(ChatHistoryModel.fromJson(normalized));
      } catch (_) {}
    }
    out.sort((a, b) => b.lastMessageDate.compareTo(a.lastMessageDate));
    return out;
  }
}
