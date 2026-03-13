import 'package:flutter/material.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medlink/widgets/custom_app_bar_widget.dart';
import 'package:medlink/views/Patient App/consultation/video_call_view.dart';

class WaitingRoomView extends StatefulWidget {
  final String? callTargetName;
  final bool isDoctor;
  final String? appointmentId;
  const WaitingRoomView({super.key, this.callTargetName, this.isDoctor = false, this.appointmentId});

  @override
  State<WaitingRoomView> createState() => _WaitingRoomViewState();
}

class _WaitingRoomViewState extends State<WaitingRoomView> {
  bool isMicOn = true;
  bool isCameraOn = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E), // Dark background for video feel
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
                // image: isCameraOn ? ... : null,
              ),
              child: isCameraOn 
               ? const Center(
                   child: Icon(Icons.person, color: Colors.white24, size: 80),
                 ) 
               : Center(
                   child: Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       const Icon(Icons.videocam_off_outlined, color: Colors.white38, size: 60),
                       const SizedBox(height: 12),
                       Text("Camera is off", style: GoogleFonts.inter(color: Colors.white38.withOpacity(0.5))),
                     ],
                   ),
                 ),
            ),
          ),
          
          const SizedBox(height: 30),

          // Info Text
          Text(
            "Waiting for ${widget.callTargetName ?? 'Dr. Sarah Johnson'}...",
            style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            "Your appointment starts in 5 minutes",
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
                  () => setState(() => isCameraOn = !isCameraOn),
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
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => VideoCallView(
                    isDoctor: widget.isDoctor,
                    appointmentId: widget.appointmentId,
                  )),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text("Join Now", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlBtn(IconData icon, Color color, String label, VoidCallback onTap) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(50),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color == Colors.red ? Colors.red.withOpacity(0.1) : Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.5)),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
      ],
    );
  }
}
