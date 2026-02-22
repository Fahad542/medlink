import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medlink/views/Login/user_view_model.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../widgets/custom_app_bar_widget.dart';

class EmergencyContactsView extends StatelessWidget {
  const EmergencyContactsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserViewModel>(
      builder: (context, userVM, child) {
        final user = userVM.patient;
        final hasContact = user?.emergencyContactName != null && user!.emergencyContactName!.isNotEmpty;

        return Scaffold(
          backgroundColor: const Color(0xFFF9FAFB),
          appBar: const CustomAppBar(title: "Emergency Contacts"),
          body: ListView(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            children: [
              // Banner / Header Text
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.1)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Colors.red, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Your emergency contacts will be notified immediately when you trigger the SOS alert.",
                        style: GoogleFonts.inter(
                          color: Colors.red[800],
                          fontSize: 12,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Text(
                "Quick Actions",
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 10),

              // Add New Contact Button (Premium Style)
              InkWell(
                onTap: () {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Add Contact feature coming soon")));
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3), style: BorderStyle.none),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.08),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add_rounded, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "Add New Contact",
                        style: GoogleFonts.inter(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14
                        )
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Text(
                "Saved Contacts (${hasContact ? 1 : 0})",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.grey[800],
                )
              ),
              const SizedBox(height: 12),

              if (hasContact)
                _buildContactCard(user!.emergencyContactName!, user.emergencyContactPhone ?? "", "Primary")
              else
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      "No emergency contacts saved",
                      style: GoogleFonts.inter(color: Colors.grey),
                    ),
                  ),
                ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildContactCard(String name, String phone, String relation) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
         boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.06),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
      ),
      child: Row(
        children: [
          // Avatar / Icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
               color: Colors.grey[100],
               shape: BoxShape.circle,
            ),
             child: const Icon(Icons.person_rounded, color: Colors.grey, size: 20),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: const Color(0xFF1E293B)
                      )
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        relation,
                        style: GoogleFonts.inter(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                 const SizedBox(height: 2),
                 Text(
                   phone,
                   style: GoogleFonts.inter(
                     color: Colors.grey[500],
                     fontSize: 12,
                     fontWeight: FontWeight.w500
                   )
                 ),
              ],
            ),
          ),

          // Call Button
          IconButton(
            onPressed: (){},
            constraints: const BoxConstraints(), // Minimizes constraints
            padding: EdgeInsets.zero,
            icon: Container(
              padding: const EdgeInsets.all(8), // Reduced from 10
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.call_rounded, color: Colors.green, size: 18), // Reduced from 20
            ),
          )
        ],
      ),
    );
  }
}
