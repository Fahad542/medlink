import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/core/constants/app_url.dart';
import 'package:medlink/models/appointment_model.dart';
import 'package:medlink/views/doctor/Consultation/submit_consultation_view_model.dart';
import 'package:medlink/views/doctor/doctor_appointments_view_model.dart';
import 'package:medlink/widgets/consultation_type_badge.dart';
import 'package:medlink/widgets/custom_app_bar_widget.dart';
import 'package:medlink/widgets/custom_button.dart';
import 'package:provider/provider.dart';
import 'package:medlink/core/localization/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class SubmitConsultationView extends StatelessWidget {
  final AppointmentModel appointment;

  const SubmitConsultationView({super.key, required this.appointment});

  @override
  Widget build(BuildContext context) {
    final bool isCompleted =
        appointment.status == AppointmentStatus.completed ||
            appointment.prescription != null;

    return ChangeNotifierProvider(
      create: (context) =>
          SubmitConsultationViewModel()..populateFromAppointment(appointment),
      child: Consumer<SubmitConsultationViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            backgroundColor: const Color(0xFFF9FAFB),
            appBar: CustomAppBar(
                title: isCompleted
                    ? context.tr('doctor.consultation.details_title')
                    : context.tr('doctor.consultation.title')),
            body: viewModel.isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPatientHeader(context),
                        const SizedBox(height: 24),
                        _buildSectionTitle(context.tr('prescription.section.diagnosis')),
                        _buildTextField(context, context.tr('doctor.consultation.chief_complaint'),
                            viewModel.chiefComplaintController,
                            maxLines: 2, readOnly: isCompleted),
                        const SizedBox(height: 16),
                        _buildTextField(context, context.tr('doctor.consultation.provisional_diagnosis'),
                            viewModel.provisionalDiagnosisController,
                            maxLines: 2, readOnly: isCompleted),
                        const SizedBox(height: 32),
                        _buildSectionTitle(context.tr('prescription.section.vitals')),
                        Row(
                          children: [
                            Expanded(
                                child: _buildTextField(context, context.tr('doctor.consultation.bp_systolic'),
                                    viewModel.bpSystolicController,
                                    keyboardType: TextInputType.number,
                                    readOnly: isCompleted)),
                            const SizedBox(width: 12),
                            Expanded(
                                child: _buildTextField(context, context.tr('doctor.consultation.bp_diastolic'),
                                    viewModel.bpDiastolicController,
                                    keyboardType: TextInputType.number,
                                    readOnly: isCompleted)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                                child: _buildTextField(
                                    context,
                                    context.tr('doctor.consultation.pulse'), viewModel.pulseController,
                                    keyboardType: TextInputType.number,
                                    readOnly: isCompleted)),
                            const SizedBox(width: 12),
                            Expanded(
                                child: _buildTextField(context, context.tr('doctor.consultation.temp'),
                                    viewModel.temperatureController,
                                    keyboardType: TextInputType.number,
                                    readOnly: isCompleted)),
                          ],
                        ),
                        const SizedBox(height: 32),
                        if (!isCompleted ||
                            viewModel.medications.isNotEmpty) ...[
                          _buildSectionTitle(context.tr('prescription.section.medications')),
                          if (!isCompleted) _buildMedicationForm(context, viewModel),
                          const SizedBox(height: 12),
                          _buildMedicationList(viewModel,
                              readOnly: isCompleted),
                          const SizedBox(height: 32),
                        ],
                        if (!isCompleted || viewModel.tests.isNotEmpty) ...[
                          _buildSectionTitle(context.tr('prescription.section.tests_required')),
                          if (!isCompleted) _buildTestForm(context, viewModel),
                          const SizedBox(height: 12),
                          _buildTestList(context, viewModel, readOnly: isCompleted),
                        ],
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
            bottomNavigationBar: isCompleted
                ? null
                : Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -5))
                      ],
                    ),
                    child: SafeArea(
                      child: CustomButton(
                        text: context.tr('doctor.consultation.submit'),
                        onPressed: () async {
                          bool success = await viewModel.submitConsultation(
                              context, appointment.id);
                          if (success && context.mounted) {
                            // Trigger refresh on appointments and dashboard
                            try {
                              Provider.of<DoctorAppointmentsViewModel>(context,
                                      listen: false)
                                  .fetchUpcomingAppointments();
                              Provider.of<DoctorAppointmentsViewModel>(context,
                                      listen: false)
                                  .fetchPastAppointments();
                            } catch (e) {
                              debugPrint("Could not refresh appointments: $e");
                            }
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildPatientHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            backgroundImage: (appointment.user?.profileImage != null &&
                    appointment.user!.profileImage!.isNotEmpty)
                ? NetworkImage(appointment.user!.profileImage!)
                : null,
            child: (appointment.user?.profileImage == null ||
                    appointment.user!.profileImage!.isEmpty)
                ? const Icon(Icons.person, color: AppColors.primary)
                : null,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(appointment.user?.name ?? context.tr('common.patient'),
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              Text(
                  context.tr(
                    'doctor.consultation.age_gender',
                    params: {
                      'age': appointment.user?.age ?? '--',
                      'gender': appointment.user?.gender ?? '--',
                    },
                  ),
                  style:
                      GoogleFonts.inter(color: Colors.grey[600], fontSize: 13)),
              const SizedBox(height: 8),
              ConsultationTypeBadge(type: appointment.type),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(title,
          style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary)),
    );
  }

  Widget _buildTextField(BuildContext context, String label, TextEditingController controller,
      {int maxLines = 1, TextInputType? keyboardType, bool readOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700])),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          readOnly: readOnly,
          decoration: InputDecoration(
            filled: true,
            fillColor: readOnly ? Colors.grey[50] : Colors.white,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildMedicationForm(BuildContext context, SubmitConsultationViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        children: [
          _buildTextField(context, context.tr('doctor.consultation.medicine_name'), viewModel.medicineNameController),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _buildTextField(context, context.tr('doctor.consultation.dosage'), viewModel.dosageController)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildTextField(
                      context,
                      context.tr('doctor.consultation.frequency'), viewModel.frequencyController)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: viewModel.addMedication,
              icon: const Icon(Icons.add, size: 18),
              label: Text(context.tr('doctor.consultation.add_medication')),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationList(SubmitConsultationViewModel viewModel,
      {bool readOnly = false}) {
    return Column(
      children: List.generate(viewModel.medications.length, (index) {
        final med = viewModel.medications[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(med['medicineName']!,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text("${med['dosage']} • ${med['frequency']}"),
          trailing: readOnly
              ? null
              : IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => viewModel.removeMedication(index)),
        );
      }),
    );
  }

  Widget _buildTestForm(BuildContext context, SubmitConsultationViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        children: [
          _buildTextField(context, context.tr('doctor.consultation.test_name'), viewModel.testNameController),
          const SizedBox(height: 12),
          _buildTextField(context, context.tr('doctor.consultation.notes'), viewModel.testNotesController),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: viewModel.addTest,
              icon: const Icon(Icons.add, size: 18),
              label: Text(context.tr('doctor.consultation.add_test')),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestList(BuildContext context, SubmitConsultationViewModel viewModel,
      {bool readOnly = false}) {
    return Column(
      children: List.generate(viewModel.tests.length, (index) {
        final test = viewModel.tests[index];
        final reportUrl = (test['reportUrl'] ?? '').trim();
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(test['testName']!,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: test['notes']!.isNotEmpty ? Text(test['notes']!) : null,
          trailing: readOnly
              ? (reportUrl.isNotEmpty
                  ? TextButton(
                      onPressed: () => _openReportUrl(context, reportUrl),
                      child: const Text('See Result'),
                    )
                  : Text(
                      'Pending',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ))
              : IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => viewModel.removeTest(index)),
        );
      }),
    );
  }

  Future<void> _openReportUrl(BuildContext context, String reportUrl) async {
    final resolved = AppUrl.getFullUrl(reportUrl);
    final uri = Uri.tryParse(resolved);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid report link')),
      );
      return;
    }

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open report')),
      );
    }
  }
}
