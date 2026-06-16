import 'dart:async';

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

class ChatListView extends StatefulWidget {
  const ChatListView({super.key});

  @override
  State<ChatListView> createState() => _ChatListViewState();
}

class _ChatListViewState extends State<ChatListView> {
  late final ChatListViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ChatListViewModel(
      Provider.of<UserViewModel>(context, listen: false),
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  /// Local device time; same rules as doctor list (today → clock, else date).
  static String _formatListTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(local.year, local.month, local.day);
    final difference = today.difference(messageDate).inDays;
    if (difference == 0) {
      return DateFormat.jm().format(local);
    }
    if (difference == 1) return 'Yesterday';
    if (difference < 7) return DateFormat.EEEE().format(local);
    return DateFormat.yMd().format(local);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
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
                            final String time =
                                _ChatListViewState._formatListTime(
                                    chat.lastMessageDate);
                            final String? profileImage = doctor.profilePhotoUrl;
                            final bool isUnread = chat.unreadCount > 0;

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
                                leading: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    CustomNetworkImage(
                                      imageUrl: profileImage,
                                      width: 44,
                                      height: 44,
                                      shape: BoxShape.circle,
                                      placeholderName: doctorName,
                                    ),
                                    if (isUnread)
                                      Positioned(
                                        right: -2,
                                        top: -2,
                                        child: Container(
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            color: Colors.redAccent,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color: Colors.white, width: 1.5),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                title: Text(doctorName,
                                    style: GoogleFonts.inter(
                                        fontWeight: isUnread
                                            ? FontWeight.w700
                                            : FontWeight.w600,
                                        fontSize: 15,
                                        color: isUnread
                                            ? AppColors.textPrimary
                                            : null)),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    lastMessage,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                        color: isUnread
                                            ? AppColors.textPrimary
                                            : Colors.grey[600],
                                        fontSize: 13,
                                        fontWeight: isUnread
                                            ? FontWeight.w500
                                            : FontWeight.normal),
                                  ),
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      time,
                                      style: GoogleFonts.inter(
                                        color: isUnread
                                            ? AppColors.primary
                                            : Colors.grey[400],
                                        fontSize: 11,
                                        fontWeight: isUnread
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    if (isUnread) ...[
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '${chat.unreadCount}',
                                          style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                onTap: () async {
                                  viewModel.clearUnreadForDoctor(doctor.id);
                                  unawaited(
                                      viewModel.markThreadReadForDoctor(doctor.id));
                                  await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => ChatView(
                                                recipientName: doctorName,
                                                profileImage: profileImage,
                                                doctorId: doctor.id.toString(),
                                                patientId: userVM.patient?.id ?? '',
                                                appointmentId: chat.id,
                                              )));
                                  await viewModel.onRefresh();
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
