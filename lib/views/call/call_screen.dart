import 'dart:async';
import 'dart:ui';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/core/constants/app_url.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:medlink/views/call/call_view_model.dart';
import 'package:medlink/services/call_socket_service.dart';
import 'package:provider/provider.dart';

class CallScreen extends StatefulWidget {
  final String channelName;
  final String? token;
  final String? appId;
  final String recipientName;
  final String? recipientPhoto;
  final bool isCaller;
  final int? recipientId; // needed so caller can signal cancel via socket

  const CallScreen({
    super.key,
    required this.channelName,
    this.token,
    this.appId,
    required this.recipientName,
    this.recipientPhoto,
    this.isCaller = false,
    this.recipientId,
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
  bool _callEnded = false;
  bool _isRinging = false; // true when other side confirmed ringing

  StreamSubscription? _callEndedSub;
  StreamSubscription? _callRingingSub;

  @override
  void initState() {
    super.initState();
    initAgora();
    _listenForCallEnd();
    _listenForRinging();
  }

  void _listenForCallEnd() {
    _callEndedSub =
        CallSocketService.instance.callEndedStream.listen((channel) {
      if (channel == widget.channelName) {
        if (mounted) {
          _onRemoteCallEnd(context);
        }
      }
    });
  }

  void _listenForRinging() {
    if (!widget.isCaller) return; // Only the caller cares about ringing status
    _callRingingSub =
        CallSocketService.instance.callRingingStream.listen((channel) {
      if (channel == widget.channelName) {
        if (mounted) {
          setState(() {
            _isRinging = true;
          });
        }
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

  String _getCallStatusText() {
    if (_remoteUid != null) {
      return _formatDuration(_seconds);
    }
    if (widget.isCaller) {
      return _isRinging ? "Ringing..." : "Calling...";
    }
    return "Connecting...";
  }

  Future<void> initAgora() async {
    await [Permission.microphone].request();

    _engine = createAgoraRtcEngine();

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
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint("remote user $remoteUid joined");
          setState(() {
            _remoteUid = remoteUid;
            _isRinging = false; // Clear ringing once connected
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
    _callEndedSub?.cancel();
    _callRingingSub?.cancel();
    if (!_callEnded) {
      _engine.leaveChannel();
    }
    _engine.release();
    super.dispose();
  }

  void _onCallEnd(BuildContext context) {
    if (_callEnded) return;
    _callEnded = true;
    _callEndedSub?.cancel();
    _callRingingSub?.cancel();
    _timer?.cancel();
    _engine.leaveChannel();

    if (mounted) {
      Provider.of<CallViewModel>(context, listen: false)
          .updateCallStatus(widget.channelName, 'ENDED');

      // If caller hangs up before pickup, also emit via socket for instant dismissal
      if (widget.isCaller && _remoteUid == null && widget.recipientId != null) {
        CallSocketService.instance.emitCancelCall(
          channelName: widget.channelName,
          recipientId: widget.recipientId!,
        );
      }

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
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF212529),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 60),

              // Avatar
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

              // Name
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

              // Status: Calling... → Ringing... → 00:00
              Text(
                _getCallStatusText(),
                style: TextStyle(
                  color: _isRinging && _remoteUid == null
                      ? Colors.greenAccent
                      : AppColors.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.0,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),

              const Spacer(),

              // Action Buttons
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
