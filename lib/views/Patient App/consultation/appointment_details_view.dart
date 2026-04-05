import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/models/doctor_model.dart';
import 'package:medlink/widgets/custom_button.dart';
import 'package:medlink/widgets/custom_app_bar_widget.dart';
import 'package:provider/provider.dart';
import 'package:medlink/views/services/session_view_model.dart';
import 'package:medlink/views/Patient%20App/appointment/appointment_viewmodel.dart';
import 'package:medlink/views/Patient%20App/appointment/appointment_payment_view.dart';
import 'package:medlink/views/main/main_screen.dart';

class AppointmentDetailsView extends StatelessWidget {
  final DoctorModel doctor;
  final DateTime selectedDate;
  final String selectedTime;

  const AppointmentDetailsView({
    super.key,
    required this.doctor,
    required this.selectedDate,
    required this.selectedTime,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: const CustomAppBar(
        title: "Appointment Details",
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Doctor Info
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ]),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundImage: (doctor.imageUrl.isNotEmpty)
                        ? NetworkImage(doctor.imageUrl)
                        : null,
                    child: (doctor.imageUrl.isEmpty)
                        ? const Icon(Icons.person, size: 30, color: Colors.grey)
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctor.name,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      doctor.specialty,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Details Grid
            Row(
              children: [
                Expanded(child: _buildDetailCard("Time", selectedTime)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildDetailCard("Date",
                        DateFormat("d MMM yyyy").format(selectedDate))),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _buildDetailCard(
                        "Duration", "${doctor.sessionDuration} min")),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildDetailCard(
                        "Price", "PKR ${doctor.consultationFee.toInt()}")),
              ],
            ),

            const SizedBox(height: 24),

            // Write for Doctor
            Text(
              "Write for Doctor",
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 5,
                        offset: const Offset(0, 2))
                  ]),
              child: TextField(
                maxLines: 4,
                style:
                    GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  hintText: "Write a summary of your situation...",
                  hintStyle:
                      GoogleFonts.inter(color: Colors.grey[400], fontSize: 13),
                ),
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
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
                  offset: const Offset(0, -5))
            ]),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: CustomButton(
                text: "Proceed to Payment",
                onPressed: () async {
                  final userViewModel =
                      Provider.of<UserViewModel>(context, listen: false);
                  final patientId = userViewModel.patient?.id;

                  if (patientId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              "Error: User session not found. Please login again.")),
                    );
                    return;
                  }

                  // Show loading indicator
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) =>
                        const Center(child: CircularProgressIndicator()),
                  );

                  final viewModel =
                      Provider.of<AppointmentViewModel>(context, listen: false);
                  final result = await viewModel.bookAppointment(
                    doctor: doctor,
                    date: selectedDate,
                    time: selectedTime,
                    patientId: patientId,
                  );

                  if (!context.mounted) return;
                  Navigator.pop(context); // Close loading dialog

                  if (result['success'] == true && result['paymentData'] != null) {
                    // Navigate to Payment Screen to show the native sheet
                    final paid = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AppointmentPaymentView(
                          doctor: doctor,
                          date: selectedDate,
                          time: selectedTime,
                          appointmentId: result['appointmentId'],
                          paymentData: result['paymentData'],
                        ),
                      ),
                    );

                    if (paid == true && context.mounted) {
                      _showFinalSuccessDialog(context);
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(result['message'] ??
                              "Failed to initiate payment.")),
                    );
                  }
                }),
          ),
        ),
      ),
    );
  }

  void _showFinalSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: Colors.green, size: 48),
              ),
              const SizedBox(height: 20),
              Text(
                "Booking Confirmed!",
                style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "Your appointment has been successfully booked and paid for. You can track it in your appointments list.",
                style: GoogleFonts.inter(
                    fontSize: 14, color: Colors.grey[600], height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: "Done",
                  onPressed: () {
                    // Navigate back to MainScreen and show Appointments tab (index 1)
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const MainScreen(initialIndex: 1)),
                      (route) => false,
                    );
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 12)),
          const SizedBox(height: 6),
          Text(value,
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: const Color(0xFF1E293B))),
        ],
      ),
    );
  }
}
