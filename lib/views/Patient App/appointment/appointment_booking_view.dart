import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/models/doctor_model.dart';
import 'package:medlink/views/services/session_view_model.dart';
import 'package:medlink/views/Patient%20App/appointment/appointment_viewmodel.dart';
import 'package:medlink/views/Patient%20App/appointment/appointment_payment_view.dart';
import 'package:medlink/widgets/custom_app_bar_widget.dart';
import 'package:medlink/widgets/custom_button.dart';
import 'package:provider/provider.dart';

class AppointmentBookingView extends StatefulWidget {
  final DoctorModel doctor;

  const AppointmentBookingView({super.key, required this.doctor});

  @override
  State<AppointmentBookingView> createState() => _AppointmentBookingViewState();
}

class _AppointmentBookingViewState extends State<AppointmentBookingView> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedTime;
  final TextEditingController _reasonController = TextEditingController();
  bool _showPayment = false;
  Map<String, dynamic>? _paymentData;
  String? _appointmentId;

  final List<String> _timeSlots = [
    "09:00 AM",
    "09:30 AM",
    "10:00 AM",
    "11:30 AM",
    "02:00 PM",
    "03:30 PM",
    "04:00 PM",
    "05:00 PM",
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Generate dates for the next 14 days
    final dates =
        List.generate(14, (index) => DateTime.now().add(Duration(days: index)));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: CustomAppBar(
          title: _showPayment ? "Complete Payment" : "Book Appointment"),
      body: _showPayment ? _buildPaymentSection() : _buildBookingForm(dates),
    );
  }

  Widget _buildBookingForm(List<DateTime> dates) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Doctor Summary Card (Premium)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          image: DecorationImage(
                            image: NetworkImage(widget.doctor.imageUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.doctor.name,
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget.doctor.specialty,
                              style: GoogleFonts.inter(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.star,
                                    size: 16, color: Colors.amber[700]),
                                const SizedBox(width: 4),
                                Text("4.8 (120 Reviews)",
                                    style: GoogleFonts.inter(
                                        color: Colors.grey[600], fontSize: 12)),
                              ],
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // 2. Calendar (Horizontal Scroll)
                Text("Select Date", style: _sectionTitleStyle),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: dates.map((date) {
                      final isSelected =
                          DateUtils.isSameDay(_selectedDate, date);
                      return GestureDetector(
                        onTap: () => setState(() => _selectedDate = date),
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color:
                                isSelected ? AppColors.primary : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.grey.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                DateFormat('d').format(date),
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('E').format(date),
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      isSelected ? Colors.white70 : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 30),

                // 3. Time Slots (Chips)
                Text("Available Times", style: _sectionTitleStyle),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _timeSlots.map((time) {
                    final isSelected = _selectedTime == time;
                    return InkWell(
                      onTap: () => setState(() => _selectedTime = time),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.grey.withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          time,
                          style: GoogleFonts.inter(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 30),

                // 4. Reason for visit
                Text("Reason for Visit", style: _sectionTitleStyle),
                const SizedBox(height: 16),
                TextField(
                  controller: _reasonController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: "E.g., Headache and nausea since 2 days",
                    fillColor: Colors.white,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide:
                          BorderSide(color: Colors.grey.withOpacity(0.2)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide:
                          BorderSide(color: Colors.grey.withOpacity(0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),

        // Bottom Bar
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, -5))
            ],
          ),
          child: SafeArea(
            child: CustomButton(
              text: "Continue to Payment",
              onPressed: _handleInitialBooking,
            ),
          ),
        )
      ],
    );
  }

  Widget _buildPaymentSection() {
    return AppointmentPaymentView(
      doctor: widget.doctor,
      date: _selectedDate,
      time: _selectedTime!,
      appointmentId: _appointmentId!,
      paymentData: _paymentData!,
    );
  }

  Future<void> _handleInitialBooking() async {
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a time slot")),
      );
      return;
    }

    final userViewModel = Provider.of<UserViewModel>(context, listen: false);
    final patientId = userViewModel.patient?.id;

    if (patientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text("Error: User session not found. Please login again.")),
      );
      return;
    }

    // Show loading hud
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppColors.primary)),
    );

    final viewModel = Provider.of<AppointmentViewModel>(context, listen: false);
    final result = await viewModel.bookAppointment(
      doctor: widget.doctor,
      date: _selectedDate,
      time: _selectedTime!,
      patientId: patientId,
      description: _reasonController.text.trim(),
    );

    if (!context.mounted) return;
    Navigator.pop(context); // Remove loading hud

    if (result['success'] == true && result['paymentData'] != null) {
      setState(() {
        _appointmentId = result['appointmentId'].toString();
        _paymentData = result['paymentData']; // This is now correctly extracted in ViewModel
        _showPayment = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(result['message'] ?? "Failed to initiate booking.")),
      );
    }
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        color: Colors.green[50], shape: BoxShape.circle),
                    child: const Icon(Icons.check_rounded,
                        size: 50, color: Colors.green),
                  ),
                  const SizedBox(height: 20),
                  Text("Appointment Requested!",
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold, fontSize: 20)),
                  const SizedBox(height: 10),
                  Text(
                    "Your appointment with ${widget.doctor.name} has been initiated. You can track the status in your appointments list.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        Navigator.pop(context); // Close Dialog
                        Navigator.pop(context); // Pop Booking View
                      },
                      child: const Text("Done"),
                    ),
                  )
                ],
              ),
            ));
  }

  TextStyle get _sectionTitleStyle => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      );
}
