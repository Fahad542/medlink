import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;

class AppointmentSocketService {
  AppointmentSocketService._();
  static final AppointmentSocketService instance = AppointmentSocketService._();

  io.Socket? _socket;
  String? _token;
  String? _url;

  final StreamController<Map<String, dynamic>> _appointmentUpdateController =
      StreamController.broadcast();
  
  Stream<Map<String, dynamic>> get appointmentUpdateStream =>
      _appointmentUpdateController.stream;

  void connect({required String url, required String token}) {
    // If the socket is already connected to the same URL with the same token, don't reconnect.
    if (_socket != null && _url == url && _token == token && _socket!.connected) {
      return;
    }

    disconnect();
    _url = url;
    _token = token;

    // Build the full namespace URL
    final fullUrl = url.endsWith('/') ? '${url}appointments' : '$url/appointments';

    _socket = io.io(
      fullUrl,
      <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
        'extraHeaders': {'Authorization': 'Bearer $token'},
      },
    );

    _socket!.on('connect', (_) {
      print("Appointment Socket Connected");
      _socket!.emit('joinUser', {});
    });

    _socket!.on('appointment:created', (data) {
      if (data is Map) {
        _appointmentUpdateController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('appointment:updated', (data) {
      if (data is Map) {
        _appointmentUpdateController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.connect();
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
  }
}
