import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medlink/widgets/custom_app_bar_widget.dart';
import 'package:medlink/views/Patient App/consultation/video_call_view.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:medlink/data/network/api_services.dart';
import 'package:medlink/services/waiting_room_socket_service.dart';
import 'package:medlink/views/services/session_view_model.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:medlink/utils/utils.dart';

class WaitingRoomView extends StatefulWidget {
  final String? callTargetName;
  final bool isDoctor;
  final String? appointmentId;
  const WaitingRoomView(
      {super.key,
      this.callTargetName,
      this.isDoctor = false,
      this.appointmentId});

  @override
  State<WaitingRoomView> createState() => _WaitingRoomViewState();
}

class _WaitingRoomViewState extends State<WaitingRoomView> {
  bool isMicOn = true;
  bool isCameraOn = true;
  bool _permissionsGranted = false;
  late RtcEngine _engine;
  bool _engineReady = false;
  bool _isAutoJoining = false;
  String? _joinedParticipantName;
  StreamSubscription? _statusSub;
  StreamSubscription? _joinSub;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _initSocket();
  }

  Future<void> _checkPermissions() async {
    // Check current status first
    var cameraStatus = await Permission.camera.status;
    var micStatus = await Permission.microphone.status;

    if (!cameraStatus.isGranted || !micStatus.isGranted) {
      // Request permissions if not already granted
      final status = await [Permission.camera, Permission.microphone].request();
      cameraStatus = status[Permission.camera] ?? PermissionStatus.denied;
      micStatus = status[Permission.microphone] ?? PermissionStatus.denied;
    }

    if (cameraStatus.isGranted && micStatus.isGranted) {
      setState(() {
        _permissionsGranted = true;
      });
      _initPreview();
    } else {
      // Handle denied permissions
      if (mounted) {
        if (cameraStatus.isPermanentlyDenied || micStatus.isPermanentlyDenied) {
          _showSettingsDialog();
        } else {
          Utils.toastMessage(
            context,
            "Camera and Mic permissions are required.",
            isError: true,
          );
        }
      }
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Permissions Required"),
        content: const Text(
            "This app needs camera and microphone access to make video calls. Please enable them in settings."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                openAppSettings();
              },
              child: const Text("Open Settings")),
        ],
      ),
    );
  }

  Future<void> _initPreview() async {
    try {
      if (widget.appointmentId == null) return;

      final apiService = ApiServices();
      // Fetch token just to get the App ID, we don't need the token for preview usually,
      // but 'initialize' needs AppID.
      final response =
          await apiService.getAgoraToken(widget.appointmentId!, 'publisher');

      if (response == null || response['data'] == null) {
        debugPrint("Failed to fetch App ID for preview");
        return;
      }

      final String appId = response['data']['appId'];

      _engine = createAgoraRtcEngine();
      await _engine.initialize(RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));

      // Set role to broadcaster so we can start preview
      await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      await _engine.enableVideo();
      await _engine.startPreview();

      if (mounted) {
        setState(() {
          _engineReady = true;
        });
      }
    } catch (e) {
      debugPrint("Preview error: $e");
    }
  }

  void _initSocket() {
    final userVM = Provider.of<UserViewModel>(context, listen: false);
    final token = userVM.accessToken;
    if (token == null || widget.appointmentId == null) return;

    final socketService = Provider.of<WaitingRoomSocketService>(context, listen: false);
    socketService.connect(token: token);
    socketService.joinAppointmentRoom(widget.appointmentId!);

    _statusSub = socketService.callStatusStream.listen((status) {
      debugPrint("Socket: Received call status update: $status");
      if (status == 'ACTIVE' || status == 'IN_PROGRESS') {
        _autoJoinCall();
      }
    });

    _joinSub = socketService.participantJoinedStream.listen((data) {
      debugPrint("Socket: Participant joined event: $data");
      final currentUserId = userVM.loginSession?.data?.user?.id?.toString();
      
      if (mounted && data['userId']?.toString() != currentUserId) {
        setState(() {
          if (data['status'] == 'LEFT') {
            _joinedParticipantName = null;
          } else {
            _joinedParticipantName = data['fullName'];
          }
        });
      }
    });

    // Notify backend that I am WAITING
    ApiServices().updateCallStatus(
      widget.appointmentId!, 
      'WAITING', 
      appointmentId: widget.appointmentId
    );

    // Also check current status (if Doctor already joined before we entered)
    _checkCurrentCallStatus();
  }

  Future<void> _checkCurrentCallStatus() async {
    try {
      final response = await ApiServices().getCallStatus(widget.appointmentId!);
      if (response != null && response['status'] == 'JOINED') {
         if (mounted) {
           setState(() {
             _joinedParticipantName = widget.callTargetName ?? 'Doctor';
           });
         }
      }
    } catch(e) {
      debugPrint("Error checking call status: $e");
    }
  }

  Future<void> _autoJoinCall() async {
    if (_isAutoJoining) return;
    _isAutoJoining = true;

    if (_engineReady) {
      await _engine.leaveChannel();
      await _engine.release();
      if (mounted) {
        setState(() {
          _engineReady = false;
        });
      }
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => VideoCallView(
            isDoctor: widget.isDoctor,
            appointmentId: widget.appointmentId,
            otherPartyName: widget.callTargetName,
            initialMicOn: isMicOn,
            initialCameraOn: isCameraOn,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    _joinSub?.cancel();
    if (widget.appointmentId != null) {
      WaitingRoomSocketService.instance.leaveAppointmentRoom(widget.appointmentId!);
    }
    if (_engineReady) {
      _engine.leaveChannel();
      _engine.release();
    }
    super.dispose();
  }

  void _onToggleCamera() async {
    setState(() {
      isCameraOn = !isCameraOn;
    });
    if (_engineReady) {
      if (isCameraOn) {
        await _engine.enableVideo();
        await _engine.startPreview();
      } else {
        await _engine.stopPreview();
        // await _engine.disableVideo(); // Optional, but stopPreview is enough for local
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: const CustomAppBar(title: "Waiting Room"),
      body: Column(
        children: [
          const SizedBox(height: 20),
          // Camera Preview Area
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white24, width: 1),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. The Camera Feed (Placeholder or Real)
                  if (_permissionsGranted && isCameraOn)
                    if (_engineReady)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: AgoraVideoView(
                          controller: VideoViewController(
                            rtcEngine: _engine,
                            canvas: const VideoCanvas(uid: 0),
                          ),
                        ),
                      )
                    else
                      const Center(child: CircularProgressIndicator())
                  else
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _permissionsGranted
                                ? Icons.videocam_off_outlined
                                : Icons.lock_outline,
                            color: Colors.white38,
                            size: 60,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _permissionsGranted
                                ? "Camera is off"
                                : "Camera permission needed",
                            style: GoogleFonts.inter(
                                color: Colors.white38.withOpacity(0.5)),
                          ),
                        ],
                      ),
                    ),

                  // 2. Mic Status Indicator (Overlay)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        isMicOn ? Icons.mic : Icons.mic_off,
                        color: isMicOn ? Colors.greenAccent : Colors.redAccent,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 30),

          // Info Text
          if (_joinedParticipantName != null)
             Text(
              "$_joinedParticipantName has joined the call!",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.bold),
            )
          else
            Text(
              "Waiting for ${widget.callTargetName ?? 'Doctor'}...",
              style: GoogleFonts.inter(
                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          const SizedBox(height: 8),
          // TODO: Implement Real-time status check from Backend (isUserInCall?)
          Text(
            "Ready to join?",
            style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
          ),

          const SizedBox(height: 40),

          // Controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildControlBtn(
                  isMicOn ? Icons.mic : Icons.mic_off,
                  isMicOn ? Colors.white : Colors.red,
                  "Mic",
                  () => setState(() => isMicOn = !isMicOn),
                ),
                _buildControlBtn(
                  isCameraOn ? Icons.videocam : Icons.videocam_off,
                  isCameraOn ? Colors.white : Colors.red,
                  "Camera",
                  _onToggleCamera,
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // Join Button
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: ElevatedButton(
              onPressed: _permissionsGranted
                  ? () async {
                      // Ensure local engine is cleaned up before navigating
                      if (_engineReady) {
                        await _engine.leaveChannel();
                        await _engine.release();
                        setState(() {
                          _engineReady = false;
                        });
                      }

                      if (context.mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VideoCallView(
                              isDoctor: widget.isDoctor,
                              appointmentId: widget.appointmentId,
                              otherPartyName: widget.callTargetName,
                              initialMicOn: isMicOn,
                              initialCameraOn: isCameraOn,
                            ),
                          ),
                        );
                      }
                    }
                  : null, // Disable if permissions not granted
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _permissionsGranted ? AppColors.primary : Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: Text("Join Now",
                  style: GoogleFonts.inter(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlBtn(
      IconData icon, Color color, String label, VoidCallback onTap) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(50),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color == Colors.red
                  ? Colors.red.withOpacity(0.1)
                  : Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.5)),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(label,
            style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
      ],
    );
  }
}
