import 'package:flutter/material.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medlink/widgets/custom_app_bar_widget.dart';
import 'package:medlink/views/Patient App/consultation/chat_view.dart';

class ChatListView extends StatelessWidget {
  const ChatListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: const CustomAppBar(title: "Online Consultation"),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: 3,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          // Dummy data for now, matching previous hardcoded values
          final String doctorName = index == 0 ? "Dr. Sarah Johnson" : (index == 1 ? "Dr. Mark Smith" : "Medlink Support");
          final String lastMessage = index == 0 ? "Hello, how is the medication?" : (index == 1 ? "Your report is ready." : "How can we help?");
          final String time = index == 0 ? "10:30 AM" : (index == 1 ? "Yesterday" : "2 days ago");
          final String? profileImage = index == 0 
              ? "https://randomuser.me/api/portraits/women/68.jpg" 
              : (index == 1 ? "https://randomuser.me/api/portraits/men/32.jpg" : null);

          return Container(
             decoration: BoxDecoration(
               color: Colors.white,
               borderRadius: BorderRadius.circular(16),
               boxShadow: [
                 BoxShadow(
                   color: Colors.black.withOpacity(0.04), // Lighter shadow
                   blurRadius: 8, // Reduced blur
                   offset: const Offset(0, 2), // Reduced offset
                 )
               ]
             ),
             child: ListTile(
               contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), // Compact padding
               leading: CircleAvatar(
                 radius: 22, // Slightly smaller
                 backgroundColor: AppColors.primary.withOpacity(0.1),
                 backgroundImage: profileImage != null ? NetworkImage(profileImage) : null,
                 child: profileImage == null
                     ? const Icon(Icons.person, color: AppColors.primary, size: 20)
                     : null,
               ),
               title: Text(
                 doctorName, 
                 style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15) // Reduced font size and weight
               ),
               subtitle: Padding(
                 padding: const EdgeInsets.only(top: 2),
                 child: Text(
                   lastMessage,
                   maxLines: 1,
                   overflow: TextOverflow.ellipsis,
                   style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 13), // Reduced subtitle font
                 ),
               ),
               trailing: Text(
                 time,
                 style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 11), // Reduced time font
               ),
               onTap: () {
                 Navigator.push(
                   context, 
                   MaterialPageRoute(builder: (_) => ChatView(
                     recipientName: doctorName,
                     profileImage: profileImage,
                   ))
                 );
               },
             ),
          );
        },
      ),
    );
  }
}
