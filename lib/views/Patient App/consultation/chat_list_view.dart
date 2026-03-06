import 'package:flutter/material.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medlink/widgets/custom_app_bar_widget.dart';
import 'package:medlink/views/Patient App/consultation/chat_view.dart';

import 'package:medlink/views/Patient App/consultation/chat_list_viewmodel.dart';
import 'package:medlink/views/services/session_view_model.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class ChatListView extends StatelessWidget {
  const ChatListView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ChatListViewModel(
        Provider.of<UserViewModel>(context, listen: false),
      ),
      child: Consumer<ChatListViewModel>(
        builder: (context, viewModel, child) {
          final userVM = Provider.of<UserViewModel>(context, listen: false);

          return Scaffold(
            backgroundColor: const Color(0xFFF1F5F9),
            appBar: const CustomAppBar(title: "Online Consultation"),
            body: viewModel.isLoading
                ? const Center(child: CircularProgressIndicator())
                : viewModel.appointments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              "No active consultations",
                              style: GoogleFonts.inter(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => viewModel.fetchAppointments(),
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          itemCount: viewModel.appointments.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final appointment = viewModel.appointments[index];
                            final doctor = appointment.doctor;

                            final String doctorName =
                                doctor?.name ?? "Dr. Sarah Johnson";
                            final String lastMessage =
                                appointment.reason ?? "Consultation request";
                            final String time = DateFormat('hh:mm a')
                                .format(appointment.dateTime);
                            final String? profileImage = doctor?.imageUrl;

                            return Container(
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    )
                                  ]),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 4),
                                leading: CircleAvatar(
                                  radius: 22,
                                  backgroundColor:
                                      AppColors.primary.withOpacity(0.1),
                                  backgroundImage: profileImage != null &&
                                          profileImage.isNotEmpty
                                      ? NetworkImage(profileImage)
                                      : null,
                                  child: profileImage == null ||
                                          profileImage.isEmpty
                                      ? const Icon(Icons.person,
                                          color: AppColors.primary, size: 20)
                                      : null,
                                ),
                                title: Text(doctorName,
                                    style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15)),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    lastMessage,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                        color: Colors.grey[600], fontSize: 13),
                                  ),
                                ),
                                trailing: Text(
                                  time,
                                  style: GoogleFonts.inter(
                                      color: Colors.grey[400], fontSize: 11),
                                ),
                                onTap: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => ChatView(
                                                recipientName: doctorName,
                                                profileImage: profileImage,
                                                appointmentId: appointment.id,
                                                currentUserId:
                                                    userVM.patient?.id != null
                                                        ? int.parse(
                                                            userVM.patient!.id)
                                                        : 0,
                                              )));
                                },
                              ),
                            );
                          },
                        ),
                      ),
          );
        },
      ),
    );
  }
}
