import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class ChatSocketService {
  ChatSocketService._();

  static final ChatSocketService instance = ChatSocketService._();

  io.Socket? _socket;
  String? _token;
  String? _url;
  String? _joinedAppointmentId;
  String? _lastAppointmentId;
  String? _lastSosId;
  String? _lastTripId;

  final StreamController<Map<String, dynamic>> _newMessageController =
      StreamController.broadcast();

  Stream<Map<String, dynamic>> get newMessageStream =>
      _newMessageController.stream;

  bool get isConnected => _socket?.connected == true;

  void connect({required String url, required String token}) {
    // Ensure the namespace is /chat
    final chatUrl = url.endsWith('/chat') ? url : '$url/chat';

    if (_socket != null &&
        _url == chatUrl &&
        _token == token &&
        _socket!.connected == true) {
      return;
    }

    _disconnectSocket();
    _url = chatUrl;
    _token = token;

    final socket = io.io(
      chatUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .disableAutoConnect()
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .setAuth({
            'authorization': 'Bearer $token',
            'token': token,
          })
          .setQuery({'token': token})
          .build(),
    );

    socket.onConnect((_) {
      debugPrint('[ChatSocketService] 🟢 CONNECTED to $chatUrl');
      _rejoinRooms();
    });

    socket.onConnectError((dynamic err) {
      debugPrint('[ChatSocketService] 🔴 CONNECT_ERROR: $err');
    });

    socket.onDisconnect((dynamic reason) {
      debugPrint('[ChatSocketService] ⚪️ DISCONNECTED: $reason');
    });

    socket.on('error', (dynamic err) {
      debugPrint('[ChatSocketService] ❌ ERROR: $err');
    });

    socket.on('chat:newMessage', (data) {
      debugPrint('[ChatSocketService] 📥 RECEIVED NEW MESSAGE: $data');
      final m = _toMap(data);
      if (m != null) _newMessageController.add(m);
    });

    _socket = socket;
    socket.connect();
  }

  void _emitJoinUser() {
    if (_socket == null) return;
    debugPrint('[ChatSocketService] 👤 EMIT joinUser');
    _socket!.emit('joinUser', <String, dynamic>{});
  }

  void _rejoinRooms() {
    _emitJoinUser();
    if (_lastAppointmentId != null && _lastAppointmentId!.isNotEmpty) {
      _emitJoinRoom(_lastAppointmentId!);
    }
    if (_lastSosId != null && _lastSosId!.isNotEmpty) {
      _emitJoinSos(_lastSosId!);
    }
    if (_lastTripId != null && _lastTripId!.isNotEmpty) {
      _emitJoinTrip(_lastTripId!);
    }
  }

  void _emitJoinRoom(String appointmentId) {
    if (_socket == null) return;
    final id = int.tryParse(appointmentId);
    if (id != null) {
      debugPrint('[ChatSocketService] 🚪 EMITTING joinRoom for appointmentId: $id');
      _socket!.emit('joinRoom', {'appointmentId': id});
    } else {
      debugPrint('[ChatSocketService] ⚠️ Invalid appointmentId to joinRoom: $appointmentId');
    }
  }

  void _emitJoinSos(String sosId) {
    if (_socket == null) return;
    final id = int.tryParse(sosId);
    if (id != null) {
      _socket!.emit('joinSosRoom', {'sosId': id});
    }
  }

  void _emitJoinTrip(String tripId) {
    if (_socket == null) return;
    final id = int.tryParse(tripId);
    if (id != null) {
      _socket!.emit('joinTripRoom', {'tripId': id});
    }
  }

  void joinRoom(String appointmentId) {
    if (_socket == null) return;
    _joinedAppointmentId = appointmentId;
    _lastAppointmentId = appointmentId;
    _emitJoinRoom(appointmentId);
  }

  void joinSosRoom(String sosId) {
    if (_socket == null) return;
    _lastSosId = sosId;
    _emitJoinSos(sosId);
  }

  void joinTripRoom(String tripId) {
    if (_socket == null) return;
    _lastTripId = tripId;
    _emitJoinTrip(tripId);
  }

  void leaveRoom(String appointmentId) {
    if (_socket == null) return;
    final id = int.tryParse(appointmentId);
    if (id != null) {
      debugPrint('[ChatSocketService] 🚪 EMITTING leaveRoom for appointmentId: $id');
      _socket!.emit('leaveRoom', {'appointmentId': id});
    }
    if (_joinedAppointmentId == appointmentId) {
      _joinedAppointmentId = null;
    }
    if (_lastAppointmentId == appointmentId) {
      _lastAppointmentId = null;
    }
  }

  /// Stop re-joining SOS/trip rooms after reconnect (e.g. when leaving mission chat).
  void clearMissionChatContext() {
    _lastSosId = null;
    _lastTripId = null;
  }

  void sendMessage({
    required String recipientId,
    required String messageType,
    String? body,
    String? mediaUrl,
  }) {
    if (_socket == null) return;
    final rId = int.tryParse(recipientId);
    if (rId == null) {
      debugPrint('[ChatSocketService] ⚠️ Error: recipientId must be parsable as integer.');
      return;
    }

    final payload = {
      'recipientId': rId,
      'payload': {
        'messageType': messageType,
        if (body != null) 'body': body,
        if (mediaUrl != null) 'mediaUrl': mediaUrl,
      },
    };
    debugPrint('[ChatSocketService] 📤 EMITTING sendMessage: $payload');
    _socket!.emit('sendMessage', payload);
  }

  void disconnect() {
    _joinedAppointmentId = null;
    _lastAppointmentId = null;
    _lastSosId = null;
    _lastTripId = null;
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
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return null;
  }
}

