import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ChatListShimmer extends StatelessWidget {
  final int itemCount;

  const ChatListShimmer({Key? key, this.itemCount = 4}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: itemCount,
      physics: const NeverScrollableScrollPhysics(), // Important since usually wrapped or short
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[200]!,
            highlightColor: Colors.white,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: const CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white,
              ),
              title: Container(
                height: 14,
                width: 120, // Title width
                margin: const EdgeInsets.only(right: 40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  height: 12,
                  width: double.infinity, // Subtitle usually spans
                  margin: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              trailing: Container(
                height: 12,
                width: 40, // Time width
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
