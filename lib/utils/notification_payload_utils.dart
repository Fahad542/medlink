/// Whether a raw API notification row counts as read.
bool notificationRowIsRead(Map<String, dynamic> m) {
  return m['isRead'] == true ||
      m['read'] == true ||
      m['is_read'] == true ||
      m['seen'] == true;
}

/// Unread badge: prefer counting rows in [data.notifications] where not read.
/// Falls back to [data.unreadCount] when the list is missing.
int unreadCountFromNotificationsPayload(Map<String, dynamic> data) {
  final rawList = data['notifications'];
  if (rawList is List) {
    var n = 0;
    for (final e in rawList) {
      if (e is! Map) continue;
      final m = Map<String, dynamic>.from(Map<dynamic, dynamic>.from(e));
      if (!notificationRowIsRead(m)) n++;
    }
    return n;
  }
  final u = data['unreadCount'];
  return u is int ? u : int.tryParse(u?.toString() ?? '') ?? 0;
}
