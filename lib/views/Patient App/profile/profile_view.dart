import 'dart:io';
import 'package:flutter/material.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:medlink/views/services/session_view_model.dart';
import 'package:medlink/views/Patient App/profile/personal_info_view.dart';
import 'package:medlink/views/Patient App/profile/emergency_contacts_view.dart';
import 'package:medlink/data/network/api_services.dart';
import 'package:medlink/models/user_model.dart';

import 'package:medlink/widgets/logout_confirmation_dialog.dart';
import 'package:medlink/widgets/delete_account_sheet.dart';
import 'package:medlink/views/Login/login_view.dart';
import 'package:provider/provider.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  @override
  void initState() {
    super.initState();
    // Fetch profile as soon as tab opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchLatestProfile();
    });
  }

  Future<void> _fetchLatestProfile() async {
    final userVM = Provider.of<UserViewModel>(context, listen: false);
    if (userVM.role == 'patient') {
      try {
        final apiServices = ApiServices();
        final response = await apiServices.getPatientProfile();
        if (response != null && response['success'] == true) {
          final updatedUser = UserModel.fromJson(response['data']);
          userVM.updatePatient(updatedUser);
        }
      } catch (e) {
        print("Error auto-fetching profile: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userVM = Provider.of<UserViewModel>(context);
    final user = userVM.patient;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F7), // Light Gray background
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          children: [
            // 1. Premium Header (Standard Widget)
            _buildHeader(user),

            // 2. Overlapping Content & Settings
            Transform.translate(
              offset: const Offset(0, -52),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Vital Stats Row
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16), // Reduced padding
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                            20), // Slightly smaller radius
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _StatItem(
                              label: "Age",
                              value: "${user?.age ?? '-'}",
                              unit: "yrs"),
                          _VerticalDivider(),
                          _StatItem(
                              label: "Blood",
                              value: "${user?.bloodGroup ?? '-'}",
                              unit: "Type"),
                          _VerticalDivider(),
                          _StatItem(
                              label: "Weight",
                              value: "${user?.weight ?? '-'}",
                              unit: "kg"),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24), // Reduced spacing

                    // Grouped Settings
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                              left: 12, bottom: 8), // Reduced bottom
                          child: Text(
                            "ACCOUNT SETTINGS",
                            style: GoogleFonts.inter(
                              fontSize: 11, // Smaller title
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF94A3B8),
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(20), // Smaller radius
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildPremiumTile(
                                context,
                                icon: Icons.person_outline_rounded,
                                color: AppColors.primary,
                                title: "Personal Info",
                                subtitle: "Details & Password",
                                onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const PersonalInformationView())),
                              ),
                              _buildDivider(),
                              _buildPremiumTile(
                                context,
                                icon: Icons.contact_phone_outlined,
                                color: AppColors.primary,
                                title: "Emergency Contacts",
                                subtitle: "SOS & Family",
                                onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const EmergencyContactsView())),
                              ),
                              _buildDivider(),
                              _buildPremiumTile(
                                context,
                                icon: Icons.language_rounded,
                                color: AppColors.primary,
                                title: "Localization",
                                subtitle: "Language & Region",
                                onTap: () {},
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30), // Reduced spacing
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "ACCOUNT ACTIONS",
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF94A3B8),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildPremiumTile(
                            context,
                            icon: Icons.logout_rounded,
                            color: AppColors.primary,
                            title: "Log Out",
                            subtitle: "Sign out of your account",
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => LogoutConfirmationDialog(
                                  onConfirm: () {
                                    userVM.logout();
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const LoginView()),
                                      (route) => false,
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                          _buildDivider(),
                          _buildPremiumTile(
                            context,
                            icon: Icons.person_remove_rounded,
                            color: AppColors.primary,
                            title: "Delete Account",
                            subtitle: "Permanently remove account",
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => LogoutConfirmationDialog(
                                  title: "Delete Account",
                                  message:
                                      "Are you sure you want to delete your account?",
                                  confirmText: "Delete",
                                  confirmColor: AppColors.primary,
                                  onConfirm: () {
                                    Navigator.pop(context);
                                    DeleteAccountSheet.show(context);
                                  },
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(dynamic user) {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Gradient Background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primary],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            // Decorative Patterns
            Positioned(
              top: -100,
              right: -50,
              child: CircleAvatar(
                radius: 130,
                backgroundColor: Colors.white.withOpacity(0.08),
              ),
            ),
            Positioned(
              bottom: -50,
              left: -50,
              child: CircleAvatar(
                radius: 100,
                backgroundColor: Colors.white.withOpacity(0.05),
              ),
            ),

            // Profile Content
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8, top: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Profile Image
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withOpacity(0.6), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 42,
                        backgroundColor: Colors.white,
                        backgroundImage: (user?.profileImage != null &&
                                user!.profileImage!.isNotEmpty)
                            ? (user!.profileImage!.startsWith('http')
                                ? NetworkImage(user.profileImage!)
                                : FileImage(File(user.profileImage!))
                                    as ImageProvider)
                            : null,
                        child: (user?.profileImage == null ||
                                user!.profileImage!.isEmpty)
                            ? const Icon(Icons.person,
                                size: 50, color: Colors.grey)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      user?.name ?? "Guest User",
                      style: GoogleFonts.inter(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 4), // Reduced padding
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Text(
                        (user?.email != null && user!.email!.isNotEmpty)
                            ? user!.email!
                            : (user?.phoneNumber ?? "No Email/Phone"),
                        style: GoogleFonts.inter(
                          fontSize: 13, // Reduced font size
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumTile(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 12), // Reduced padding
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8), // Reduced padding
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20), // Reduced icon size
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 15, // Reduced font size
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 11, // Reduced font size
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: Colors.grey[300]), // Reduced arrow
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 60, // Adjusted ident
      endIndent: 0,
      color: Colors.grey[100],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const _StatItem(
      {required this.label, required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 11, // Reduced font size
            fontWeight: FontWeight.bold,
            color: Colors.grey[400],
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 18, // Reduced font size
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(width: 2),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                unit,
                style: GoogleFonts.inter(
                  fontSize: 11, // Reduced font size
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      width: 1,
      color: Colors.grey[200],
    );
  }
}
