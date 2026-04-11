import 'package:flutter/material.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/widgets/custom_app_bar_widget.dart';
import 'package:medlink/widgets/custom_network_image.dart';

import 'package:medlink/views/Patient App/consultation/chat_viewmodel.dart';
import 'package:medlink/models/chat_message_model.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:medlink/widgets/chat_message_shimmer.dart';
import 'package:medlink/views/services/session_view_model.dart';

class ChatView extends StatefulWidget {
  final String recipientName;
  final String? profileImage;
  final String doctorId;
  final String patientId;
  final String? appointmentId;
  final String? sosId;
  final String? tripId;

  const ChatView({
    super.key,
    required this.recipientName,
    this.profileImage,
    required this.doctorId,
    required this.patientId,
    this.appointmentId,
    this.sosId,
    this.tripId,
  });

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> with SingleTickerProviderStateMixin {
  final TextEditingController _msgController = TextEditingController();
  late final AnimationController _emptyAnimController;
  late final Animation<double> _emptyPulse;

  @override
  void initState() {
    super.initState();
    _emptyAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _emptyPulse = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(
        parent: _emptyAnimController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _emptyAnimController.dispose();
    _msgController.dispose();
    super.dispose();
  }

  Widget _buildEmptyChatBody(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _emptyPulse,
                child: Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Image.asset(
                    'assets/Icons/chat.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.chat_bubble_rounded,
                      size: 56,
                      color: AppColors.primary.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Start the conversation',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Text(
                  'Messages are private and delivered instantly. Send a message below.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ChatViewModel(
        doctorId: widget.doctorId,
        patientId: widget.patientId,
        token: Provider.of<UserViewModel>(context, listen: false).accessToken ??
            '',
        appointmentId: widget.appointmentId,
        sosId: widget.sosId,
        tripId: widget.tripId,
      )..fetchMessages(),
      child: Consumer<ChatViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            backgroundColor: const Color(0xFFF1F5F9),
            appBar: CustomAppBar(
              centerTitle: false,
              titleSpacing: 0,
              titleWidget: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomNetworkImage(
                    imageUrl: widget.profileImage,
                    width: 32,
                    height: 32,
                    shape: BoxShape.circle,
                    placeholderName: widget.recipientName,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.recipientName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              // actions: [
              //   Container(
              //     height: 32,
              //     width: 32,
              //     decoration: BoxDecoration(
              //       color: Colors.white.withOpacity(0.15),
              //       shape: BoxShape.circle,
              //     ),
              //     child: IconButton(
              //       icon: const Icon(Icons.videocam_rounded,
              //           color: Colors.white, size: 18),
              //       padding: EdgeInsets.zero,
              //       onPressed: () {},
              //     ),
              //   ),
              //   const SizedBox(width: 8),
              //   Container(
              //     height: 32,
              //     width: 32,
              //     decoration: BoxDecoration(
              //       color: Colors.white.withOpacity(0.15),
              //       shape: BoxShape.circle,
              //     ),
              //     child: IconButton(
              //       icon: const Icon(Icons.call_rounded,
              //           color: Colors.white, size: 18),
              //       padding: EdgeInsets.zero,
              //       onPressed: () {},
              //     ),
              //   ),
              //   const SizedBox(width: 16),
              // ],
            ),
            body: Column(
              children: [
                Expanded(
                  child: viewModel.isLoading
                      ? const ChatMessageShimmer()
                      : RefreshIndicator(
                          onRefresh: () => viewModel.fetchMessages(),
                          child: viewModel.messages.isEmpty
                              ? _buildEmptyChatBody(context)
                              : ListView.builder(
                            reverse: true, // Show latest messages at bottom
                            physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics()),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            itemCount: viewModel.messages.length,
                            itemBuilder: (context, index) {
                              final userVM = Provider.of<UserViewModel>(context,
                                  listen: false);
                              final uId = userVM.loginSession?.data?.user?.id
                                  ?.toString();
                              final dId = userVM.doctor?.id;
                              final pId = userVM.patient?.id;
                              final ambId = userVM.driver?.id;

                              final currentUserIdStr =
                                  (uId != null && uId.isNotEmpty)
                                      ? uId
                                      : (ambId != null && ambId.isNotEmpty)
                                          ? ambId
                                          : (dId != null && dId.isNotEmpty)
                                              ? dId
                                              : (pId != null && pId.isNotEmpty)
                                                  ? pId
                                                  : "0";
                              final currentUserId =
                                  int.tryParse(currentUserIdStr) ?? 0;

                              final message = viewModel.messages[index];
                              final isMe = message.senderId == currentUserId;

                              return Align(
                                alignment: isMe
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  constraints: BoxConstraints(
                                      maxWidth:
                                          MediaQuery.of(context).size.width *
                                              0.75),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                      color: isMe
                                          ? AppColors.primary
                                          : Colors.white,
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(16),
                                        topRight: const Radius.circular(16),
                                        bottomLeft: isMe
                                            ? const Radius.circular(16)
                                            : Radius.zero,
                                        bottomRight: isMe
                                            ? Radius.zero
                                            : const Radius.circular(16),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 5,
                                          offset: const Offset(0, 2),
                                        )
                                      ]),
                                  child: Column(
                                    crossAxisAlignment: isMe
                                        ? CrossAxisAlignment.end
                                        : CrossAxisAlignment.start,
                                    children: [
                                      if (message.messageType ==
                                              MessageType.IMAGE &&
                                          message.mediaUrl != null)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 8.0),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: CustomNetworkImage(
                                              imageUrl: message.mediaUrl!,
                                              fit: BoxFit.cover,
                                              borderRadius: 8,
                                            ),
                                          ),
                                        ),
                                      if (message.body != null &&
                                          message.body!.isNotEmpty)
                                        Text(
                                          message.body!,
                                          style: TextStyle(
                                            color: isMe
                                                ? Colors.white
                                                : Colors.black87,
                                            fontSize: 14,
                                          ),
                                        ),
                                      const SizedBox(height: 2),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            DateFormat('hh:mm a').format(
                                              message.sentAt.toLocal(),
                                            ),
                                            style: TextStyle(
                                              color: isMe
                                                  ? Colors.white70
                                                  : Colors.grey[500],
                                              fontSize: 9,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),

                // Input Area
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -5))
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _msgController,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF5F7FA),
                            hintText: "Type a message...",
                            hintStyle: const TextStyle(
                                color: Colors.grey, fontSize: 13),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: AppColors.primary,
                        radius: 20,
                        child: IconButton(
                          icon: const Icon(Icons.send,
                              color: Colors.white, size: 18),
                          onPressed: () {
                            if (_msgController.text.isNotEmpty) {
                              final userVM = Provider.of<UserViewModel>(context,
                                  listen: false);
                              final uId = userVM.loginSession?.data?.user?.id
                                  ?.toString();
                              final dId = userVM.doctor?.id;
                              final pId = userVM.patient?.id;
                              final ambId = userVM.driver?.id;

                              final currentUserId =
                                  (uId != null && uId.isNotEmpty)
                                      ? uId
                                      : (ambId != null && ambId.isNotEmpty)
                                          ? ambId
                                          : (dId != null && dId.isNotEmpty)
                                              ? dId
                                              : (pId != null && pId.isNotEmpty)
                                                  ? pId
                                                  : "0";
                              viewModel.sendMessage(
                                  _msgController.text, currentUserId);
                              _msgController.clear();
                            }
                          },
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
