import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class PrescriptionListShimmer extends StatelessWidget {
  final int itemCount;

  const PrescriptionListShimmer({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: itemCount,
      physics: const NeverScrollableScrollPhysics(), // Since it's a loader
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              Padding(
                padding: const EdgeInsets.all(16),
                child: Shimmer.fromColors(
                  baseColor: Colors.grey[200]!,
                  highlightColor: Colors.grey[50]!,
                  child: Row(
                    children: [
                      // Avatar Placeholder
                      Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Doctor Name Placeholder
                            Container(
                              width: MediaQuery.of(context).size.width * 0.4,
                              height: 15,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Specialty Placeholder
                            Container(
                              width: MediaQuery.of(context).size.width * 0.25,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Date Placeholder
                            Container(
                              width: MediaQuery.of(context).size.width * 0.2,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Badge Placeholder
                      Container(
                        width: 60,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Divider(height: 1, color: Colors.grey[100]),

              // ── Diagnosis Section Placeholder ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Shimmer.fromColors(
                  baseColor: Colors.grey[200]!,
                  highlightColor: Colors.grey[50]!,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Medical Icon Placeholder
                      Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Diagnosis Lines
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 60,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              width: MediaQuery.of(context).size.width * 0.5,
                              height: 14,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              Divider(height: 1, color: Colors.grey[100]),

              // ── Footer (Appointment Date) Placeholder ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Shimmer.fromColors(
                  baseColor: Colors.grey[200]!,
                  highlightColor: Colors.grey[50]!,
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: MediaQuery.of(context).size.width * 0.6,
                        height: 13,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        );
      },
    );
  }
}
