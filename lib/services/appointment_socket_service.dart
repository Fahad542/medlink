import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

/// `/appointments` namespace — real-time list sync for patient + doctor.
class AppointmentSocketService {
  AppointmentSocketService._();
  static final AppointmentSocketService instance = AppointmentSocketService._();

  io.Socket? _socket;
  String? _url;
  String? _token;
  String? _joinUserId;
  String? _joinRole;

  final StreamController<Map<String, dynamic>> _appointmentUpdateController =
      StreamController.broadcast();

  /// Batches bursty server events into a single UI refresh.
  Timer? _dispatchDebounce;

  Stream<Map<String, dynamic>> get appointmentUpdateStream =>
      _appointmentUpdateController.stream;

  void _emitJoinUser() {
    final s = _socket;
    if (s == null || !s.connected) return;
    final payload = <String, dynamic>{};
    if (_joinUserId != null && _joinUserId!.isNotEmpty) {
      payload['userId'] = _joinUserId;
    }
    if (_joinRole != null && _joinRole!.isNotEmpty) {
      payload['role'] = _joinRole;
    }
    s.emit('joinUser', payload);
    if (kDebugMode) {
      debugPrint('[AppointmentSocket] joinUser $payload');
    }
  }

  void _flushDispatch(dynamic data) {
    Map<String, dynamic> m;
    if (data is Map) {
      m = Map<String, dynamic>.from(data);
    } else if (data is String && data.isNotEmpty) {
      m = {'appointmentId': data};
    } else if (data != null) {
      m = {'payload': data.toString()};
    } else {
      m = {};
    }
    if (kDebugMode) {
      debugPrint('[AppointmentSocket] event -> UI refresh: $m');
    }
    _appointmentUpdateController.add(m);
  }

  void _dispatch(dynamic data) {
    _dispatchDebounce?.cancel();
    _dispatchDebounce = Timer(const Duration(milliseconds: 400), () {
      _flushDispatch(data);
    });
  }

  void _registerEventHandlers() {
    if (_socket == null) return;

    const events = <String>[
      'appointment:created',
      'appointment:updated',
      'appointment:cancelled',
      'appointment:canceled',
      'appointment:deleted',
      'appointment:removed',
      'appointment:statusChanged',
      'appointments:sync',
      'appointments:change',
    ];

    for (final name in events) {
      _socket!.on(name, _dispatch);
    }
  }

  /// [userId] and [role] are sent with `joinUser` so the server can map the
  /// connection to the right user (string id, e.g. UUID / numeric string).
  void connect({
    required String url,
    required String token,
    String? userId,
    String? role,
  }) {
    if (_socket != null &&
        _url == url &&
        _token == token &&
        _joinUserId == userId &&
        _joinRole == role &&
        _socket!.connected) {
      return;
    }

    disconnect();
    _url = url;
    _token = token;
    _joinUserId = userId;
    _joinRole = role;

    final fullUrl =
        url.endsWith('/') ? '${url}appointments' : '$url/appointments';

    _socket = io.io(
      fullUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(20)
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(10000)
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .setAuth({
            'authorization': 'Bearer $token',
            'token': token,
          })
          .setQuery({'token': token})
          .build(),
    );

    _socket!.on('connect', (_) {
      if (kDebugMode) {
        debugPrint('[AppointmentSocket] connected $fullUrl');
      }
      _emitJoinUser();
    });

    _socket!.on('reconnect', (_) {
      if (kDebugMode) {
        debugPrint('[AppointmentSocket] reconnected');
      }
      _emitJoinUser();
    });

    _socket!.onConnectError((dynamic err) {
      if (kDebugMode) {
        debugPrint('[AppointmentSocket] connect_error: $err');
      }
    });

    _socket!.onDisconnect((dynamic reason) {
      if (kDebugMode) {
        debugPrint('[AppointmentSocket] disconnect: $reason');
      }
    });

    _registerEventHandlers();
    _socket!.connect();
  }

  void disconnect() {
    _dispatchDebounce?.cancel();
    _dispatchDebounce = null;
    _socket?.dispose();
    _socket = null;
  }

  void _emitIfConnected(String event, Map<String, dynamic> payload) {
    final s = _socket;
    if (s == null || !s.connected) {
      if (kDebugMode) {
        debugPrint(
          '[AppointmentSocket] skip emit $event (not connected)',
        );
      }
      return;
    }
    s.emit(event, payload);
  }

  /// After payment / booking is confirmed — server can fan out to the doctor.
  void emitAfterBookingCreated({
    required String appointmentId,
    required String doctorId,
    String? patientId,
  }) {
    final idNum = int.tryParse(appointmentId.trim());
    final docNum = int.tryParse(doctorId.trim());
    final payload = <String, dynamic>{
      'appointmentId': idNum ?? appointmentId,
      'doctorId': docNum ?? doctorId,
      if (idNum != null) 'id': idNum,
      if (patientId != null && patientId.isNotEmpty) 'patientId': patientId,
      'status': 'pending',
    };
    _emitIfConnected('appointment:created', payload);
    _emitIfConnected('appointment:updated', payload);
  }

  /// After local cancel API succeeds.
  void emitAfterCancellation(String appointmentId) {
    final idNum = int.tryParse(appointmentId.trim());
    final payload = <String, dynamic>{
      'appointmentId': idNum ?? appointmentId,
      if (idNum != null) 'id': idNum,
      'status': 'cancelled',
    };
    _emitIfConnected('appointment:cancelled', payload);
    _emitIfConnected('appointment:canceled', payload);
    _emitIfConnected('appointment:updated', payload);
  }
}
