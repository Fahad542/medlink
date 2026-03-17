import 'package:flutter/material.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medlink/models/doctor_model.dart';
import 'package:medlink/widgets/custom_button.dart';
import 'package:provider/provider.dart';
import 'package:medlink/views/Patient%20App/appointment/appointment_viewmodel.dart';
import 'package:medlink/views/doctor/Doctor%20profile/doctor_profile_view_model.dart'; // Import local VM
import 'package:medlink/views/doctor/doctor_reviews_view.dart';
import 'package:medlink/views/Patient App/consultation/waiting_room_view.dart';
import 'package:medlink/views/Patient App/consultation/book_appointment_view.dart';

import 'package:intl/intl.dart';

class DoctorProfileView extends StatelessWidget {
  final DoctorModel doctor;

  const DoctorProfileView({super.key, required this.doctor});

  @override
  Widget build(BuildContext context) {
    print("DEBUG: BUILDING REDESIGNED DOCTOR PROFILE VIEW");
    return ChangeNotifierProvider(
      create: (context) => DoctorProfileViewModel(
          Provider.of<AppointmentViewModel>(context, listen: false)),
      child: _DoctorProfileContent(doctor: doctor),
    );
  }
}

class _DoctorProfileContent extends StatelessWidget {
  final DoctorModel doctor;

  const _DoctorProfileContent({required this.doctor});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<DoctorProfileViewModel>(context);
    final hasBooking = viewModel.hasBooking(doctor.id);

    // Total height of the fixed header area (280 bg + 60 overlap + 20 buffer)
    const double fixedHeaderHeight = 360;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Scrollable Header
            SizedBox(
              height: fixedHeaderHeight,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // Background & Decorations
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 280,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(32),
                          bottomRight: Radius.circular(32),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(32),
                          bottomRight: Radius.circular(32),
                        ),
                        child: Stack(
                          children: [
                            // Gradient
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    AppColors.primary.withOpacity(0.8)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                            ),
                            // Circle 1
                            Positioned(
                              top: -50,
                              right: -50,
                              child: Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.05),
                                ),
                              ),
                            ),
                            // Circle 2
                            Positioned(
                              bottom: -30,
                              left: -30,
                              child: Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.05),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Profile Image & Name
                  Positioned(
                    top: 60,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundImage: NetworkImage(doctor.imageUrl),
                            backgroundColor: Colors.grey[200],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          doctor.name,
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          doctor.specialty,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Stats Card (KPIs) - Adjusted positioning relative to fixed container
                  Positioned(
                    top: 280 -
                        40, // 280 (bg height) - 40 (overlap) -> Starts at 240
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          )
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatItem("Patients", "1.5K+"),
                          _buildStatItem(
                              "Experience", "${doctor.experience} Yrs"),
                          _buildStatItem("Rating", doctor.rating.toString()),
                        ],
                      ),
                    ),
                  ),

                  // AppBar Actions (Back, Chat, Video)
                  Positioned(
                    top: 50,
                    left: 20,
                    right: 20,
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.arrow_back_ios_new,
                                color: Colors.white, size: 18),
                          ),
                        ),
                        const Spacer(),
                        if (hasBooking) ...[
                          GestureDetector(
                            onTap: () {},
                            child: Container(
                              width: 36,
                              height: 36,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Image.asset("assets/Icons/chat.png",
                                  width: 16, height: 16, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => WaitingRoomView(
                                          callTargetName: doctor.name,
                                          isDoctor: false,
                                          appointmentId: viewModel
                                              .getAppointmentId(doctor.id),
                                        )),
                              );
                            },
                            child: Container(
                              width: 36,
                              height: 36,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Image.asset("assets/Icons/video.png",
                                  width: 20, height: 20, color: Colors.white),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // About Section
                  Text("About", style: _sectionTitleStyle),
                  const SizedBox(height: 8),
                  Text(
                    doctor.about,
                    style:
                        GoogleFonts.inter(color: Colors.grey[600], height: 1.5),
                  ),
                  const SizedBox(height: 24),

                  // Details (Hospital & Fee)
                  Row(
                    children: [
                      Expanded(
                          child: _buildInfoCard(Icons.local_hospital_rounded,
                              "Hospital", doctor.hospital, AppColors.primary)),
                      const SizedBox(width: 16),
                      Expanded(
                          child: _buildInfoCard(
                              Icons.attach_money_rounded,
                              "Consultation",
                              "KES ${doctor.consultationFee}",
                              AppColors.primary)),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Ratings & Reviews Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Ratings & Reviews", style: _sectionTitleStyle),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    DoctorReviewsView(doctor: doctor)),
                          );
                        },
                        child: const Text("See All"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildReviewItem("John Doe", 4.5,
                      "Great experience, very professional.", "2 days ago"),

                  const SizedBox(height: 12),

                  const SizedBox(height: 100), // Spacing for bottom button
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5))
            ]),
        child: SafeArea(
          // Ensure button is safe from bottom gestures
          child: SizedBox(
            width: double.infinity,
            child: CustomButton(
                text: "Book Appointment",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => BookAppointmentView(doctor: doctor)),
                  );
                }),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.grey[500],
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(
      IconData icon, String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(title,
              style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 12)),
          const SizedBox(height: 4),
          Text(value,
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: const Color(0xFF1E293B)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildReviewItem(
      String name, double rating, String comment, String date) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12), // Reduced padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16), // Slightly less rounded
        boxShadow: [
          BoxShadow(
            color: const Color(0xff1D1617).withOpacity(0.04),
            offset: const Offset(0, 3),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32, // Smaller avatar
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      name[0],
                      style: GoogleFonts.inter(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: const Color(0xFF1E293B)),
                      ),
                      Text(
                        date,
                        style: GoogleFonts.inter(
                            color: Colors.grey[500], fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 14, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      rating.toString(),
                      style: GoogleFonts.inter(
                          color: const Color(0xFF1E293B),
                          fontWeight: FontWeight.bold,
                          fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            comment,
            style: GoogleFonts.inter(
                color: const Color(0xFF64748B), height: 1.4, fontSize: 12.5),
          ),
        ],
      ),
    );
  }

  TextStyle get _sectionTitleStyle => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      );

  TextStyle get _subTitleStyle => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      );
}
