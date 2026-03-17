import 'dart:async';
import 'dart:ui';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/core/constants/app_url.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:medlink/views/call/call_view_model.dart';
import 'package:provider/provider.dart';

class CallScreen extends StatefulWidget {
  final String channelName;
  final String? token;
  final String? appId;
  final String recipientName;
  final String? recipientPhoto;
  final bool isCaller;

  const CallScreen({
    super.key,
    required this.channelName,
    this.token,
    this.appId,
    required this.recipientName,
    this.recipientPhoto,
    this.isCaller = false,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  int? _remoteUid;
  bool _localUserJoined = false;
  late RtcEngine _engine;
  bool _muted = false;
  bool _speaker = false;
  int _seconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    initAgora();
    // Poll status to check if rejected
    _startStatusPolling();
  }

  // Add this
  bool _callEnded = false;
  Timer? _statusTimer;

  void _startStatusPolling() {
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_localUserJoined && _remoteUid != null) {
        // Call connected, maybe stop polling or poll less frequently
        timer.cancel();
        return;
      }

      try {
        // We need to access ApiServices.
        // Since CallScreen is not inside Provider(create...), we rely on global provider or direct instance.
        // Let's use direct instance for this fix to be self-contained.
        // import 'package:medlink/data/network/api_services.dart';
        // final api = ApiServices();
        // But we need to import it.
        // Better: Use Provider.of<CallViewModel>(context, listen: false) if it is available above in the tree.
        // MainScreen provides CallViewModel, so it should be available!
        if (!mounted) return;

        final status = await Provider.of<CallViewModel>(context, listen: false)
            .getCallStatus(widget.channelName);
        if (status == 'REJECTED' || status == 'ENDED') {
          if (mounted) {
            _onRemoteCallEnd(context);
          }
        }
      } catch (e) {
        debugPrint("Status poll error: $e");
      }
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _seconds++;
        });
      }
    });
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> initAgora() async {
    // retrieve permissions
    await [Permission.microphone].request();

    // create the engine
    _engine = createAgoraRtcEngine();

    // Check if appId is provided, otherwise show error
    if (widget.appId == null) {
      debugPrint("App ID is missing!");
      return;
    }

    await _engine.initialize(RtcEngineContext(
      appId: widget.appId!,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint("local user ${connection.localUid} joined");
          setState(() {
            _localUserJoined = true;
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint("remote user $remoteUid joined");
          setState(() {
            _remoteUid = remoteUid;
          });
          _startTimer();
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          debugPrint("remote user $remoteUid left channel");
          if (mounted) {
            setState(() {
              _remoteUid = null;
            });
            // End call if remote user leaves
            _onRemoteCallEnd(context);
          }
        },
        onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          debugPrint("onLeaveChannel");
        },
      ),
    );

    await _engine.enableAudio();
    await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _engine.joinChannel(
      token: widget.token ?? "",
      channelId: widget.channelName,
      uid: 0,
      options: const ChannelMediaOptions(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (!_callEnded) {
      _engine.leaveChannel();
    }
    _engine.release();
    super.dispose();
  }

  void _onCallEnd(BuildContext context) {
    if (_callEnded) return;
    _callEnded = true;
    _engine.leaveChannel();

    // Notify backend that call ended (only if local user initiated end)
    if (mounted) {
      Provider.of<CallViewModel>(context, listen: false)
          .updateCallStatus(widget.channelName, 'ENDED');
      Navigator.pop(context);
    }
  }

  void _onRemoteCallEnd(BuildContext context) {
    if (_callEnded) return;
    _callEnded = true;
    _engine.leaveChannel();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _onToggleMute() {
    setState(() {
      _muted = !_muted;
    });
    _engine.muteLocalAudioStream(_muted);
  }

  void _onToggleSpeaker() {
    setState(() {
      _speaker = !_speaker;
    });
    _engine.setEnableSpeakerphone(_speaker);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent back button
      child: Scaffold(
        backgroundColor: const Color(0xFF212529),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Handle indicator
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 60),

              // Avatar with Pulse Effect
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 3),
                  image: widget.recipientPhoto != null &&
                          widget.recipientPhoto!.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(
                              AppUrl.getFullUrl(widget.recipientPhoto)),
                          fit: BoxFit.cover,
                        )
                      : const DecorationImage(
                          image: NetworkImage(
                              'https://img.freepik.com/free-photo/portrait-smiling-male-doctor_171337-1532.jpg'),
                          fit: BoxFit.cover,
                        ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.5),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Name & Status
              Text(
                widget.recipientName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _remoteUid != null
                    ? _formatDuration(_seconds)
                    : (widget.isCaller ? "Calling..." : "Connecting..."),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.0,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),

              const Spacer(),

              // Action Buttons Row (Mic, Video, Speaker)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildCallActionButton(
                      icon: _muted ? Icons.mic_off_rounded : Icons.mic_rounded,
                      iconColor: _muted ? Colors.black : Colors.white,
                      bgColor: _muted ? Colors.white : Colors.grey[800]!,
                      onTap: _onToggleMute,
                    ),
                    // _buildCallActionButton(
                    //   icon: Icons.videocam_off_rounded,
                    //   iconColor: Colors.white,
                    //   bgColor: Colors.grey[800]!,
                    //   onTap: () {}, // Video disabled for now
                    // ),
                    _buildCallActionButton(
                      icon: _speaker
                          ? Icons.volume_up_rounded
                          : Icons.volume_off_rounded,
                      iconColor: _speaker ? Colors.black : Colors.white,
                      bgColor: _speaker ? Colors.white : Colors.grey[800]!,
                      onTap: _onToggleSpeaker,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // End Call Button
              Padding(
                padding: const EdgeInsets.only(bottom: 50),
                child: GestureDetector(
                  onTap: () => _onCallEnd(context),
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5252),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF5252).withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.call_end_rounded,
                        color: Colors.white, size: 32),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCallActionButton({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
    );
  }
}
