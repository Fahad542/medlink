import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/core/constants/app_url.dart';
import 'package:medlink/views/Ambulance/profile/ambulance_profile_view_model.dart';
import 'package:medlink/views/Ambulance/profile/ambulance_edit_profile_view.dart';
import 'package:medlink/widgets/logout_confirmation_dialog.dart';
import 'package:medlink/widgets/delete_account_sheet.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:medlink/widgets/custom_network_image.dart';
import 'package:medlink/views/Ambulance/profile/ambulance_reviews_view.dart';

class AmbulanceProfileView extends StatelessWidget {
  const AmbulanceProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AmbulanceProfileViewModel(),
      child: Consumer<AmbulanceProfileViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return Scaffold(
              backgroundColor: const Color(0xFFF8FAFC),
              body: _buildProfileShimmer(context),
            );
          }
          return Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            body: SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildProfileHeader(context, viewModel),
                  const SizedBox(height: 24),

                  // Menu Items
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 12, bottom: 8),
                          child: Text(
                            "ACCOUNT SETTINGS",
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF94A3B8),
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        _buildSettingsGroup([
                          _buildPremiumTile(
                            context,
                            icon: Icons.person_outline_rounded,
                            color: AppColors.primary,
                            title: "Edit Profile",
                            subtitle: "Update driver details",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      AmbulanceEditProfileView(
                                    initialFullName: viewModel.driverName == '—'
                                        ? ''
                                        : viewModel.driverName,
                                    initialEmail: viewModel.email == '—'
                                        ? ''
                                        : viewModel.email,
                                    initialPhone: viewModel.phone == '—'
                                        ? ''
                                        : viewModel.phone,
                                    initialProfilePhoto:
                                        viewModel.profilePhotoUrl,
                                    initialVehiclePlate:
                                        viewModel.licensePlate == '—'
                                            ? ''
                                            : viewModel.licensePlate,
                                    initialVehicleType:
                                        viewModel.vehicleType == '—'
                                            ? ''
                                            : viewModel.vehicleType,
                                    initialLicenseNo: viewModel.licenseNo == '—'
                                        ? ''
                                        : viewModel.licenseNo,
                                  ),
                                ),
                              ).then((result) {
                                if (result == true) {
                                  viewModel.fetchDriverProfile();
                                }
                              });
                            },
                          ),
                          _buildDivider(),
                          _buildPremiumTile(
                            context,
                            icon: Icons.language_rounded,
                            color: AppColors.primary,
                            title: "Localization",
                            subtitle: "Language & Region",
                            onTap: () => _showLanguageDialog(context),
                          ),
                        ]),

                        const SizedBox(height: 28),
                        Padding(
                          padding: const EdgeInsets.only(left: 12, bottom: 8),
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
                        _buildSettingsGroup(
                          [
                            _buildPremiumTile(
                              context,
                              icon: Icons.logout_rounded,
                              color: AppColors.primary,
                              title: "Log Out",
                              subtitle: "Sign out of your account",
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) =>
                                      LogoutConfirmationDialog(
                                    onConfirm: () => viewModel.logout(context),
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
                                  builder: (context) =>
                                      LogoutConfirmationDialog(
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
                        const SizedBox(height: 110),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(
      BuildContext context, AmbulanceProfileViewModel viewModel) {
    return SizedBox(
      height: 340,
      child: Stack(
        children: [
          Container(
            height: 300,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(30)),
              child: Stack(
                fit: StackFit.expand,
                children: [
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
                  Align(
                    alignment: Alignment.center,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 20, top: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.6),
                                  width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                )
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 45,
                              backgroundColor: Colors.white,
                              backgroundImage: NetworkImage(
                                  AppUrl.getFullUrl(viewModel.profilePhotoUrl)),
                              onBackgroundImageError: (_, __) {},
                              child: AppUrl.getFullUrl(viewModel.profilePhotoUrl)
                                      .isEmpty
                                  ? const Icon(Icons.person,
                                      size: 50, color: Colors.grey)
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  viewModel.driverName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.verified_rounded,
                                  color: Colors.lightGreenAccent, size: 20),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.1)),
                            ),
                            child: Text(
                              viewModel.licensePlate,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 0,
            child: Container(
              height: 96,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
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
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AmbulanceReviewsView(),
                        ),
                      );
                    },
                    child: _buildStatItem(
                      viewModel.rating.isNotEmpty ? viewModel.rating : "0.0",
                      "Rating",
                      Icons.star_rounded,
                      Colors.amber,
                    ),
                  ),
                  _buildVerticalDivider(),
                  _buildStatItem(
                    viewModel.totalTrips.isNotEmpty ? viewModel.totalTrips : "0",
                    "Trips",
                    Icons.directions_car_rounded,
                    AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileShimmer(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(
            height: 240,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(48)),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 60),
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Column(
              children: [
                Container(
                  width: 160,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 120,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
                2,
                (_) => Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Column(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 48,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 36,
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    )),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      String value, String label, IconData icon, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: Colors.grey[500],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.grey[200],
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required Color iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 15, color: Colors.grey[300]),
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
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: Colors.grey[300]),
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
      color: Colors.grey[100],
      indent: 56,
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Center(
          child: Text(
            "Select Language",
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            _buildLanguageOption(context, "English", "🇺🇸"),
            _buildLanguageOption(context, "Spanish", "🇪🇸"),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(BuildContext context, String name, String flag) {
    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 22)),
      title: Text(name, style: GoogleFonts.inter(fontSize: 15)),
      onTap: () => Navigator.pop(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
