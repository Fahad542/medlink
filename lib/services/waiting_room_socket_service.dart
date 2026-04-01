import 'dart:async';
import 'package:flutter/material.dart';
import 'package:medlink/core/constants/app_url.dart';
import 'package:medlink/data/network/api_services.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class WaitingRoomSocketService extends ChangeNotifier {
  static final WaitingRoomSocketService instance = WaitingRoomSocketService._();
  WaitingRoomSocketService._();

  io.Socket? _socket;
  bool _isConnected = false;
  String? _currentAppointmentId;

  final StreamController<String> _callStatusController = StreamController<String>.broadcast();
  Stream<String> get callStatusStream => _callStatusController.stream;

  bool get isConnected => _isConnected;

  void connect({required String token}) {
    if (_socket != null && _socket!.connected) return;

    _socket = io.io(
      '${AppUrl.baseUrl}/chat', // Using chat namespace as it also handles appointment rooms
      <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
        'extraHeaders': {'Authorization': 'Bearer $token'},
      },
    );

    _socket!.onConnect((_) {
      _isConnected = true;
      debugPrint('WaitingRoom Socket Connected');
      if (_currentAppointmentId != null) {
        joinAppointmentRoom(_currentAppointmentId!);
      }
      notifyListeners();
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      debugPrint('WaitingRoom Socket Disconnected');
      notifyListeners();
    });

    // Listen for call status updates
    // Note: The backend needs to emit this event. 
    // In ChatGateway, we can add a method to emit call status.
    _socket!.on('call:statusUpdate', (data) {
      debugPrint('Call Status Update: $data');
      if (data is Map && data['status'] != null) {
        _callStatusController.add(data['status']);
      }
    });
  }

  void joinAppointmentRoom(String appointmentId) {
    _currentAppointmentId = appointmentId;
    if (_socket != null && _socket!.connected) {
      _socket!.emit('joinRoom', {'appointmentId': int.tryParse(appointmentId) ?? appointmentId});
      debugPrint('Joined Appointment Room: $appointmentId');
    }
  }

  void leaveAppointmentRoom(String appointmentId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('leaveRoom', {'appointmentId': int.tryParse(appointmentId) ?? appointmentId});
      debugPrint('Left Appointment Room: $appointmentId');
    }
    if (_currentAppointmentId == appointmentId) {
      _currentAppointmentId = null;
    }
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    _currentAppointmentId = null;
  }

  @override
  void dispose() {
    _callStatusController.close();
    disconnect();
    super.dispose();
  }
}
