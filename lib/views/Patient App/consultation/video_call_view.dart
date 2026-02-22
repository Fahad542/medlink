import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/widgets/prescription_bottom_sheet.dart';
import 'package:permission_handler/permission_handler.dart';

class VideoCallView extends StatefulWidget {
  final bool isDoctor;

  const VideoCallView({super.key, this.isDoctor = false});

  @override
  State<VideoCallView> createState() => _VideoCallViewState();
}

class _VideoCallViewState extends State<VideoCallView> {
  // Agora State
  int? _remoteUid;
  bool _localUserJoined = false;
  late RtcEngine _engine;

  // Local UI State
  bool isMicOn = true;
  bool isCameraOn = true;

  // CREDENTIALS (PROVIDED)
  static const String appId = "cf69cfdd7e3e47e19486c765003b36ac";
  static const String token =
      "007eJxTYFgZE7573poEjTaHWZcdN68utz1kGSod8m0zz42F72cmHXNVYEhOM7NMTktJMU81TjUxTzW0NLEwSzY3MzUwME4yNktMLknIzmwIZGRQ1ZNmZmSAQBCfhaEktbiEgQEAczQfFw==";
  static const String channel = "test"; // Default channel name for testing

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  Future<void> _initAgora() async {
    // 1. Request Permissions
    await [Permission.microphone, Permission.camera].request();

    // 2. Create Engine
    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    // 3. Event Handling
    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint("Local user ${connection.localUid} joined");
          setState(() {
            _localUserJoined = true;
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint("Remote user $remoteUid joined");
          setState(() {
            _remoteUid = remoteUid;
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          debugPrint("Remote user $remoteUid left channel");
          setState(() {
            _remoteUid = null;
          });
        },
      ),
    );

    // 4. Enable Video
    await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _engine.enableVideo();
    await _engine.startPreview();

    // 5. Join Channel
    await _engine.joinChannel(
      token: token,
      channelId: channel,
      uid: 0,
      options: const ChannelMediaOptions(),
    );
  }

  @override
  void dispose() {
    _engine.leaveChannel();
    _engine.release();
    super.dispose();
  }

  // --- ACTIONS ---

  void _onToggleMic() {
    setState(() {
      isMicOn = !isMicOn;
    });
    _engine.muteLocalAudioStream(!isMicOn);
  }

  void _onToggleCamera() {
    setState(() {
      isCameraOn = !isCameraOn;
    });
    _engine.muteLocalVideoStream(!isCameraOn);
  }

  void _onEndCall() {
    Navigator.pop(context);
  }

  // --- UI WIDGETS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Immersive background
      body: Stack(
        children: [
          // 1. Remote Video (Main Feed)
          Center(
            child: _remoteVideo(),
          ),

          // 2. Overlay: Top Info Bar
          Positioned(
            top: 50,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.circle, color: Colors.red, size: 12), // Recording dot status
                  const SizedBox(width: 8),
                  Text("04:21", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),

          // 3. Local Video (PIP)
          Positioned(
            bottom: 140, // Above control bar
            right: 20,
            child: Container(
              width: 100,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white38),
                boxShadow: const [
                  BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4))
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: _localVideo(),
            ),
          ),

          // 4. Bottom Control Bar
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2C).withOpacity(0.9),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Mic Toggle
                  _buildControlBtn(
                    isMicOn ? Icons.mic : Icons.mic_off,
                    isMicOn ? Colors.white : Colors.black,
                    isMicOn ? Colors.grey.withOpacity(0.3) : Colors.white,
                    _onToggleMic,
                  ),

                  // End Call (Main Action)
                  InkWell(
                    onTap: _onEndCall,
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.call_end, color: Colors.white, size: 24),
                    ),
                  ),

                  // Camera Toggle
                  _buildControlBtn(
                    isCameraOn ? Icons.videocam : Icons.videocam_off,
                    isCameraOn ? Colors.white : Colors.black,
                    isCameraOn ? Colors.grey.withOpacity(0.3) : Colors.white,
                    _onToggleCamera,
                  ),

                  // Add Prescription Button (Doctor Only)
                  if (widget.isDoctor)
                    _buildControlBtn(
                      Icons.post_add_rounded,
                      Colors.white,
                      Colors.grey.withOpacity(0.3),
                      () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => const PrescriptionBottomSheet(),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Video Renderers

  Widget _localVideo() {
    if (_localUserJoined && isCameraOn) {
      return AgoraVideoView(
        controller: VideoViewController(
          rtcEngine: _engine,
          canvas: const VideoCanvas(uid: 0),
        ),
      );
    } else {
      return const Center(child: Icon(Icons.videocam_off, color: Colors.white54, size: 30));
    }
  }

  Widget _remoteVideo() {
    if (_remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: const RtcConnection(channelId: channel),
        ),
      );
    } else {
      return Container(
        color: Colors.grey[900],
        child: Center(
           child: Column(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
               const Icon(Icons.person, size: 100, color: Colors.white24),
               const SizedBox(height: 16),
               Text(
                 "Waiting for remote user...",
                 style: GoogleFonts.inter(color: Colors.white54, fontSize: 16),
               ),
             ],
           ),
        ),
      );
    }
  }

  Widget _buildControlBtn(IconData icon, Color iconColor, Color bgColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
    );
  }
}
