import 'package:flutter/material.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medlink/models/doctor_model.dart';
import 'package:medlink/widgets/custom_app_bar_widget.dart';

class DoctorReviewsView extends StatelessWidget {
  final DoctorModel doctor;

  const DoctorReviewsView({super.key, required this.doctor});

  @override
  Widget build(BuildContext context) {
    // Mock List of Reviews
    final reviews = [
      {
        "name": "John Doe",
        "rating": 4.5,
        "comment": "Great experience, very professional.",
        "date": "2 days ago"
      },
      {
        "name": "Jane Smith",
        "rating": 5.0,
        "comment": "Highly recommended!",
        "date": "1 week ago"
      },
      {
        "name": "Michael Brown",
        "rating": 4.0,
        "comment": "Good doctor, but wait time was long.",
        "date": "3 weeks ago"
      },
      {
        "name": "Emily White",
        "rating": 5.0,
        "comment": "Excellent care and friendly staff.",
        "date": "1 month ago"
      },
      {
        "name": "David Wilson",
        "rating": 3.5,
        "comment": "Average experience.",
        "date": "1 month ago"
      },
      {
        "name": "Sarah Johnson",
        "rating": 4.8,
        "comment": "Very knowledgeable and kind.",
        "date": "2 months ago"
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: CustomAppBar(title: "Reviews for ${doctor.name
          .split(' ')
          .first}"), // Shorten name for title
      body: Column(
        children: [
          _buildReviewSummary(reviews),
          Expanded(
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              itemCount: reviews.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              // Reduced spacing
              itemBuilder: (context, index) {
                final review = reviews[index];
                return Container(
                  padding: const EdgeInsets.all(12), // Reduced padding
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    // Slightly less rounded
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
                                // Smaller avatar
                                height: 32,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.08),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  (review['name'] as String)[0],
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
                                    review['name'] as String,
                                    style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: const Color(0xFF1E293B)),
                                  ),
                                  Text(
                                    review['date'] as String,
                                    style: GoogleFonts.inter(
                                        color: Colors.grey[500], fontSize: 10),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star_rounded, size: 14,
                                    color: Colors.amber),
                                const SizedBox(width: 4),
                                Text(
                                  (review['rating'] as double).toString(),
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
                        review['comment'] as String,
                        style: GoogleFonts.inter(color: const Color(0xFF64748B),
                            height: 1.4,
                            fontSize: 12.5),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewSummary(List<Map<String, dynamic>> reviews) {
    // Calculate stats (Mocked logic for simplicity, assuming data is static)
    double averageRating = 4.8;
    int totalReviews = 120; // Mock total

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16), // Reduced padding
      child: Row(
        children: [
          // Average Rating Big
          Column(
            children: [
              Text(
                averageRating.toString(),
                style: GoogleFonts.inter(fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B)), // Smaller font
              ),
              Row(
                children: List.generate(5, (index) =>
                    Icon(
                        Icons.star_rounded,
                        color: index < 4 ? Colors.amber : Colors.grey[300],
                        size: 16 // Smaller stars
                    )),
              ),
              const SizedBox(height: 4),
              Text(
                "$totalReviews Reviews",
                style: GoogleFonts.inter(color: Colors.grey[500],
                    fontSize: 11,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(width: 24),
          // Progress Bars
          Expanded(
            child: Column(
              children: [
                _buildRatingBar(5, 0.8),
                _buildRatingBar(4, 0.15),
                _buildRatingBar(3, 0.03),
                _buildRatingBar(2, 0.01),
                _buildRatingBar(1, 0.01),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBar(int star, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2), // Tighter spacing
      child: Row(
        children: [
          Text(
            "$star",
            style: GoogleFonts.inter(fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600]), // Smaller font
          ),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value,
                backgroundColor: Colors.grey[100],
                color: AppColors.primary,
                minHeight: 4, // Thinner bar
              ),
            ),
          ),
        ],
      ),
    );
  }
}