import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ChatMessageShimmer extends StatelessWidget {
  final int itemCount;

  const ChatMessageShimmer({Key? key, this.itemCount = 6}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: itemCount,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final isMe = index % 2 == 0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                width: MediaQuery.of(context).size.width * (0.4 + (index % 3) * 0.1),
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                    bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
