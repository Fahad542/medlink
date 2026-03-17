import 'dart:async';
import 'package:flutter/material.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/core/constants/app_url.dart';
import 'package:medlink/views/call/call_view_model.dart';
import 'package:provider/provider.dart';

class IncomingCallScreen extends StatefulWidget {
  final String callerName;
  final String? callerPhoto;
  final String channelName;
  final String? token;
  final String? appId;
  final VoidCallback onDecline;

  const IncomingCallScreen({
    super.key,
    required this.callerName,
    this.callerPhoto,
    required this.channelName,
    this.token,
    this.appId,
    required this.onDecline,
  });

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> {
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    // Poll to see if caller cancelled
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!mounted) return;
      try {
        final status = await Provider.of<CallViewModel>(context, listen: false)
            .getCallStatus(widget.channelName);
        if (status == 'ENDED' || status == 'CANCELLED') {
          if (mounted) Navigator.pop(context);
        }
      } catch (e) {
        debugPrint("Incoming poll error: $e");
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent dismissing without action
      child: Scaffold(
        backgroundColor: const Color(0xFF212529),
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
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
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: widget.callerPhoto == null
                    ? const Icon(Icons.person, size: 80, color: Colors.white)
                    : null,
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
                        // Notify backend rejected
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
                        // Notify backend accepted? Or just join.
                        // Ideally notify accepted.
                        Provider.of<CallViewModel>(context, listen: false)
                            .updateCallStatus(widget.channelName, 'ACCEPTED');
                        Navigator.pop(context, true); // Return true to accept
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
