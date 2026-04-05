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

  final StreamController<String> _callRingingController =
      StreamController<String>.broadcast();
  Stream<String> get callRingingStream => _callRingingController.stream;

  bool get isConnected => _isConnected;

  void connect({required String token, required int userId}) {
    debugPrint('[CallSocketService] connect() called for userId=$userId, isConnected=$_isConnected');
    
    // If already connected, skip
    if (_socket != null && _socket!.connected) {
      debugPrint('[CallSocketService] Already connected, skipping');
      return;
    }

    // If socket exists but disconnected, clean it up first
    if (_socket != null) {
      debugPrint('[CallSocketService] Cleaning up stale socket');
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }

    debugPrint('[CallSocketService] Creating new socket to ${AppUrl.baseUrl}/agora');
    _socket = io.io(
      '${AppUrl.baseUrl}/agora',
      <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
        'forceNew': true,
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

    _socket!.on('call:ringing', (data) {
      debugPrint('Call Ringing Socket Event: $data');
      if (data != null && data['channelName'] != null) {
        _callRingingController.add(data['channelName'].toString());
      }
    });
  }

  /// Emit cancel call event via socket (instant, before Agora channel join)
  void emitCancelCall({required String channelName, required int recipientId}) {
    if (_socket != null && _socket!.connected) {
      debugPrint('Emitting call:cancel for $channelName to recipient $recipientId');
      _socket!.emit('call:cancel', {
        'channelName': channelName,
        'recipientId': recipientId,
      });
    }
  }

  /// Emit ringing confirmation back to the caller
  void emitRinging({required String channelName, required int callerId}) {
    if (_socket != null && _socket!.connected) {
      debugPrint('Emitting call:ringing for $channelName to caller $callerId');
      _socket!.emit('call:ringing', {
        'channelName': channelName,
        'callerId': callerId,
      });
    }
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
    _callRingingController.close();
    disconnect();
    super.dispose();
  }
}
