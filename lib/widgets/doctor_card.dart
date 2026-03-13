import 'package:flutter/material.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/models/doctor_model.dart';

class DoctorCard extends StatelessWidget {
  final DoctorModel doctor;
  final VoidCallback onTap;
  final VoidCallback? onBookPressed;

  const DoctorCard({
    super.key,
    required this.doctor,
    required this.onTap,
    this.onBookPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
           BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Builder(builder: (context) {
                    final String url = doctor.imageUrl.toLowerCase();
                    final bool isPlaceholder = url.isEmpty || 
                        url.contains('unsplash.com') ||
                        url.contains('randomuser.me') ||
                        url.contains('pravatar.cc') ||
                        url.contains('placeholder.com');

                    if (isPlaceholder) {
                      return Container(
                        height: 70,
                        width: 70,
                        color: Colors.grey[200],
                        child: const Icon(Icons.person, color: Colors.grey),
                      );
                    }
                    return Image.network(
                      doctor.imageUrl,
                      height: 70, // Reduced from 80
                      width: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        height: 70,
                        width: 70,
                        color: Colors.grey[200],
                        child: const Icon(Icons.person, color: Colors.grey),
                      ),
                    );
                  }),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              doctor.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        doctor.specialty,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(
                            doctor.rating.toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          Text(
                            " (120+)", // Fixed this to static as per previous fix
                            style: TextStyle(color: Colors.grey[400], fontSize: 11),
                          ),
                          const Spacer(),

                          if (onBookPressed != null)
                            SizedBox(
                              height: 28, // Compact Button
                              child: ElevatedButton(
                                onPressed: onBookPressed,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text("Book", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
