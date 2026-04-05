import 'dart:async';
import 'package:flutter/material.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/core/constants/app_url.dart';
import 'package:medlink/views/call/call_view_model.dart';
import 'package:medlink/services/call_socket_service.dart';
import 'package:provider/provider.dart';

class IncomingCallScreen extends StatefulWidget {
  final String callerName;
  final String? callerPhoto;
  final String channelName;
  final String? token;
  final String? appId;
  final int? callerId;
  final VoidCallback onDecline;

  const IncomingCallScreen({
    super.key,
    required this.callerName,
    this.callerPhoto,
    required this.channelName,
    this.token,
    this.appId,
    this.callerId,
    required this.onDecline,
  });

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen>
    with SingleTickerProviderStateMixin {
  StreamSubscription? _callEndedSub;
  Timer? _pollTimer;
  late AnimationController _pulseController;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();

    // Pulse animation for the avatar ring
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // PRIMARY: Listen for caller cancelling via socket
    _callEndedSub =
        CallSocketService.instance.callEndedStream.listen((channel) {
      debugPrint('[IncomingCallScreen] Socket call:ended received for $channel');
      if (channel == widget.channelName) {
        _dismissScreen();
      }
    });

    // FALLBACK: Poll call status via HTTP every 3 seconds
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_isDismissing || !mounted) return;
      try {
        final status = await Provider.of<CallViewModel>(context, listen: false)
            .getCallStatus(widget.channelName);
        debugPrint('[IncomingCallScreen] Poll status: $status');
        if (status == 'ENDED' || status == 'CANCELLED' || status == 'REJECTED') {
          _dismissScreen();
        }
      } catch (e) {
        debugPrint('[IncomingCallScreen] Poll error: $e');
      }
    });

    // Notify the caller that this side is ringing
    if (widget.callerId != null) {
      CallSocketService.instance.emitRinging(
        channelName: widget.channelName,
        callerId: widget.callerId!,
      );
    }
  }

  void _dismissScreen() {
    if (_isDismissing) return;
    _isDismissing = true;
    _pollTimer?.cancel();
    if (mounted) {
      Navigator.pop(context); // Instantly dismiss
    }
  }

  @override
  void dispose() {
    _callEndedSub?.cancel();
    _pollTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF212529),
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Animated pulse rings behind avatar
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final scale = 1.0 + (_pulseController.value * 0.15);
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer pulse ring
                      Container(
                        width: 190 * scale,
                        height: 190 * scale,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary
                                .withOpacity(0.15 * (1 - _pulseController.value)),
                            width: 2,
                          ),
                        ),
                      ),
                      // Inner pulse ring
                      Container(
                        width: 170 * scale,
                        height: 170 * scale,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary
                                .withOpacity(0.25 * (1 - _pulseController.value)),
                            width: 2,
                          ),
                        ),
                      ),
                      // Avatar
                      Container(
                        width: 160,
                        height: 160,
                        padding: widget.callerPhoto == null
                            ? const EdgeInsets.all(20)
                            : null,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                          image: widget.callerPhoto != null &&
                                  widget.callerPhoto!.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(
                                      AppUrl.getFullUrl(widget.callerPhoto)),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          border: Border.all(
                              color: Colors.white.withOpacity(0.2), width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: widget.callerPhoto == null
                            ? const Icon(Icons.person,
                                size: 80, color: Colors.white)
                            : null,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                widget.callerName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Incoming Call...",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                ),
              ),
              const Spacer(),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Decline Button
                    GestureDetector(
                      onTap: () {
                        if (_isDismissing) return;
                        _isDismissing = true;
                        _callEndedSub?.cancel();
                        _pollTimer?.cancel();
                        Provider.of<CallViewModel>(context, listen: false)
                            .updateCallStatus(widget.channelName, 'REJECTED');
                        Navigator.pop(context);
                        widget.onDecline();
                      },
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.call_end,
                            color: Colors.white, size: 32),
                      ),
                    ),
                    // Accept Button
                    GestureDetector(
                      onTap: () {
                        if (_isDismissing) return;
                        _isDismissing = true;
                        _callEndedSub?.cancel();
                        _pollTimer?.cancel();
                        Provider.of<CallViewModel>(context, listen: false)
                            .updateCallStatus(widget.channelName, 'ACCEPTED');
                        Navigator.pop(context, true);
                      },
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.call,
                            color: Colors.white, size: 32),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
