import 'package:flutter/material.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/models/ambulance_model.dart';
import 'package:medlink/views/Patient App/consultation/chat_view.dart';

import 'package:medlink/views/services/session_view_model.dart';
import 'package:provider/provider.dart';

class AmbulanceTrackingView extends StatefulWidget {
  final AmbulanceModel ambulance;

  const AmbulanceTrackingView({super.key, required this.ambulance});

  @override
  State<AmbulanceTrackingView> createState() => _AmbulanceTrackingViewState();
}

class _AmbulanceTrackingViewState extends State<AmbulanceTrackingView>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = true;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: false);

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor:
          const Color(0xFF212529), // Dark background for status bar
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      body: Stack(
        children: [
          // 1. Premium Dark Map Background
          Listener(
            onPointerDown: (_) {
              setState(() {
                _isExpanded = false;
              });
            },
            onPointerUp: (_) {
              setState(() {
                _isExpanded = true;
              });
            },
            onPointerCancel: (_) {
              setState(() {
                _isExpanded = true;
              });
            },
            child: Container(
              color: const Color(0xFF242f3e), // Dark Blue-Grey Map
              width: double.infinity,
              height: double.infinity,
              child: Stack(
                children: [
                  // Simulated Map Grid/Streets (Subtle)
                  Positioned(
                    top: -100,
                    bottom: -100,
                    left: MediaQuery.of(context).size.width * 0.4,
                    child: Container(
                      width: 40,
                      decoration: BoxDecoration(
                        border: Border.symmetric(
                          vertical: BorderSide(
                              color: Colors.white.withOpacity(0.05), width: 2),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 200,
                    left: -50,
                    right: -50,
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        border: Border.symmetric(
                          horizontal: BorderSide(
                              color: Colors.white.withOpacity(0.05), width: 2),
                        ),
                      ),
                    ),
                  ),

                  // Route Path (Neon Glow)
                  CustomPaint(
                    size: Size.infinite,
                    painter: _RoutePainter(),
                  ),

                  // Hospital Marker
                  const Positioned(
                    top: 150,
                    left: 60,
                    child: Column(
                      children: [
                        Icon(Icons.monitor_heart_outlined,
                            size: 32, color: Color(0xFFFF5252)),
                        SizedBox(height: 4),
                        Text(
                          "Hospital",
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Pulsing Ambulance Marker
                  Positioned(
                    top: 300,
                    left: MediaQuery.of(context).size.width * 0.4 - 20,
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            // Pulse Ring
                            Container(
                              width: 60 + (40 * _pulseAnimation.value),
                              height: 60 + (40 * _pulseAnimation.value),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary.withOpacity(
                                    0.3 * (1 - _pulseAnimation.value)),
                              ),
                            ),
                            // Core Marker
                            child!,
                          ],
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.5),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.directions_car_rounded,
                            color: Colors.white, size: 28),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Premium Bottom Sheet
          Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isExpanded = true;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 30,
                      offset: const Offset(0, -10),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Slim Handle
                      Align(
                        alignment: Alignment.center,
                        child: Container(
                          width: 36,
                          height: 4,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      // Removed SizedBox spacer

                      // ETA Header (Refined)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "ARRIVING IN",
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 11, // Reduced
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 2), // Tighter spacing
                              Text(
                                widget.ambulance.estimatedArrival,
                                style: const TextStyle(
                                  fontSize: 24, // Reduced from 32
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1E293B),
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color:
                                  const Color(0xFFECFDF5), // Very light green
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                  color:
                                      const Color(0xFF10B981).withOpacity(0.2)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.check_circle_rounded,
                                    size: 16, color: Color(0xFF10B981)),
                                SizedBox(width: 6),
                                Text(
                                  "ON TIME",
                                  style: TextStyle(
                                    color: Color(0xFF10B981), // Emerald 500
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Collapsible Content
                      AnimatedCrossFade(
                        firstChild: Column(
                          children: [
                            const SizedBox(height: 24),
                            Divider(color: Colors.grey[100], height: 1),
                            const SizedBox(height: 24),

                            // Driver & Vehicle Info (Cleaner look)
                            Row(
                              children: [
                                Container(
                                  height: 50, // Reduced from 64
                                  width: 50, // Reduced from 64
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      )
                                    ],
                                    image: const DecorationImage(
                                      image: NetworkImage(
                                          'https://img.freepik.com/free-photo/portrait-smiling-male-doctor_171337-1532.jpg'),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            widget.ambulance.driverName,
                                            style: const TextStyle(
                                              fontSize: 16, // Reduced from 18
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1E293B),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          const Icon(Icons.verified,
                                              size: 16,
                                              color: AppColors.primary)
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Paramedic • ${widget.ambulance.plateNumber}",
                                        style: TextStyle(
                                            color: Colors.grey[500],
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.star_rounded,
                                              color: Colors.amber, size: 16),
                                          const SizedBox(width: 2),
                                          const Text(
                                            "4.9",
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13),
                                          ),
                                          Text(
                                            " (112)",
                                            style: TextStyle(
                                                color: Colors.grey[400],
                                                fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Action Buttons (Modern)
                            Row(
                              children: [
                                Expanded(
                                  child: TextButton.icon(
                                    onPressed: () {
                                      final userVM = Provider.of<UserViewModel>(
                                          context,
                                          listen: false);
                                      final currentUserId =
                                          userVM.loginSession?.data?.user?.id ??
                                              0;
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                              builder: (context) => ChatView(
                                              recipientName:
                                                  widget.ambulance.driverName,
                                              appointmentId: widget.ambulance.id,
                                              doctorId: widget.ambulance.id,
                                              patientId: currentUserId.toString(),
                                            ),
                                        ),
                                      );
                                    },
                                    icon: Image.asset("assets/Icons/chat.png",
                                        width: 22, height: 22),
                                    label: const Text("Message"),
                                    style: TextButton.styleFrom(
                                      backgroundColor:
                                          const Color(0xFFF1F5F9), // Slate 100
                                      foregroundColor:
                                          const Color(0xFF475569), // Slate 600
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 18),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      _showCallDriverBottomSheet(context);
                                    },
                                    icon: const Icon(Icons.phone_rounded,
                                        size: 22),
                                    label: const Text("Call Driver"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(
                                          0xFF10B981), // Emerald 500
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 18),
                                      elevation: 0,
                                      shadowColor: const Color(0xFF10B981)
                                          .withOpacity(0.4),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        secondChild: const SizedBox(width: double.infinity),
                        crossFadeState: _isExpanded
                            ? CrossFadeState.showFirst
                            : CrossFadeState.showSecond,
                        duration: const Duration(milliseconds: 300),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCallDriverBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: const BoxDecoration(
            color: Color(0xFF212529),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
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
              // Driver Avatar with Pulse
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 3),
                  image: const DecorationImage(
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
              // Driver Name & Status
              Text(
                widget.ambulance.driverName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Calling...",
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.0,
                ),
              ),

              const Spacer(),

              // Action Buttons
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildCallActionButton(
                        Icons.mic_off_rounded, Colors.white, Colors.grey[800]!),
                    _buildCallActionButton(Icons.videocam_off_rounded,
                        Colors.white, Colors.grey[800]!),
                    _buildCallActionButton(
                        Icons.volume_up_rounded, Colors.black, Colors.white),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(bottom: 50),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
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
        );
      },
    );
  }

  Widget _buildCallActionButton(IconData icon, Color iconColor, Color bgColor) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: iconColor, size: 24),
    );
  }
}

class _RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Glow Effect
    final glowPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.5)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    // 2. Core Line
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    // Simulate a path from Hospital to Ambulance
    path.moveTo(80, 190);
    path.lineTo(80, 215); // Down to intersection
    path.lineTo(size.width * 0.4 + 20, 215); // Across
    path.lineTo(size.width * 0.4 + 20, 300); // Down to ambulance

    canvas.drawPath(path, glowPaint); // Draw glow first
    canvas.drawPath(path, paint); // Draw core line
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
