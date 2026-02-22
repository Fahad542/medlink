
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/widgets/custom_app_bar_widget.dart';
import 'package:medlink/widgets/custom_button.dart';
// Needed for PathMetric
import 'dart:ui' as ui;

class PaymentMethodsView extends StatefulWidget {
  const PaymentMethodsView({super.key});

  @override
  State<PaymentMethodsView> createState() => _PaymentMethodsViewState();
}

class _PaymentMethodsViewState extends State<PaymentMethodsView> {
  int _selectedOption = 0; // 0: Credit Card, 1: Paypal, 2: Google Pay, 3: Apple Pay

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Light grey bg
      appBar: const CustomAppBar(title: "Payment Methods"),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16), // Reduced padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Credit Card Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Credit Card",
                        style: GoogleFonts.inter(
                          fontSize: 16, // Reduced font
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      Radio<int>(
                        value: 0,
                        groupValue: _selectedOption,
                        activeColor: AppColors.primary,
                        onChanged: (val) => setState(() => _selectedOption = val!),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Credit Card Widget
                  _buildCreditCard(),
                  
                  const SizedBox(height: 24),
                  
                  // Add New Card Button (Dotted)
                  _buildAddCardButton(),
                  
                  const SizedBox(height: 32),
                  
                  // Divider "or continue with"
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey[300])),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "or continue with",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey[300])),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Other Payment Options
                  _buildPaymentOption(
                    index: 1,
                    name: "Paypal",
                    icon: Icons.paypal, // Using Icon for now, replace with asset if available
                    color: const Color(0xFF003087),
                  ),
                  const SizedBox(height: 16),
                  _buildPaymentOption(
                    index: 2,
                    name: "Google Pay",
                    icon: Icons.g_mobiledata_rounded, // Placeholder
                    color: Colors.black, // Placeholder color
                    isGoogle: true,
                  ),
                  const SizedBox(height: 16),
                  _buildPaymentOption(
                    index: 3,
                    name: "Apple Pay",
                    icon: Icons.apple,
                    color: Colors.black,
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom Continue Button
          const SizedBox(height: 100), // Spacing for bottom sheet
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0,-5)
              )
            ]
        ),
        child: SafeArea(
          child: SizedBox(
              width: double.infinity,
              child: CustomButton(
                  text: "Continue",
                  fontWeight: FontWeight.w500, // Reduced bold
                  onPressed: () {
                     // Handle Continue
                  },
              ),
          ),
        ),
    ),
  );
  }

  Widget _buildCreditCard() {
    return Container(
      height: 180, // Reduced height
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.secondary, // Light Teal
            AppColors.primary,   // Main Teal
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background decorative circles
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20), // Reduced vertical padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Section: Brand + Chip
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                         Text(
                          "Master Card",
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 14, // Slightly smaller
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12), // Reduced spacing
                    // Chip Icon (Mock)
                    Container(
                      width: 36, // Smaller chip
                      height: 26,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: const Icon(Icons.nfc, color: Colors.white70, size: 16),
                    ),
                  ],
                ),
                
                // Middle: Card Number
                Text(
                  "8040 2350 6950 3740",
                  style: GoogleFonts.sourceCodePro( 
                    color: Colors.white,
                    fontSize: 16, // Reduced font
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),

                // Bottom Row: Name, Expiry, Logo
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Valid",
                          style: GoogleFonts.inter(color: Colors.white70, fontSize: 10),
                        ),
                        Text(
                          "06/30",
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Abu Hasan Emon",
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    
                    // Mastercard Circles Mock
                    SizedBox(
                      height: 24, // Smaller Logo
                      width: 40,
                      child: Stack(
                        children: [
                          Container(
                            width: 24, 
                            height: 24,
                            decoration: BoxDecoration(color: Colors.red.withOpacity(0.8), shape: BoxShape.circle),
                          ),
                          Positioned(
                            left: 14,
                            child: Container(
                              width: 24, 
                              height: 24,
                              decoration: BoxDecoration(color: Colors.amber.withOpacity(0.8), shape: BoxShape.circle),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddCardButton() {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(30),
      child: Container(
        height: 50, // Reduced height
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.5),
            style: BorderStyle.none, // Can't do true dotted border easily without package, simulating with dashed or custom painter.
                                   // Using a simple blue border for now, or I can try CustomPaint if "dotted" is strict requirement.
                                   // The prompt says "dotted button".
          ),
        ),
        // To approximate the look without custom painter, we'll just use a outlined look and a '+' 
        child: CustomPaint(
          painter: _DottedBorderPainter(color: AppColors.primary),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_rounded, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  "Credit Card",
                  style: GoogleFonts.inter(
                    color: AppColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required int index, 
    required String name, 
    required IconData icon, 
    required Color color,
    bool isGoogle = false,
  }) {
    bool isSelected = _selectedOption == index;
    return InkWell(
      onTap: () => setState(() => _selectedOption = index),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 60, // Reduced height
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Row(
          children: [
             // Icon Container
             Container(
               width: 40,
               height: 40,
               decoration: BoxDecoration(
                 color: const Color(0xFFF1F5F9), // Light grey
                 shape: BoxShape.circle,
               ),
               child: Center(
                 child: isGoogle 
                 ? Text("G", style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)) // Simple G mock
                 : Icon(icon, color: color, size: 24),
               ),
             ),
             const SizedBox(width: 16),
             Expanded(
               child: Text(
                 name,
                 style: GoogleFonts.inter(
                   fontSize: 16,
                   fontWeight: FontWeight.w600,
                   color: const Color(0xFF1E293B),
                 ),
               ),
             ),
             /* // User design doesn't show radio buttons for these, but functionality implies selection?
                // The image shows "Credit Card" with a radio at the top. 
                // It's possible these are just buttons or they can also be selected.
                // I will assume they are selectable.
             */
             // Radio<int>(
             //   value: index,
             //   groupValue: _selectedOption,
             //   activeColor: AppColors.primary,
             //   onChanged: (val) => setState(() => _selectedOption = val!),
             // ),
          ],
        ),
      ),
    );
  }
}

class _DottedBorderPainter extends CustomPainter {
  final Color color;
  const _DottedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final Path path = Path();
    // Rounded Rect Path
    path.addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(30)));

    final Path dashPath = Path();
    double dashWidth = 6.0;
    double dashSpace = 4.0;
    double distance = 0.0;
    
    for (ui.PathMetric pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        dashPath.addPath(
          pathMetric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}


