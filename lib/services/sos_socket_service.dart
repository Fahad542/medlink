import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class SosSocketService {
  SosSocketService._();

  static final SosSocketService instance = SosSocketService._();

  io.Socket? _socket;
  String? _token;
  String? _url;
  String? _lastJoinedSosKey;
  /// Last trip room joined (numeric id or UUID string — must match backend `joinTrip` / broadcasts).
  String? _lastJoinedTripIdKey;

  final StreamController<Map<String, dynamic>> _sosUpdatedController =
      StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _tripUpdatedController =
      StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _tripLocationUpdatedController =
      StreamController.broadcast();

  Stream<Map<String, dynamic>> get sosUpdatedStream =>
      _sosUpdatedController.stream;
  Stream<Map<String, dynamic>> get tripUpdatedStream =>
      _tripUpdatedController.stream;
  Stream<Map<String, dynamic>> get tripLocationUpdatedStream =>
      _tripLocationUpdatedController.stream;

  bool get isConnected => _socket?.connected == true;

  void connect({required String url, required String token}) {
    final socketUrl = url.endsWith('/sos') ? url : '$url/sos';

    if (_socket != null &&
        _url == socketUrl &&
        _token == token &&
        _socket!.connected == true) {
      return;
    }

    disconnect();
    _url = socketUrl;
    _token = token;

    final socket = io.io(
      socketUrl,
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
      debugPrint('[SosSocketService] connected');
      _emitJoinUser();
      if (_lastJoinedSosKey != null && _lastJoinedSosKey!.isNotEmpty) {
        socket.emit('joinSos', {'sosId': _idWireFromKey(_lastJoinedSosKey!)});
      }
      if (_lastJoinedTripIdKey != null) {
        socket.emit('joinTrip', {
          'tripId': _idWireFromKey(_lastJoinedTripIdKey!),
        });
      }
    });
    socket.onConnectError((dynamic e) {
      debugPrint('[SosSocketService] connect_error: $e');
    });
    socket.onDisconnect((dynamic r) {
      debugPrint('[SosSocketService] disconnect: $r');
    });

    socket.on('sos:updated', (data) {
      final m = _toMap(data);
      if (m != null) _sosUpdatedController.add(m);
    });
    socket.on('trip:updated', (data) {
      final m = _toMap(data);
      if (m != null) _tripUpdatedController.add(m);
    });
    void onDriverLoc(dynamic data) {
      final m = _toMap(data);
      if (m != null) _tripLocationUpdatedController.add(m);
    }

    socket.on('trip:locationUpdated', onDriverLoc);
    socket.on('trip:driverLocation', onDriverLoc);
    socket.on('driverLocationUpdated', onDriverLoc);

    _socket = socket;
    socket.connect();
  }

  void _emitJoinUser() {
    if (_socket == null) return;
    debugPrint('[SosSocketService] emit joinUser');
    _socket!.emit('joinUser', <String, dynamic>{});
  }

  void disconnect() {
    final s = _socket;
    _socket = null;
    if (s != null) {
      s.dispose();
      s.disconnect();
      s.close();
    }
  }

  /// Call after connect if you need an explicit re-join (e.g. token refresh).
  void joinUser() {
    _emitJoinUser();
  }

  void joinSos(Object sosId) {
    final key = sosId.toString();
    if (key.isEmpty) return;
    _lastJoinedSosKey = key;
    _socket?.emit('joinSos', {'sosId': _idWireFromKey(key)});
  }

  /// Call when patient ends emergency flow so reconnect does not rejoin old rooms.
  void clearJoinedRooms() {
    _lastJoinedSosKey = null;
    _lastJoinedTripIdKey = null;
  }

  /// Backend may expect a number (auto-id) or a string (UUID). Prefer int when parsable.
  static dynamic _idWireFromKey(String key) {
    final n = int.tryParse(key);
    return n ?? key;
  }

  void joinTrip(Object tripId) {
    final key = tripId.toString();
    if (key.isEmpty) return;
    _lastJoinedTripIdKey = key;
    _socket?.emit('joinTrip', {'tripId': _idWireFromKey(key)});
  }

  void updateTripLocation({
    required Object tripId,
    required double lat,
    required double lng,
    double? speed,
    double? heading,
  }) {
    final key = tripId.toString();
    if (key.isEmpty) return;
    _socket?.emit('updateTripLocation', {
      'tripId': _idWireFromKey(key),
      'lat': lat,
      'lng': lng,
      if (speed != null) 'speed': speed,
      if (heading != null) 'heading': heading,
    });
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
