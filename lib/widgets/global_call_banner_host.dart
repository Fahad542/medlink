import 'dart:async';

import 'package:flutter/material.dart';
import 'package:medlink/services/call_socket_service.dart';
import 'package:medlink/views/call/call_screen.dart';
import 'package:medlink/views/services/session_view_model.dart';
import 'package:provider/provider.dart';

/// App-level incoming call banner shown above all routed screens.
class GlobalCallBannerHost extends StatefulWidget {
  const GlobalCallBannerHost({super.key, required this.child});

  final Widget child;

  @override
  State<GlobalCallBannerHost> createState() => _GlobalCallBannerHostState();
}

class _GlobalCallBannerHostState extends State<GlobalCallBannerHost> {
  StreamSubscription? _incomingCallSub;
  StreamSubscription? _callEndedSub;
  Map<String, dynamic>? _pendingIncomingCall;
  String? _connectedToken;
  int? _connectedUserId;

  @override
  void initState() {
    super.initState();
    final callSocket = CallSocketService.instance;
    _incomingCallSub = callSocket.incomingCallStream.listen((data) {
      if (!mounted) return;
      setState(() => _pendingIncomingCall = Map<String, dynamic>.from(data));
    });
    _callEndedSub = callSocket.callEndedStream.listen((channel) {
      final pending = _pendingIncomingCall;
      if (pending == null) return;
      if (pending['channelName']?.toString() == channel && mounted) {
        setState(() => _pendingIncomingCall = null);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userVM = Provider.of<UserViewModel>(context);
    final token = userVM.accessToken ?? '';
    final userId = userVM.loginSession?.data?.user?.id ??
        int.tryParse(userVM.patient?.id ?? '') ??
        int.tryParse(userVM.doctor?.id ?? '') ??
        int.tryParse(userVM.driver?.id ?? '');
    if (token.isEmpty || userId == null) return;
    if (_connectedToken == token && _connectedUserId == userId) return;

    _connectedToken = token;
    _connectedUserId = userId;
    CallSocketService.instance.connect(token: token, userId: userId);
  }

  @override
  void dispose() {
    _incomingCallSub?.cancel();
    _callEndedSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pending = _pendingIncomingCall;
    return Stack(
      children: [
        widget.child,
        if (pending != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            right: 12,
            child: _buildIncomingCallBanner(pending),
          ),
      ],
    );
  }

  Widget _buildIncomingCallBanner(Map<String, dynamic> data) {
    final callerId = data['callerId'] is int
        ? data['callerId'] as int
        : int.tryParse(data['callerId']?.toString() ?? '');
    final callerName = data['callerName']?.toString() ?? 'Incoming call';
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.videocam_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$callerName is calling — Join video call',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
            TextButton(
              onPressed: () async {
                final payload = _pendingIncomingCall;
                if (payload == null) return;
                setState(() => _pendingIncomingCall = null);
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CallScreen(
                      channelName: payload['channelName'],
                      token: payload['token'],
                      appId: payload['appId'],
                      recipientName: payload['callerName'] ?? 'Caller',
                      recipientPhoto: payload['callerPhoto'],
                      isCaller: false,
                      recipientId: callerId,
                    ),
                  ),
                );
              },
              child: const Text('Join'),
            ),
            IconButton(
              onPressed: () => setState(() => _pendingIncomingCall = null),
              icon: const Icon(Icons.close, color: Colors.white70, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
