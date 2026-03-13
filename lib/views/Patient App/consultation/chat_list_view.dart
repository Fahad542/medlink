import 'package:flutter/material.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medlink/widgets/no_data_widget.dart';
import 'package:medlink/widgets/chat_list_shimmer.dart';
import 'package:medlink/widgets/custom_app_bar_widget.dart';
import 'package:medlink/views/Patient App/consultation/chat_view.dart';
import 'package:medlink/widgets/custom_network_image.dart';

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
                ? const ChatListShimmer(itemCount: 5)
                : viewModel.chatHistory.isEmpty
                    ? const NoDataWidget(
                        title: "No Consultations",
                        subTitle: "You have no active consultations right now.",
                      )
                    : RefreshIndicator(
                        onRefresh: () => viewModel.fetchChatHistory(),
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          itemCount: viewModel.chatHistory.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final chat = viewModel.chatHistory[index];
                            final doctor = chat.doctor;

                            final String doctorName = doctor.fullName;
                            final String lastMessage = chat.lastMessage;
                            final String time = DateFormat('hh:mm a')
                                .format(chat.lastMessageDate);
                            final String? profileImage = doctor.profilePhotoUrl;

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
                                leading: CustomNetworkImage(
                                  imageUrl: profileImage,
                                  width: 44,
                                  height: 44,
                                  shape: BoxShape.circle,
                                  placeholderName: doctorName,
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
                                                doctorId: doctor.id.toString(),
                                                patientId: userVM.patient?.id ?? '',
                                                appointmentId: chat.id,
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
