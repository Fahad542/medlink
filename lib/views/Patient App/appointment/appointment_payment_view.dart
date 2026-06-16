import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/data/network/api_services.dart';
import 'package:medlink/models/doctor_model.dart';
import 'package:medlink/widgets/custom_app_bar_widget.dart';
import 'package:medlink/widgets/custom_button.dart';
import 'package:intl/intl.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:medlink/views/main/main_screen.dart';
import 'package:provider/provider.dart';
import 'package:medlink/services/appointment_socket_service.dart';
import 'package:medlink/views/Patient%20App/appointment/appointment_viewmodel.dart';
import 'package:medlink/views/services/session_view_model.dart';
import 'package:medlink/core/localization/app_localizations.dart';

class AppointmentPaymentView extends StatefulWidget {
  final DoctorModel doctor;
  final DateTime date;
  final String time;
  final String appointmentId;
  final Map<String, dynamic> paymentData; // Native Stripe data

  const AppointmentPaymentView({
    super.key,
    required this.doctor,
    required this.date,
    required this.time,
    required this.appointmentId,
    required this.paymentData,
  });

  @override
  State<AppointmentPaymentView> createState() => _AppointmentPaymentViewState();
}

class _AppointmentPaymentViewState extends State<AppointmentPaymentView> {
  bool _isProcessing = false;

  Future<void> _launchPayment() async {
    try {
      setState(() => _isProcessing = true);

      final dynamic pIntentRaw = widget.paymentData['paymentIntent'];
      final dynamic eKeyRaw = widget.paymentData['ephemeralKey'];
      final dynamic customerRaw = widget.paymentData['customer'];
      final dynamic publishableKeyRaw = widget.paymentData['publishableKey'];

      if (pIntentRaw == null || eKeyRaw == null || customerRaw == null) {
        throw Exception(context.tr('patient.appointment_payment.error.missing_data'));
      }

      final String paymentIntent = pIntentRaw.toString();
      final String ephemeralKey = eKeyRaw.toString();
      final String customer = customerRaw.toString();
      final String? publishableKey = publishableKeyRaw?.toString();

      if (publishableKey != null) {
        Stripe.publishableKey = publishableKey;
      }

      // Step 1: Initialize Payment Sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntent,
          customerEphemeralKeySecret: ephemeralKey,
          customerId: customer,
          merchantDisplayName: 'Medlink Africa',
          appearance: const PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: AppColors.primary,
            ),
          ),
        ),
      );

      // Step 2: Present Payment Sheet
      await Stripe.instance.presentPaymentSheet();

      // Step 3: SUCCESS - Confirm with backend manually
      final String paymentIntentId = paymentIntent.split('_secret_')[0];
      final confirmResponse =
          await ApiServices().confirmManualPayment(paymentIntentId);

      if (confirmResponse != null && confirmResponse['success'] == true) {
        if (mounted) {
          final patientId = Provider.of<UserViewModel>(context, listen: false)
              .patient
              ?.id
              .toString();
          AppointmentSocketService.instance.emitAfterBookingCreated(
            appointmentId: widget.appointmentId,
            doctorId: widget.doctor.id,
            patientId: patientId,
          );
          try {
            Provider.of<AppointmentViewModel>(context, listen: false)
                .loadUpcomingAppointments();
          } catch (_) {}
          setState(() =>
              _isProcessing = false); // Stop loading before success dialog
          _showSuccessDialog();
        }
      } else {
        throw Exception(
            confirmResponse?['message'] ??
                context.tr('patient.appointment_payment.error.confirm_failed'));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
      if (e is StripeException) {
        if (e.error.code == FailureCode.Canceled) {
          debugPrint(context.tr('patient.appointment_payment.debug.cancelled'));
          return;
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(context.tr('patient.appointment_payment.error.failed',
                    params: {'error': e.error.localizedMessage ?? ''}))),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(context.tr('patient.appointment_payment.error.generic',
                    params: {'error': e.toString()}))),
          );
        }
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: Colors.green, size: 48),
            ),
            const SizedBox(height: 24),
            Text(
              context.tr('patient.appointment_payment.success.title'),
              style:
                  GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('patient.appointment_payment.success.subtitle',
                  params: {'doctor': widget.doctor.name}),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: context.tr('patient.appointment_payment.go_appointments'),
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                      builder: (_) => const MainScreen(initialIndex: 1)),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: CustomAppBar(title: context.tr('patient.appointment_payment.complete')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Payment Summary Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.payment_rounded,
                        color: AppColors.primary, size: 32),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.tr('patient.appointment_payment.fee_label'),
                    style: GoogleFonts.inter(
                        fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "CFA ${widget.doctor.consultationFee}",
                    style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            Text(context.tr('patient.appointment_payment.details'),
                style: GoogleFonts.inter(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            _buildDetailRow(Icons.person_outline,
                context.tr('patient.appointment_payment.doctor'), widget.doctor.name),
            _buildDetailRow(Icons.calendar_today_outlined,
                context.tr('patient.appointment_payment.date'),
                DateFormat('EEEE, MMM d, yyyy').format(widget.date)),
            _buildDetailRow(Icons.access_time_outlined,
                context.tr('patient.appointment_payment.time'), widget.time),

            const Spacer(),

            if (_isProcessing)
              Center(
                child: Column(
                  children: [
                    const CircularProgressIndicator(color: AppColors.primary),
                    const SizedBox(height: 16),
                    Text(context.tr('patient.appointment_payment.processing'),
                        style: GoogleFonts.inter(color: Colors.grey)),
                  ],
                ),
              )
            else
              CustomButton(
                text: context.tr('patient.appointment_payment.complete_secure'),
                onPressed: _launchPayment,
              ),

            const SizedBox(height: 16),
            Center(
              child: Text(
                context.tr('patient.appointment_payment.powered_by'),
                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500]),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[400]),
          const SizedBox(width: 12),
          Text(
            "$label: ",
            style: GoogleFonts.inter(
                color: Colors.grey[600], fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
                color: AppColors.textPrimary, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
