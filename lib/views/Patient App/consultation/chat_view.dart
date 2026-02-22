import 'package:flutter/material.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/widgets/custom_app_bar_widget.dart';

class ChatView extends StatefulWidget {
  final String recipientName;
  final String? profileImage;
  const ChatView({super.key, required this.recipientName, this.profileImage});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final TextEditingController _msgController = TextEditingController();
  // Status: sent, delivered, seen
  final List<Map<String, dynamic>> _messages = [
    {"msg": "Hello, Dr. ${"Sarah"}! I have a question about my prescription.", "isMe": true, "time": "10:30 AM", "status": "seen"},
    {"msg": "Hi there! Sure, please go ahead.", "isMe": false, "time": "10:31 AM", "status": "none"},
    {"msg": "Am I supposed to take the medicine before food?", "isMe": true, "time": "10:32 AM", "status": "delivered"},
    {"msg": "Yes, it is recommended to take it 30 mins before your meal.", "isMe": false, "time": "10:33 AM", "status": "none"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: CustomAppBar(
        centerTitle: false,
        titleSpacing: 0, // Fix: Bring content closer to arrow
        titleWidget: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16, // Compact
              backgroundColor: Colors.white.withOpacity(0.2),
              backgroundImage: widget.profileImage != null ? NetworkImage(widget.profileImage!) : null,
              child: widget.profileImage == null
                  ? Text(
                      widget.recipientName.isNotEmpty ? widget.recipientName.substring(0, 1).toUpperCase() : "?",
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                    )
                  : null,
            ),
            const SizedBox(width: 8), // Tighter spacing
            Text(
              widget.recipientName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500, // Not bold
                fontSize: 16, // Compact
              ),
            ),
          ],
        ),
        actions: [
          Container(
            height: 32, width: 32, // Compact
             decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.videocam_rounded, color: Colors.white, size: 18),
              padding: EdgeInsets.zero,
              onPressed: () {},
            ),
          ),
          const SizedBox(width: 8),
           Container(
            height: 32, width: 32, // Compact
             decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.call_rounded, color: Colors.white, size: 18),
              padding: EdgeInsets.zero,
              onPressed: () {},
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Compact padding
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isMe = message['isMe'] as bool;
                final status = message['status'] as String;

                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8), // Compact margin
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), // Compact bubble
                    decoration: BoxDecoration(
                      color: isMe ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                        bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                      ),
                      boxShadow: [
                         BoxShadow(
                           color: Colors.black.withOpacity(0.05),
                           blurRadius: 5,
                           offset: const Offset(0, 2),
                         )
                      ]
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          message['msg'],
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black87,
                            fontSize: 14, // Compact font
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              message['time'],
                              style: TextStyle(
                                color: isMe ? Colors.white70 : Colors.grey[500],
                                fontSize: 9, // Compact time
                              ),
                            ),
                            if (isMe) ...[
                              const SizedBox(width: 4),
                              if (status == 'sent')
                                const Icon(Icons.check, size: 12, color: Colors.white70)
                              else if (status == 'delivered')
                                const Icon(Icons.done_all, size: 12, color: Colors.white70)
                              else if (status == 'seen')
                                const Icon(Icons.done_all, size: 12, color: Colors.lightBlueAccent),
                            ]
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Input Area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Compact padding
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    style: const TextStyle(fontSize: 14), // Compact font
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF5F7FA),
                      hintText: "Type a message...",
                      hintStyle: const TextStyle(color: Colors.grey, fontSize: 13), // Compact hint
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), // Compact height
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: AppColors.primary,
                  radius: 20, // Smaller button
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 18),
                    onPressed: () {
                      if(_msgController.text.isNotEmpty) {
                        setState(() {
                          _messages.add({
                            "msg": _msgController.text,
                            "isMe": true,
                            "time": "Now",
                            "status": "sent" // Default status for new msg
                          });
                          _msgController.clear();
                        });
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
  }
}
