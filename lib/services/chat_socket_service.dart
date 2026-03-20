import 'dart:async';
import 'dart:convert';

import 'package:socket_io_client/socket_io_client.dart' as io;

class ChatSocketService {
  ChatSocketService._();

  static final ChatSocketService instance = ChatSocketService._();

  io.Socket? _socket;
  String? _token;
  String? _url;
  String? _joinedAppointmentId;

  final StreamController<Map<String, dynamic>> _newMessageController =
      StreamController.broadcast();

  Stream<Map<String, dynamic>> get newMessageStream =>
      _newMessageController.stream;

  bool get isConnected => _socket?.connected == true;

  void connect({required String url, required String token}) {
    if (_socket != null &&
        _url == url &&
        _token == token &&
        _socket!.connected == true) {
      return;
    }

    _disconnectSocket();
    _url = url;
    _token = token;

    final socket = io.io(
      url,
      <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
        'extraHeaders': {'Authorization': 'Bearer $token'},
      },
    );

    socket.on('chat:newMessage', (data) {
      final m = _toMap(data);
      if (m != null) _newMessageController.add(m);
    });

    _socket = socket;
    socket.connect();
  }

  void joinRoom(String appointmentId) {
    if (_socket == null) return;
    if (_joinedAppointmentId != null && _joinedAppointmentId != appointmentId) {
      leaveRoom(_joinedAppointmentId!);
    }
    _joinedAppointmentId = appointmentId;
    _socket?.emit('joinRoom', {'appointmentId': appointmentId});
  }

  void leaveRoom(String appointmentId) {
    _socket?.emit('leaveRoom', {'appointmentId': appointmentId});
    if (_joinedAppointmentId == appointmentId) {
      _joinedAppointmentId = null;
    }
  }

  void sendMessage({
    required String recipientId,
    required String messageType,
    String? body,
    String? mediaUrl,
  }) {
    _socket?.emit('sendMessage', {
      'recipientId': recipientId,
      'payload': {
        'messageType': messageType,
        if (body != null) 'body': body,
        if (mediaUrl != null) 'mediaUrl': mediaUrl,
      },
    });
  }

  void disconnect() {
    _joinedAppointmentId = null;
    _disconnectSocket();
  }

  void _disconnectSocket() {
    final s = _socket;
    _socket = null;
    if (s != null) {
      s.dispose();
      s.disconnect();
      s.close();
    }
  }

  Map<String, dynamic>? _toMap(dynamic data) {
    if (data is Map) return Map<String, dynamic>.from(data as Map);
    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return null;
  }
}

