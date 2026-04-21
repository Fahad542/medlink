import 'dart:async';

import 'package:flutter/material.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medlink/widgets/custom_app_bar_widget.dart';
import 'package:medlink/views/Patient App/consultation/chat_view.dart';

import 'package:medlink/views/services/session_view_model.dart';
import 'package:medlink/views/doctor/doctor_chat_history_view_model.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:medlink/widgets/custom_network_image.dart';
import 'package:intl/intl.dart';

/// Owns [DoctorChatHistoryViewModel] lifecycle (socket subscription + dispose).
class DoctorChatListScreen extends StatefulWidget {
  const DoctorChatListScreen({super.key});

  @override
  State<DoctorChatListScreen> createState() => _DoctorChatListScreenState();
}

class _DoctorChatListScreenState extends State<DoctorChatListScreen> {
  late final DoctorChatHistoryViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = DoctorChatHistoryViewModel(
      Provider.of<UserViewModel>(context, listen: false),
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: const DoctorChatListView(),
    );
  }
}

class DoctorChatListView extends StatefulWidget {
  const DoctorChatListView({super.key});

  @override
  State<DoctorChatListView> createState() => _DoctorChatListViewState();
}

class _DoctorChatListViewState extends State<DoctorChatListView> {
  String _fetchSeed = '';
  bool _fetchQueued = false;

  void _fetchChatsIfReady() {
    final userVM = Provider.of<UserViewModel>(context, listen: false);
    // Must match JWT user id (chat DB uses User.id). Prefer session id, then doctor model.
    final loginId = userVM.loginSession?.data?.user?.id?.toString();
    final docId = userVM.doctor != null ? userVM.doctor!.id.trim() : '';
    final String? doctorId = (loginId != null && loginId.isNotEmpty)
        ? loginId
        : (docId.isNotEmpty ? docId : null);
    final token = userVM.accessToken ?? '';
    final nextSeed = '${doctorId ?? ''}|$token';

    // Fetch whenever auth/session identity becomes available or changes.
    if (nextSeed == _fetchSeed) return;
    _fetchSeed = nextSeed;

    if (doctorId == null || doctorId.isEmpty) {
      debugPrint('Doctor chat list: no user id — cannot load conversations');
      return;
    }

    if (_fetchQueued) return;
    _fetchQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchQueued = false;
      if (!mounted) return;
      Provider.of<DoctorChatHistoryViewModel>(context, listen: false)
          .fetchChatHistory(doctorId);
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _fetchChatsIfReady();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!mounted) return;
    // Defer network fetch so notifyListeners never runs during build phase.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _fetchChatsIfReady();
    });
  }

  @override
  void dispose() {
    _fetchQueued = false;
    super.dispose();
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
                            onTap: () async {
                              final userVM = Provider.of<UserViewModel>(
                                  context,
                                  listen: false);
                              final patientIdInt =
                                  int.tryParse(chat.patient?.id ?? '');
                              if (patientIdInt != null) {
                                Provider.of<DoctorChatHistoryViewModel>(context,
                                        listen: false)
                                    .clearUnreadForPatient(patientIdInt);
                                unawaited(
                                  Provider.of<DoctorChatHistoryViewModel>(
                                    context,
                                    listen: false,
                                  ).markThreadReadForPatient(patientIdInt),
                                );
                              }
                              final uId = userVM.loginSession?.data?.user?.id?.toString();
                              final dId = userVM.doctor?.id;
                              final currentUserIdStr =
                                  (dId != null && dId.isNotEmpty)
                                      ? dId
                                      : (uId ?? '');
                              await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => ChatView(
                                            recipientName:
                                                chat.patient?.fullName ?? "",
                                            profileImage:
                                                chat.patient?.profilePhotoUrl ?? "",
                                            appointmentId:
                                                "",
                                            doctorId:
                                                currentUserIdStr.toString(),
                                            patientId: chat.patient?.id ?? "",
                                          )));
                              final loginId =
                                  userVM.loginSession?.data?.user?.id?.toString();
                              final docId = userVM.doctor != null
                                  ? userVM.doctor!.id.trim()
                                  : '';
                              final String? doctorIdForFetch =
                                  (loginId != null && loginId.isNotEmpty)
                                      ? loginId
                                      : (docId.isNotEmpty ? docId : null);
                              if (doctorIdForFetch != null &&
                                  doctorIdForFetch.isNotEmpty &&
                                  context.mounted) {
                                await Provider.of<DoctorChatHistoryViewModel>(
                                        context,
                                        listen: false)
                                    .fetchChatHistory(doctorIdForFetch);
                              }
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
