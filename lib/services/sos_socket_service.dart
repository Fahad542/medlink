import 'dart:async';
import 'dart:convert';

import 'package:socket_io_client/socket_io_client.dart' as io;

class SosSocketService {
  SosSocketService._();

  static final SosSocketService instance = SosSocketService._();

  io.Socket? _socket;
  String? _token;
  String? _url;

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
    if (_socket != null &&
        _url == url &&
        _token == token &&
        _socket!.connected == true) {
      return;
    }

    disconnect();
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

    socket.on('connect', (_) {});
    socket.on('disconnect', (_) {});
    socket.on('connect_error', (_) {});

    socket.on('sos:updated', (data) {
      final m = _toMap(data);
      if (m != null) _sosUpdatedController.add(m);
    });
    socket.on('trip:updated', (data) {
      final m = _toMap(data);
      if (m != null) _tripUpdatedController.add(m);
    });
    socket.on('trip:locationUpdated', (data) {
      final m = _toMap(data);
      if (m != null) _tripLocationUpdatedController.add(m);
    });

    _socket = socket;
    socket.connect();
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

  void joinUser() {
    _socket?.emit('joinUser', {});
  }

  void joinTrip(int tripId) {
    _socket?.emit('joinTrip', {'tripId': tripId});
  }

  void joinSos(int sosId) {
    _socket?.emit('joinSos', {'sosId': sosId});
  }

  void updateTripLocation({
    required int tripId,
    required double lat,
    required double lng,
    double? speed,
    double? heading,
  }) {
    _socket?.emit('updateTripLocation', {
      'tripId': tripId,
      'lat': lat,
      'lng': lng,
      if (speed != null) 'speed': speed,
      if (heading != null) 'heading': heading,
    });
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

