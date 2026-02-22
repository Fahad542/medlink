import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/views/Ambulance/profile/ambulance_profile_view_model.dart';
import 'package:medlink/views/Ambulance/profile/ambulance_edit_profile_view.dart';
import 'package:medlink/widgets/logout_confirmation_dialog.dart';
import 'package:provider/provider.dart';

class AmbulanceProfileView extends StatelessWidget {
  const AmbulanceProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AmbulanceProfileViewModel(),
      child: Consumer<AmbulanceProfileViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            body: SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildProfileHeader(context, viewModel),
                  // Stats Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatItem("4.8", "Rating", Icons.star_rounded, Colors.amber),
                            _buildVerticalDivider(),
                            _buildStatItem("1,240", "Trips", Icons.directions_car_rounded, AppColors.primary),
                            _buildVerticalDivider(),
                            _buildStatItem("3 Yrs", "Exp.", Icons.work_rounded, Colors.blue),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Menu Items
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _buildSettingsGroup([
                           _buildSettingsTile(
                            context,
                            icon: Icons.person_outline_rounded,
                            title: "Edit Profile",
                            iconColor: AppColors.primary,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const AmbulanceEditProfileView()),
                              );
                            },
                          ),
                          _buildDivider(),
                          _buildSettingsTile(
                            context,
                            icon: Icons.language_rounded,
                            title: "Localization",
                            iconColor: Colors.orange,
                            onTap: () => _showLanguageDialog(context),
                          ),
                           _buildDivider(),
                           _buildSettingsTile(
                            context,
                            icon: Icons.notifications_none_rounded,
                            title: "Notifications",
                            iconColor: Colors.purple,
                            onTap: () {}, // TODO
                          ),
                        ]),
                        
                   const SizedBox(height: 20),
                        
                        // Logout
                         GestureDetector(
                          onTap: () {
                             showDialog(
                               context: context,
                               builder: (context) => LogoutConfirmationDialog(
                                 onLogout: () => viewModel.logout(context),
                               ),
                             );
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14), 
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              // Border removed
                               boxShadow: [
                                BoxShadow(
                                  color: AppColors.error.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.logout_rounded, color: AppColors.error, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  "Logout",
                                  style: GoogleFonts.inter(
                                    color: AppColors.error,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                         const SizedBox(height: 30),
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

  Widget _buildProfileHeader(BuildContext context, AmbulanceProfileViewModel viewModel) {
    return SizedBox(
      height: 240,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Gradient Background with Curve
           Container(
            height: 180,
            width: double.infinity,
            padding: const EdgeInsets.only(top: 8), 
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF00695C), AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(48)),
             ),
             child: SafeArea(
               child: Column(
                 children: [
                   const SizedBox(height: 20),
                   
                   // Name and Badge
                   Row(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       // const SizedBox(width: 26),  // Removed for better centering 
                       Text(
                         viewModel.driverName,
                         style: GoogleFonts.inter(
                           color: Colors.white,
                           fontSize: 22, 
                           fontWeight: FontWeight.bold,
                         ),
                       ),
                       const SizedBox(width: 6),
                       const Icon(Icons.verified_rounded, color: Colors.lightGreenAccent, size: 20), 
                     ],
                   ),
                   const SizedBox(height: 2),
                   
                   Text(
                     viewModel.licensePlate,
                     style: GoogleFonts.inter(
                       color: Colors.white70,
                       fontSize: 13,
                       fontWeight: FontWeight.w500,
                       letterSpacing: 0.5,
                     ),
                   ),
                 ],
               ),
             ),
          ),
          
          // Profile Image
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                     BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.network(
                    "https://i.pravatar.cc/300?img=11", // Male Image
                     fit: BoxFit.cover,
                     errorBuilder: (context, error, stackTrace) =>
                        Container(color: Colors.grey[200], child: const Icon(Icons.person, size: 44, color: Colors.grey)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8), 
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 7),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12, // Increased from 11
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

  Widget _buildSettingsTile(BuildContext context, {
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
            Icon(Icons.arrow_forward_ios_rounded, size: 15, color: Colors.grey[300]),
          ],
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Select Language", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption(context, "English", "🇺🇸"),
            _buildLanguageOption(context, "Spanish", "🇪🇸"),
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
