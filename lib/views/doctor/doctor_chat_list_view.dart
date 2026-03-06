import 'package:flutter/material.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medlink/widgets/custom_app_bar_widget.dart';
import 'package:medlink/views/Patient App/consultation/chat_view.dart';
// Assuming we might fetch User models later

import 'package:medlink/views/services/session_view_model.dart';
import 'package:provider/provider.dart';

class DoctorChatListView extends StatelessWidget {
  const DoctorChatListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: const CustomAppBar(title: "Patient Messages"),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          // Dummy data for Patients
          final String patientName = index == 0
              ? "John Doe"
              : (index == 1 ? "Jane Smith" : "Michael Brown");
          final String lastMessage = index == 0
              ? "Dr. Alex, is the dosage correct?"
              : (index == 1
                  ? "Thanks for turn consultation."
                  : "I have a mild fever again.");
          final String time = index == 0
              ? "10:30 AM"
              : (index == 1 ? "Yesterday" : "2 days ago");
          final bool isUnread = index == 0; // Mock unread status
          final String profileImage = index == 0
              ? "https://randomuser.me/api/portraits/men/1.jpg"
              : (index == 1
                  ? "https://randomuser.me/api/portraits/women/2.jpg"
                  : "https://randomuser.me/api/portraits/men/3.jpg");

          return Container(
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Stack(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    backgroundImage: profileImage != null
                        ? NetworkImage(profileImage)
                        : null,
                    child: profileImage == null
                        ? Text(
                            patientName.substring(0, 1),
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary),
                          )
                        : null,
                  ),
                  if (isUnread)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              title: Text(patientName,
                  style: GoogleFonts.inter(
                    fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  )),
              subtitle: Text(
                lastMessage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: isUnread ? AppColors.textPrimary : Colors.grey[600],
                  fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    time,
                    style: GoogleFonts.inter(
                      color: isUnread ? AppColors.primary : Colors.grey[400],
                      fontSize: 12,
                      fontWeight:
                          isUnread ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  if (isUnread) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(6), // Increased padding
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Text('1',
                          style: GoogleFonts.inter(
                              color: Colors.white, fontSize: 10)),
                    ),
                  ]
                ],
              ),
              onTap: () {
                final userVM =
                    Provider.of<UserViewModel>(context, listen: false);
                final currentUserId = userVM.loginSession?.data?.user?.id ?? 0;
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ChatView(
                              recipientName: patientName,
                              profileImage: profileImage,
                              appointmentId: "0", // Placeholder for dummy data
                              currentUserId: currentUserId,
                            )));
              },
            ),
          );
        },
      ),
    );
  }
}
