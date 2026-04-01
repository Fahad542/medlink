import 'dart:async';
import 'package:flutter/material.dart';
import 'package:medlink/core/constants/app_url.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class CallSocketService extends ChangeNotifier {
  static final CallSocketService instance = CallSocketService._();
  CallSocketService._();

  io.Socket? _socket;
  bool _isConnected = false;

  final StreamController<Map<String, dynamic>> _incomingCallController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get incomingCallStream =>
      _incomingCallController.stream;

  final StreamController<String> _callEndedController =
      StreamController<String>.broadcast();
  Stream<String> get callEndedStream => _callEndedController.stream;

  bool get isConnected => _isConnected;

  void connect({required String token, required int userId}) {
    if (_socket != null && _socket!.connected) return;

    _socket = io.io(
      '${AppUrl.baseUrl}/agora',
      <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
        'extraHeaders': {'Authorization': 'Bearer $token'},
      },
    );

    _socket!.onConnect((_) {
      _isConnected = true;
      debugPrint('Call Socket Connected');
      _socket!.emit('joinUserRoom');
      notifyListeners();
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      debugPrint('Call Socket Disconnected');
      notifyListeners();
    });

    _socket!.on('call:incoming', (data) {
      debugPrint('Incoming Call Socket Event: $data');
      if (data != null) {
        _incomingCallController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('call:ended', (data) {
      debugPrint('Call Ended Socket Event: $data');
      if (data != null && data['channelName'] != null) {
        _callEndedController.add(data['channelName'].toString());
      }
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }

  @override
  void dispose() {
    _incomingCallController.close();
    _callEndedController.close();
    disconnect();
    super.dispose();
  }
}
