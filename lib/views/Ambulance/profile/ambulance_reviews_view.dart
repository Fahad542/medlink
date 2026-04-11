import 'package:flutter/material.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/data/network/api_services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medlink/widgets/custom_app_bar_widget.dart';
import 'package:intl/intl.dart';

class AmbulanceReviewsView extends StatelessWidget {
  const AmbulanceReviewsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: const CustomAppBar(title: "My Reviews"),
      body: FutureBuilder<dynamic>(
        future: ApiServices().getDriverReviews(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final response = snapshot.data;
          final data = response is Map ? response['data'] : null;
          final reviews = (data is Map && data['reviews'] is List)
              ? List<Map<String, dynamic>>.from(data['reviews'])
              : <Map<String, dynamic>>[];
          final avg = double.tryParse((data is Map ? data['averageRating'] : '0.0').toString()) ?? 0.0;
          final total = int.tryParse((data is Map ? data['totalReviews'] : '0').toString()) ?? 0;

          if (reviews.isEmpty && !snapshot.hasError) {
             return _buildEmptyState();
          }

          final distribution = _buildDistribution(reviews);

          return Column(
            children: [
              _buildReviewSummary(
                averageRating: avg,
                totalReviews: total,
                distribution: distribution,
              ),
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  itemCount: reviews.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final review = reviews[index];
                    return _buildReviewCard(review);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star_outline_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "No reviews yet",
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Your ratings from patients will appear here.",
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final patientMap = review['patient'] is Map
        ? Map<String, dynamic>.from(review['patient'])
        : <String, dynamic>{};
    final reviewerName = (patientMap['fullName'] ?? "Patient").toString();
    final rating = (double.tryParse(review['rating']?.toString() ?? '0') ?? 0).toStringAsFixed(1);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff1D1617).withOpacity(0.04),
            offset: const Offset(0, 3),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      reviewerName.isNotEmpty ? reviewerName.characters.first : "P",
                      style: GoogleFonts.inter(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reviewerName,
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: const Color(0xFF1E293B)),
                      ),
                      Text(
                        _formatReviewDate(review['createdAt']),
                        style: GoogleFonts.inter(
                            color: Colors.grey[500], fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      rating,
                      style: GoogleFonts.inter(
                          color: const Color(0xFF1E293B),
                          fontWeight: FontWeight.bold,
                          fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            (review['comment'] ?? "No written feedback provided.").toString(),
            style: GoogleFonts.inter(
                color: const Color(0xFF64748B), height: 1.4, fontSize: 12.5),
          ),
        ],
      ),
    );
  }

  Map<int, double> _buildDistribution(List<Map<String, dynamic>> reviews) {
    final counts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (final r in reviews) {
      final star = (double.tryParse(r['rating']?.toString() ?? '0') ?? 0).round();
      if (star >= 1 && star <= 5) counts[star] = (counts[star] ?? 0) + 1;
    }
    final total = reviews.length;
    if (total == 0) return {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    return {
      1: (counts[1] ?? 0) / total,
      2: (counts[2] ?? 0) / total,
      3: (counts[3] ?? 0) / total,
      4: (counts[4] ?? 0) / total,
      5: (counts[5] ?? 0) / total,
    };
  }

  Widget _buildReviewSummary({
    required double averageRating,
    required int totalReviews,
    required Map<int, double> distribution,
  }) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Column(
            children: [
              Text(
                averageRating.toStringAsFixed(1),
                style: GoogleFonts.inter(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B)),
              ),
              Row(
                children: List.generate(
                    5,
                    (index) => Icon(Icons.star_rounded,
                        color: index < averageRating.round()
                            ? Colors.amber
                            : Colors.grey[300],
                        size: 16)),
              ),
              const SizedBox(height: 4),
              Text(
                "$totalReviews Reviews",
                style: GoogleFonts.inter(
                    color: Colors.grey[500],
                    fontSize: 11,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              children: [
                _buildRatingBar(5, distribution[5] ?? 0),
                _buildRatingBar(4, distribution[4] ?? 0),
                _buildRatingBar(3, distribution[3] ?? 0),
                _buildRatingBar(2, distribution[2] ?? 0),
                _buildRatingBar(1, distribution[1] ?? 0),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatReviewDate(dynamic value) {
    if (value == null) return "Recently";
    final dt = DateTime.tryParse(value.toString());
    if (dt == null) return value.toString();
    final now = DateTime.now();
    final diff = now.difference(dt.toLocal());
    if (diff.inMinutes < 1) return "Just now";
    if (diff.inHours < 1) return "${diff.inMinutes} min ago";
    if (diff.inDays < 1) return "${diff.inHours} hours ago";
    if (diff.inDays < 7) return "${diff.inDays} days ago";
    return DateFormat('MMM d, yyyy').format(dt.toLocal());
  }

  Widget _buildRatingBar(int star, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            "$star",
            style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600]),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value,
                backgroundColor: Colors.grey[100],
                color: AppColors.primary,
                minHeight: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
