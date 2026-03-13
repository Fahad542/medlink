import 'package:flutter/material.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medlink/widgets/custom_app_bar_widget.dart';
import 'package:medlink/views/Patient App/consultation/chat_view.dart';
// Assuming we might fetch User models later

import 'package:medlink/views/services/session_view_model.dart';
import 'package:medlink/views/doctor/doctor_chat_history_view_model.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:medlink/widgets/custom_network_image.dart';
import 'package:intl/intl.dart';

class DoctorChatListView extends StatefulWidget {
  const DoctorChatListView({super.key});

  @override
  State<DoctorChatListView> createState() => _DoctorChatListViewState();
}

class _DoctorChatListViewState extends State<DoctorChatListView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userVM = Provider.of<UserViewModel>(context, listen: false);
      final String? doctorId = userVM.loginSession?.data?.user?.id?.toString() ??
          userVM.doctor?.id;
          
      if (doctorId != null && doctorId.isNotEmpty) {
        Provider.of<DoctorChatHistoryViewModel>(context, listen: false)
            .fetchChatHistory(doctorId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DoctorChatHistoryViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF1F5F9),
          appBar: const CustomAppBar(title: "Patient Messages"),
          body: viewModel.isLoading
              ? _buildShimmerLoading()
              : viewModel.chatHistory?.data == null ||
                      viewModel.chatHistory!.data!.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: viewModel.chatHistory!.data!.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final chat = viewModel.chatHistory!.data![index];
                        final bool isUnread =
                            (chat.unreadCount ?? 0) > 0;

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
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            leading: Stack(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: AppColors.primary
                                            .withOpacity(0.1),
                                        width: 2),
                                  ),
                                  child: CustomNetworkImage(
                                    imageUrl: chat.patient?.profilePhotoUrl,
                                    placeholderName: chat.patient?.fullName,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                if (isUnread)
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white,
                                            width: 1.5),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            title: Text(chat.patient?.fullName ?? "Unknown Patient",
                                style: GoogleFonts.inter(
                                  fontWeight: isUnread
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                  fontSize: 16,
                                  color: AppColors.textPrimary,
                                )),
                            subtitle: Text(
                              chat.lastMessage ?? "No messages yet",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: isUnread
                                    ? AppColors.textPrimary
                                    : Colors.grey[600],
                                fontWeight: isUnread
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                              ),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _formatDate(chat.lastMessageDate),
                                  style: GoogleFonts.inter(
                                    color: isUnread
                                        ? AppColors.primary
                                        : Colors.grey[400],
                                    fontSize: 12,
                                    fontWeight: isUnread
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                if (isUnread) ...[
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.all(
                                        6), // Increased padding
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text('${chat.unreadCount}',
                                        style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ]
                              ],
                            ),
                            onTap: () {
                              final userVM = Provider.of<UserViewModel>(
                                  context,
                                  listen: false);
                              final currentUserId =
                                  userVM.loginSession?.data?.user?.id ?? 0;
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => ChatView(
                                            recipientName:
                                                chat.patient?.fullName ?? "",
                                            profileImage:
                                                chat.patient?.profilePhotoUrl ?? "",
                                            appointmentId:
                                                "0", // Using 0 as we don't have appointmentId in the response yet
                                            doctorId:
                                                currentUserId.toString(),
                                            patientId:
                                                chat.patient?.id.toString() ?? "",
                                          )));
                            },
                          ),
                        );
                      },
                    ),
        );
      },
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return "";
    try {
      final dateTime = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
      final difference = today.difference(messageDate).inDays;

      if (difference == 0) {
        return DateFormat.jm().format(dateTime); // e.g. 10:30 AM
      } else if (difference == 1) {
        return "Yesterday";
      } else if (difference < 7) {
        return DateFormat.EEEE().format(dateTime); // e.g. Monday
      } else {
        return DateFormat.yMd().format(dateTime); // e.g. 12/03/2026
      }
    } catch (e) {
      return "";
    }
  }

  Widget _buildShimmerLoading() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle),
              ),
            ),
            title: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                height: 16,
                width: 100,
                color: Colors.white,
              ),
            ),
            subtitle: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                height: 12,
                width: 150,
                margin: const EdgeInsets.only(top: 8),
                color: Colors.white,
              ),
            ),
            trailing: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                height: 12,
                width: 40,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.message_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "No messages yet",
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Your conversations with patients will appear here",
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
}
