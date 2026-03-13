import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class CategoryShimmer extends StatelessWidget {
  const CategoryShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16), // Adjusted to match Home padding
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return Container(
            width: 100,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02), // Match subtle Category shadow
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[200]!,
              highlightColor: Colors.grey[50]!,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: 60,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class DoctorListShimmer extends StatelessWidget {
  const DoctorListShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: 6,
      physics: const NeverScrollableScrollPhysics(), // Usually good for loaders
      itemBuilder: (context, index) {
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
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[200]!, // Lightened for better look
              highlightColor: Colors.grey[50]!,  // Lightened for better look
              child: Row(
                children: [
                   // Image Placeholder
                  Container(
                    height: 70,
                    width: 70,
                    decoration: BoxDecoration(
                      color: Colors.white, 
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(width: 14),
                  
                  // Details Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Title Placeholder
                        Container(
                          width: MediaQuery.of(context).size.width * 0.4,
                          height: 15,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Subtitle Placeholder (Specialty)
                        Container(
                          width: MediaQuery.of(context).size.width * 0.25,
                          height: 13,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Ratings Row
                        Row(
                          children: [
                            // Fake Star Icon Placeholder
                            Container(
                              width: 16,
                              height: 16,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle, 
                              ),
                            ),
                            const SizedBox(width: 4),
                            // Rating Text Placeholder
                            Container(
                              width: 60,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
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
        );
      },
    );
  }
}

class DropdownShimmer extends StatelessWidget {
  const DropdownShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[50]!,
      child: Container(
        height: 58, // Matches the approximate height of the dropdown field
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 150,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const Spacer(),
            const Padding(
              padding: EdgeInsets.only(right: 20),
              child:
                  Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class AppointmentCardShimmer extends StatelessWidget {
  const AppointmentCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!, // Consistent with other shimmers
      highlightColor: Colors.grey[50]!,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Doctor Image Placeholder
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.withOpacity(0.1)),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Info Column Placeholder
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Doctor Name Placeholder
                      Container(
                        height: 14,
                        width: 120, // Typical name length
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      
                      // Specialty Placeholder
                      Container(
                        height: 12,
                        width: 90, // Typical specialty length
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Date & Time Row Placeholder
                      Row(
                        children: [
                          Container(
                            width: 14,
                            height: 14,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            height: 12,
                            width: 100, // Typical date/time length
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // 3-dots Action Icon Placeholder
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class VisitCardShimmer extends StatelessWidget {
  const VisitCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[200]!,
        highlightColor: Colors.grey[50]!,
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(height: 14, width: 120, color: Colors.white),
                      Container(height: 10, width: 60, color: Colors.white),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(height: 12, width: 80, color: Colors.white),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(height: 12, width: 150, color: Colors.white),
                      Container(height: 11, width: 70, color: Colors.white),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ArticleShimmer extends StatelessWidget {
  const ArticleShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[200]!,
        highlightColor: Colors.grey[50]!,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Placeholder on the Left
              Container(
                height: 120,
                width: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(width: 16),
              
              // Info Placeholder on the Right
              Expanded(
                child: SizedBox(
                  height: 120,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Expected Top Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  height: 14, 
                                  width: double.infinity, 
                                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  height: 14, 
                                  width: 150, 
                                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 20, 
                            height: 20, 
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)
                          ),
                        ],
                      ),
                      
                      const Spacer(),
                      
                      // Expected Bottom Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 12, 
                                width: 80, 
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 14, 
                                width: 60, 
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))
                              ),
                            ],
                          ),
                          Container(
                            height: 38,
                            width: 38,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EmergencyContactsShimmer extends StatelessWidget {
  const EmergencyContactsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    // Mimic the container that holds the list in the emergency tab
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: List.generate(3, (index) {
          final isLast = index == 2;
          return Column(
            children: [
              Row(
                children: [
                  // Icon placeholder
                  Shimmer.fromColors(
                    baseColor: Colors.grey[200]!,
                    highlightColor: Colors.grey[50]!,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Text placeholders
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Shimmer.fromColors(
                          baseColor: Colors.grey[200]!,
                          highlightColor: Colors.grey[50]!,
                          child: Container(
                            height: 14,
                            width: 100, // Name width
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Shimmer.fromColors(
                          baseColor: Colors.grey[200]!,
                          highlightColor: Colors.grey[50]!,
                          child: Container(
                            height: 10,
                            width: 60, // Subtitle width
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Button placeholder
                  Shimmer.fromColors(
                    baseColor: Colors.grey[200]!,
                    highlightColor: Colors.grey[50]!,
                    child: Container(
                      height: 32,
                      width: 70, // Button width
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10), // Same rounding as button
                      ),
                    ),
                  ),
                ],
              ),
              if (!isLast) const Divider(height: 24, color: Color(0xFFF1F5F9)),
            ],
          );
        }),
      ),
    );
  }
}

class QuickInstructionShimmer extends StatelessWidget {
  const QuickInstructionShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(2, (index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon placeholder
                Shimmer.fromColors(
                  baseColor: Colors.grey[200]!,
                  highlightColor: Colors.grey[50]!,
                  child: Container(
                    width: 32, // Based on a typical icon size + small padding
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Text placeholders
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Shimmer.fromColors(
                        baseColor: Colors.grey[200]!,
                        highlightColor: Colors.grey[50]!,
                        child: Container(
                          height: 16,
                          width: 150, // Title width
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Shimmer.fromColors(
                        baseColor: Colors.grey[200]!,
                        highlightColor: Colors.grey[50]!,
                        child: Container(
                          height: 12,
                          width: double.infinity, // Content width line 1
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Shimmer.fromColors(
                        baseColor: Colors.grey[200]!,
                        highlightColor: Colors.grey[50]!,
                        child: Container(
                          height: 12,
                          width: 200, // Content width line 2
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class FirstAidShimmer extends StatelessWidget {
  const FirstAidShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
      itemCount: 4,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[200]!,
            highlightColor: Colors.grey[50]!,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Icon placeholder (left)
                  Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Text Info placeholders (middle)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 14,
                          width: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 12,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Arrow button placeholder (right)
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class VideoReelsShimmer extends StatelessWidget {
  const VideoReelsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      scrollDirection: Axis.vertical,
      itemCount: 3,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Background placeholder
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    color: Colors.white,
                  ),
                ),
                
                // Gradient Overlay Simulation
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.5),
                      ],
                    ),
                  ),
                ),

                // Content Overlays
                Positioned(
                  left: 20,
                  bottom: 20,
                  right: 80,
                  child: Shimmer.fromColors(
                    baseColor: Colors.white.withOpacity(0.3),
                    highlightColor: Colors.white.withOpacity(0.1),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 20,
                          width: 180,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          height: 14,
                          width: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class PersonalInfoShimmer extends StatelessWidget {
  const PersonalInfoShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Profile Image Shimmer
          Center(
            child: Shimmer.fromColors(
              baseColor: Colors.grey[200]!,
              highlightColor: Colors.grey[50]!,
              child: Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Fields Shimmer
          _buildFieldShimmer(context),
          const SizedBox(height: 16),
          _buildFieldShimmer(context),
          const SizedBox(height: 16),

          // Row for Date of Birth & Gender
          Row(
            children: [
              Expanded(child: _buildFieldShimmer(context)),
              const SizedBox(width: 16),
              Expanded(child: _buildFieldShimmer(context)),
            ],
          ),
          const SizedBox(height: 16),

          _buildFieldShimmer(context),
          const SizedBox(height: 16),
          _buildFieldShimmer(context),
          const SizedBox(height: 16),

          // Row for Age & Weight
          Row(
            children: [
              Expanded(child: _buildFieldShimmer(context)),
              const SizedBox(width: 16),
              Expanded(child: _buildFieldShimmer(context)),
            ],
          ),
          const SizedBox(height: 16),
          _buildFieldShimmer(context),
        ],
      ),
    );
  }

  Widget _buildFieldShimmer(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label Shimmer
        Shimmer.fromColors(
          baseColor: Colors.grey[200]!,
          highlightColor: Colors.grey[50]!,
          child: Container(
            height: 12,
            width: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Field Shimmer
        Shimmer.fromColors(
          baseColor: Colors.grey[200]!,
          highlightColor: Colors.grey[50]!,
          child: Container(
            height: 56,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }
}

class DoctorPatientListShimmer extends StatelessWidget {
  const DoctorPatientListShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(left: 16, right: 16, top: 0, bottom: 100),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[200]!,
            highlightColor: Colors.grey[50]!,
            child: Row(
              children: [
                // Avatar Shimmer
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                // Names & Stats Shimmer
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            height: 14,
                            width: 100,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            height: 14,
                            width: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 12,
                        width: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
                // More Options Icon Shimmer
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
