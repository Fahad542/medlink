import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medlink/data/network/api_services.dart';
import 'package:medlink/services/waiting_room_socket_service.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/views/services/session_view_model.dart';
import 'package:medlink/widgets/prescription_bottom_sheet.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class VideoCallView extends StatefulWidget {
  final bool isDoctor;
  final String? appointmentId;
  /// Name of the other person in the call (e.g. doctor name for patient, patient name for doctor).
  final String? otherPartyName;
  final bool initialMicOn;
  final bool initialCameraOn;

  const VideoCallView({
    super.key,
    this.isDoctor = false,
    this.appointmentId,
    this.otherPartyName,
    this.initialMicOn = true,
    this.initialCameraOn = true,
  });

  @override
  State<VideoCallView> createState() => _VideoCallViewState();
}

class _VideoCallViewState extends State<VideoCallView> {
  // Agora State
  int? _remoteUid;
  bool _localUserJoined = false;
  late RtcEngine _engine;
  bool _isLoading = true;
  String? _error;

  // Remote State
  bool _remoteVideoMuted = false;

  // Local UI State
  late bool isMicOn;
  late bool isCameraOn;

  // Timer State
  int _seconds = 0;
  Timer? _timer;

  String? _statusMessage;

  /// Display name for the remote party (passed in + refined from socket).
  String? _remotePartyName;

  @override
  void initState() {
    super.initState();
    isMicOn = widget.initialMicOn;
    isCameraOn = widget.initialCameraOn;
    _remotePartyName = widget.otherPartyName;
    _initAgora();
    _initSocket();
  }

  void _initSocket() {
    final userVM = Provider.of<UserViewModel>(context, listen: false);
    final token = userVM.accessToken;
    if (token == null || widget.appointmentId == null) return;

    final socketService = Provider.of<WaitingRoomSocketService>(context, listen: false);
    socketService.connect(token: token);
    socketService.joinAppointmentRoom(widget.appointmentId!);

    socketService.participantJoinedStream.listen((data) {
       debugPrint("[VideoCallView] Participant event: $data");
       // Only update status message if it's the OTHER person
       final currentUserId = userVM.loginSession?.data?.user?.id?.toString();
       if (mounted && data['userId']?.toString() != currentUserId) {
         setState(() {
           if (data['status'] == 'LEFT') {
             _statusMessage = null;
           } else {
             final name = data['fullName']?.toString();
             if (name != null && name.isNotEmpty) {
               _remotePartyName = name;
             }
             _statusMessage = "${_resolvedRemoteName()} is ready!";
           }
         });
       }
    });
  }

  String _localParticipantName(UserViewModel vm) {
    final role = vm.role ?? '';
    if (role == 'patient') {
      return vm.patient?.name ??
          vm.loginSession?.data?.user?.fullName ??
          'You';
    }
    if (role == 'doctor') {
      return vm.doctor?.name ??
          vm.loginSession?.data?.user?.fullName ??
          'You';
    }
    return vm.loginSession?.data?.user?.fullName ?? 'You';
  }

  String _remoteParticipantLabel() {
    return widget.isDoctor ? 'Patient' : 'Doctor';
  }

  String _resolvedRemoteName() {
    return (_remotePartyName?.trim().isNotEmpty ?? false)
        ? _remotePartyName!
        : _remoteParticipantLabel();
  }

  void _startTimer() {
    _timer?.cancel(); // Cancel any existing timer
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _seconds++;
        });
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  String get _formattedTime {
    final minutes = (_seconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_seconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  Future<void> _initAgora() async {
    // 1. Request Permissions
    await [Permission.microphone, Permission.camera].request();

    try {
      if (widget.appointmentId == null) {
        throw Exception("Appointment ID is missing");
      }

      // 2. Fetch Token
      final apiService = ApiServices();
      final response =
          await apiService.getAgoraToken(widget.appointmentId!, 'publisher');

      if (response == null || response['data'] == null) {
        throw Exception("Failed to get token data");
      }

      final data = response['data'];
      if (data['token'] == null || data['appId'] == null) {
        throw Exception("Token or AppId missing in response");
      }

      final String token = data['token'];
      final String appId = data['appId'];

      // 3. Create Engine
      _engine = createAgoraRtcEngine();
      await _engine.initialize(RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));

      // 4. Event Handling
      _engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            debugPrint("Local user ${connection.localUid} joined");
            if (mounted) {
              setState(() {
                _localUserJoined = true;
              });
              // Notify backend that this user has joined
              if (widget.appointmentId != null) {
                ApiServices().updateCallStatus(
                  widget.appointmentId!, 
                  'JOINED', 
                  appointmentId: widget.appointmentId
                );
              }
            }
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            debugPrint("Remote user $remoteUid joined");
            if (mounted) {
              setState(() {
                _remoteUid = remoteUid;
                _remoteVideoMuted = false;
              });
              _startTimer(); // Start timer when remote user joins
            }
          },
          onUserOffline: (RtcConnection connection, int remoteUid,
              UserOfflineReasonType reason) {
            debugPrint("Remote user $remoteUid left channel");
            if (mounted) {
              setState(() {
                _remoteUid = null;
                _remoteVideoMuted = false;
              });
              _stopTimer(); // Stop timer when remote user leaves
            }
          },
          onUserMuteVideo:
              (RtcConnection connection, int remoteUid, bool muted) {
            debugPrint("Remote user $remoteUid muted video: $muted");
            if (mounted) {
              setState(() {
                _remoteVideoMuted = muted;
              });
            }
          },
        ),
      );

      // 5. Enable Video/Audio based on initial state
      await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

      // ALWAYS enable video module, even if camera is initially off.
      // If we disableVideo(), we can't receive remote video stream.
      await _engine.enableVideo();

      if (widget.initialCameraOn) {
        await _engine.startPreview();
      } else {
        // Just mute local stream, don't disable the entire video module
        // await _engine.disableVideo();
      }

      await _engine.muteLocalAudioStream(!widget.initialMicOn);
      await _engine.muteLocalVideoStream(!widget.initialCameraOn);

      // 6. Join Channel
      await _engine.joinChannel(
        token: token,
        channelId: widget.appointmentId!,
        uid: 0,
        options: const ChannelMediaOptions(),
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error init agora: $e");
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  Future<void> _dispose() async {
    _timer?.cancel();
    try {
      if (widget.appointmentId != null) {
        ApiServices().updateCallStatus(
          widget.appointmentId!, 
          'LEFT', 
          appointmentId: widget.appointmentId
        );
      }
      await _engine.leaveChannel();
      await _engine.release();
    } catch (e) {
      debugPrint("Error disposing agora: $e");
    }
  }

  // --- ACTIONS ---

  void _onToggleMic() {
    setState(() {
      isMicOn = !isMicOn;
    });
    _engine.muteLocalAudioStream(!isMicOn);
  }

  void _onToggleCamera() async {
    setState(() {
      isCameraOn = !isCameraOn;
    });

    if (isCameraOn) {
      await _engine.enableVideo();
      await _engine.startPreview();
      await _engine.muteLocalVideoStream(false);
    } else {
      await _engine.muteLocalVideoStream(true);
      await _engine.stopPreview();
    }
  }

  void _onEndCall() {
    Navigator.pop(context);
  }

  // --- UI WIDGETS ---

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            "Error: $_error",
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final userVM = Provider.of<UserViewModel>(context, listen: false);
    final localName = _localParticipantName(userVM);

    return Scaffold(
      backgroundColor: Colors.black, // Immersive background
      body: Stack(
        children: [
          // 1. Remote Video (Main Feed)
          Center(
            child: _remoteVideo(localName),
          ),

          // 2. Overlay: timer + both participants (always visible during call test)
          Positioned(
            top: 48,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.circle, color: Colors.redAccent, size: 10),
                      const SizedBox(width: 8),
                      Text(
                        _formattedTime,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _remoteUid != null ? 'Connected' : 'Connecting',
                        style: GoogleFonts.inter(
                          color: _remoteUid != null ? Colors.greenAccent : Colors.white54,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _participantLine(
                    icon: Icons.person_pin_circle_outlined,
                    role: 'You (${widget.isDoctor ? 'Doctor' : 'Patient'})',
                    name: localName,
                  ),
                  const SizedBox(height: 6),
                  _participantLine(
                    icon: Icons.person_outline,
                    role: _remoteParticipantLabel(),
                    name: _resolvedRemoteName(),
                  ),
                ],
              ),
            ),
          ),

          // 3. Remote label on main feed when video is active
          if (_remoteUid != null && !_remoteVideoMuted)
            Positioned(
              left: 16,
              right: 16,
              bottom: 210,
              child: IgnorePointer(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_remoteParticipantLabel()}: ${_resolvedRemoteName()}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

          // 4. Local Video (PIP) + label
          Positioned(
            bottom: 140,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  width: 108,
                  height: 152,
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white38),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black45,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _localVideo(),
                ),
                const SizedBox(height: 6),
                Container(
                  constraints: const BoxConstraints(maxWidth: 140),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'You: $localName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),

          // 5. Bottom Control Bar
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
                      child: const Icon(Icons.call_end,
                          color: Colors.white, size: 24),
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
                          builder: (context) => PrescriptionBottomSheet(
                            appointmentId: widget.appointmentId ?? "",
                          ),
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
      return const Center(
          child: Icon(Icons.videocam_off, color: Colors.white54, size: 30));
    }
  }

  Widget _remoteVideo(String localName) {
    if (_remoteUid != null) {
      if (_remoteVideoMuted) {
        return Container(
          color: Colors.grey[900],
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.videocam_off, size: 80, color: Colors.white24),
                const SizedBox(height: 16),
                Text(
                  "Camera is off",
                  style: GoogleFonts.inter(color: Colors.white54, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_remoteParticipantLabel()}: ${_resolvedRemoteName()}',
                  style: GoogleFonts.inter(color: Colors.white38, fontSize: 13),
                ),
              ],
            ),
          ),
        );
      }
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: RtcConnection(channelId: widget.appointmentId!),
        ),
      );
    } else {
      return Container(
        color: Colors.grey[900],
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person, size: 100, color: Colors.white24),
                const SizedBox(height: 16),
                Text(
                  _statusMessage ??
                      'Waiting for ${_resolvedRemoteName()}...',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: Colors.white54, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Text(
                  'You: $localName',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: Colors.white38, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_remoteParticipantLabel()}: ${_resolvedRemoteName()}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: AppColors.primary, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _participantLine({
    required IconData icon,
    required String role,
    required String name,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                role,
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 10),
              ),
              Text(
                name,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControlBtn(
      IconData icon, Color iconColor, Color bgColor, VoidCallback onTap) {
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
