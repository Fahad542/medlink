import 'dart:convert';

/// Numeric user id from JWT payload (`sub`, `id`, or `userId`).
int? readAuthUserIdFromJwt(String? token) {
  if (token == null || token.isEmpty) return null;
  final parts = token.split('.');
  if (parts.length < 2) return null;
  try {
    final normalized = base64Url.normalize(parts[1]);
    final payload =
        jsonDecode(utf8.decode(base64Url.decode(normalized)))
            as Map<String, dynamic>;
    final raw = payload['sub'] ?? payload['id'] ?? payload['userId'];
    if (raw is int) return raw;
    return int.tryParse(raw?.toString() ?? '');
  } catch (_) {
    return null;
  }
}
