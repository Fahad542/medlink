import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/core/constants/app_url.dart';
import 'package:medlink/widgets/custom_app_bar_widget.dart';
import 'package:medlink/widgets/no_data_widget.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:medlink/views/Patient App/prescriptions/prescription_view_model.dart';
import 'package:medlink/widgets/prescription_list_shimmer.dart';

class PrescriptionView extends StatefulWidget {
  const PrescriptionView({super.key});

  @override
  State<PrescriptionView> createState() => _PrescriptionViewState();
}

class _PrescriptionViewState extends State<PrescriptionView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PrescriptionViewModel>(context, listen: false)
          .fetchPrescriptions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: const CustomAppBar(title: "E-Prescriptions"),
      body: Consumer<PrescriptionViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading && vm.prescriptions.isEmpty) {
            return const PrescriptionListShimmer(itemCount: 4);
          }

          if (vm.prescriptions.isEmpty) {
            return const Center(
              child: NoDataWidget(
                title: "No Prescriptions Found",
                subTitle: "You don't have any generic e-prescriptions.",
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => vm.fetchPrescriptions(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: vm.prescriptions.length,
              itemBuilder: (context, index) {
                final p = vm.prescriptions[index];
                return _buildPrescriptionCard(context, p);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildPrescriptionCard(BuildContext context, dynamic p) {
    final doctor = p['doctor'] as Map? ?? {};
    final diagnosis = p['diagnosis'] ?? 'N/A';
    final testsPending = (p['testsPending'] ?? 0) as int;
    final createdAt = p['createdAt'] != null ? DateTime.tryParse(p['createdAt']) : null;
    final doctorName = doctor['fullName'] ?? 'Doctor';
    final specialty = doctor['specialty'] ?? '';
    final photoUrl = AppUrl.getFullUrl(doctor['profilePhotoUrl']?.toString());
    final hasPendingTests = testsPending > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () => _onViewTapped(context, p, doctor),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildAvatar(photoUrl, doctorName),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Dr. $doctorName",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (specialty.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            specialty,
                            style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500),
                          ),
                        ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.medication_outlined, size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              diagnosis,
                              style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (hasPendingTests)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline_rounded, size: 14, color: Colors.orange[700]),
                              const SizedBox(width: 4),
                              Text(
                                "Action: Submit Report",
                                style: TextStyle(fontSize: 11, color: Colors.orange[700], fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (createdAt != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 12, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('dd MMM yyyy').format(createdAt),
                            style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => _onViewTapped(context, p, doctor),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          "View",
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String photoUrl, String name) {
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'D';
    final fallback = Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary),
        ),
      ),
    );

    if (photoUrl.isEmpty) return fallback;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.network(
        photoUrl,
        width: 46,
        height: 46,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(14)),
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Called when View button is tapped — fetches full detail via API
  Future<void> _onViewTapped(BuildContext context, dynamic p, Map doctor) async {
    final appointmentId = p['appointmentId']?.toString();
    if (appointmentId == null) return;

    final vm = Provider.of<PrescriptionViewModel>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final apiDetail = await vm.getPrescriptionDetail(appointmentId);

    if (!context.mounted) return;
    Navigator.of(context).pop(); // dismiss loading

    // Merge: list item data (p) + API detail response
    // p has: diagnosis, doctor, appointment, testsPending, testsCount
    // apiDetail has: medications, tests, notes, chiefComplaint etc.
    final Map<String, dynamic> merged = {
      ...Map<String, dynamic>.from(p as Map),
      if (apiDetail != null) ...apiDetail,
    };

    _showPrescriptionDetail(context, merged, doctor);
  }


  /// Upload test report — opens picker, calls API, refreshes prescriptions
  Future<void> _uploadTestReport(BuildContext ctx, String prescriptionId, String testId) async {
    // Show picker source options
    final source = await showModalBottomSheet<ImageSource>(
      context: ctx,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text("Choose from Gallery"),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text("Take a Photo"),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null || !ctx.mounted) return;

    final picked = await ImagePicker().pickImage(source: source, imageQuality: 85);
    if (picked == null || !ctx.mounted) return;

    final file = File(picked.path);

    // Show loading
    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final vm = Provider.of<PrescriptionViewModel>(ctx, listen: false);
    final success = await vm.uploadReport(prescriptionId, testId, file, ctx);

    if (!ctx.mounted) return;
    Navigator.of(ctx).pop(); // dismiss loader

    if (success) {
      Navigator.of(ctx).pop(); // close bottom sheet
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text("Report uploaded successfully ✓"), backgroundColor: Color(0xFF00897B)),
      );
    }
  }

  void _showPrescriptionDetail(

    BuildContext context,
    Map<String, dynamic> detail,
    Map doctor,
  ) {
    // API returns: detail = appointment object
    // detail['prescription'] = { diagnosis, notes, items[], tests[] }
    // detail['doctor'] = { fullName, profilePhotoUrl, doctorSpecialties[{specialty:{name}}] }
    // detail['vitals'] = { weightKg, bpSystolic, bpDiastolic, heartRate, temperature }
    // detail['consulKind'], detail['scheduledStart'], detail['reason']

    final prescription = detail['prescription'] as Map? ?? {};

    // Prescription fields
    final diagnosis = prescription['diagnosis'] ?? detail['diagnosis'] ?? 'N/A';
    final notes = prescription['notes']?.toString() ?? detail['notes']?.toString();
    final medications = prescription['items'] as List? ?? prescription['medications'] as List? ?? [];
    final tests = prescription['tests'] as List? ?? [];

    // Tests count from list item (p) — reliable counts
    final testsPending = (detail['testsPending'] ?? 0) as int;
    final testsCount = (detail['testsCount'] ?? 0) as int;

    // Reason / chief complaint
    final reason = detail['reason']?.toString();

    // Vitals
    final vitals = detail['vitals'] as Map?;

    // Doctor — from API detail (has doctorSpecialties) or fallback to list doctor
    final detailDoctor = detail['doctor'] as Map? ?? doctor;
    final doctorName = detailDoctor['fullName'] ?? doctor['fullName'] ?? 'Doctor';

    // Specialty: API returns doctorSpecialties[{specialty:{name}}]
    String specialty = doctor['specialty']?.toString() ?? '';
    final specialties = detailDoctor['doctorSpecialties'] as List?;
    if (specialties != null && specialties.isNotEmpty) {
      specialty = specialties[0]['specialty']?['name']?.toString() ?? specialty;
    }

    final photoUrl = AppUrl.getFullUrl(
        (detailDoctor['profilePhotoUrl'] ?? doctor['profilePhotoUrl'])?.toString());

    // Appointment date + type from top-level detail (not nested appointment)
    final scheduledStart = detail['scheduledStart'] != null
        ? DateTime.tryParse(detail['scheduledStart'])
        : (detail['appointment']?['scheduledStart'] != null
            ? DateTime.tryParse(detail['appointment']['scheduledStart'])
            : null);
    final consultKind = detail['consulKind'] ?? detail['appointment']?['consulKind'] ?? '';




    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Stack(
        alignment: Alignment.bottomCenter,
        children: [
          GestureDetector(onTap: () => Navigator.pop(ctx), child: Container(color: Colors.transparent)),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Close button
              Padding(
                padding: const EdgeInsets.only(right: 30, bottom: 16),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    onTap: () => Navigator.pop(ctx),
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: const Icon(Icons.close, size: 20, color: Colors.black87),
                    ),
                  ),
                ),
              ),

              // Receipt Card — scrollable
              Container(
                width: MediaQuery.of(ctx).size.width * 0.92,
                constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.75),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Header ──
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.primary.withOpacity(0.15), AppColors.primary.withOpacity(0.05)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                                ),
                                child: photoUrl.isEmpty
                                    ? CircleAvatar(
                                        radius: 24,
                                        backgroundColor: AppColors.primary.withOpacity(0.12),
                                        child: Text(
                                          doctorName.isNotEmpty ? doctorName[0].toUpperCase() : 'D',
                                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                        ),
                                      )
                                    : ClipOval(
                                        child: Image.network(
                                          photoUrl, width: 48, height: 48, fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => CircleAvatar(
                                            radius: 24,
                                            backgroundColor: AppColors.primary.withOpacity(0.12),
                                            child: Text(
                                              doctorName.isNotEmpty ? doctorName[0].toUpperCase() : 'D',
                                              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Dr. $doctorName", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                    if (specialty.isNotEmpty) Text(specialty, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                                    if (scheduledStart != null)
                                      Text(
                                        DateFormat('MMM dd, yyyy • hh:mm a').format(scheduledStart.toLocal()),
                                        style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                                      ),
                                  ],
                                ),
                              ),
                              if (consultKind.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(consultKind, style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600)),
                                ),
                            ],
                          ),
                        ),

                        // ── Body ──
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Reason for Visit
                              if (reason != null && reason.isNotEmpty) ...[
                                _buildSectionTitle("Reason for Visit"),
                                const SizedBox(height: 6),
                                Text(reason, style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF475569))),
                                const SizedBox(height: 16),
                                _buildDashedLine(),
                                const SizedBox(height: 16),
                              ],

                              // Diagnosis
                              _buildSectionTitle("Diagnosis"),
                              const SizedBox(height: 6),
                              Text(diagnosis, style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF475569))),

                              // Vitals
                              if (vitals != null) ...[
                                const SizedBox(height: 16),
                                _buildDashedLine(),
                                const SizedBox(height: 16),
                                _buildSectionTitle("Vitals"),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8F9FA),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Column(
                                    children: [
                                      if (vitals['bpSystolic'] != null && vitals['bpDiastolic'] != null)
                                        _buildVitalRow("Blood Pressure", "${vitals['bpSystolic']}/${vitals['bpDiastolic']} mmHg"),
                                      if (vitals['heartRate'] != null)
                                        _buildVitalRow("Heart Rate", "${vitals['heartRate']} bpm"),
                                      if (vitals['weightKg'] != null)
                                        _buildVitalRow("Weight", "${vitals['weightKg']} kg"),
                                      if (vitals['temperature'] != null)
                                        _buildVitalRow("Temperature", "${vitals['temperature']} °C", isLast: true),
                                    ],
                                  ),
                                ),
                              ],

                              // Medications
                              if (medications.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                _buildDashedLine(),
                                const SizedBox(height: 16),
                                _buildSectionTitle("Medications"),
                                const SizedBox(height: 12),
                                ...medications.map((med) {
                                  final name = med['medicineName'] ?? med['name'] ?? '';
                                  final dosage = med['dosage'] ?? '';
                                  final frequency = med['frequency'] ?? '';
                                  final duration = med['duration']?.toString() ?? '';
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FFFE),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                                          child: const Icon(Icons.medication_outlined, size: 16, color: AppColors.primary),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                              if (dosage.isNotEmpty || frequency.isNotEmpty)
                                                Text(
                                                  [if (dosage.isNotEmpty) dosage, if (frequency.isNotEmpty) frequency].join(' • '),
                                                  style: const TextStyle(fontSize: 11, color: Color(0xFF00897B), fontWeight: FontWeight.w500),
                                                ),
                                              if (duration.isNotEmpty)
                                                Text("Duration: $duration", style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],

                              // Tests — show individual list if available, else summary
                              if (tests.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                _buildDashedLine(),
                                const SizedBox(height: 16),
                                _buildSectionTitle("Tests Required"),
                                const SizedBox(height: 12),
                                ...tests.map((test) {
                                  final testName = test['testName'] ?? test['name'] ?? test['test'] ?? '';
                                  final hasReport = test['reportUrl'] != null || test['reportId'] != null;
                                  final prescriptionId = (prescription['id'] ?? '').toString();
                                  final testId = (test['id'] ?? '').toString();
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(testName, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B), fontWeight: FontWeight.w500)),
                                        ),
                                        const SizedBox(width: 12),
                                        if (hasReport)
                                          const Icon(Icons.check_circle, size: 20, color: Color(0xFF00897B))
                                        else
                                          SizedBox(
                                            height: 32,
                                            child: OutlinedButton.icon(
                                              onPressed: () => _uploadTestReport(
                                                ctx,
                                                prescriptionId,
                                                testId,
                                              ),
                                              icon: const Icon(Icons.upload_rounded, size: 14),
                                              label: const Text("Upload"),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: AppColors.primary,
                                                side: const BorderSide(color: AppColors.primary),
                                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                                textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                                visualDensity: VisualDensity.compact,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                }),
                              ] else if (testsCount > 0) ...[
                                // Fallback: show summary when API doesn't return test list
                                const SizedBox(height: 16),
                                _buildDashedLine(),
                                const SizedBox(height: 16),
                                _buildSectionTitle("Tests Required"),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: testsPending > 0 ? const Color(0xFFFFF8E7) : const Color(0xFFECFDF5),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        testsPending > 0 ? Icons.science_outlined : Icons.check_circle_outline,
                                        size: 20,
                                        color: testsPending > 0 ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          testsPending > 0
                                              ? "$testsPending of $testsCount test(s) pending — upload required"
                                              : "All $testsCount test report(s) uploaded ✓",
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: testsPending > 0 ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],


                              // Doctor's Notes
                              if (notes != null && notes.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                _buildDashedLine(),
                                const SizedBox(height: 16),
                                _buildSectionTitle("Doctor's Notes"),
                                const SizedBox(height: 6),
                                Text(notes, style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF475569))),
                              ],

                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ActionCircleButton(
                      icon: Icons.download_rounded,
                      label: "Download",
                      onTap: () {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text("Downloading PDF..."), backgroundColor: Colors.teal),
                        );
                      },
                    ),
                    const SizedBox(width: 32),
                    _ActionCircleButton(icon: Icons.share_outlined, label: "Share", onTap: () {}),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 6, height: 6,
          decoration: const BoxDecoration(color: Color(0xFF00BFA5), shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
      ],
    );
  }

  Widget _buildVitalRow(String label, String value, {bool isLast = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, color: Colors.grey.shade200),
      ],
    );
  }

  Widget _buildDashedLine() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 4.0;
        const dashHeight = 1.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          direction: Axis.horizontal,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth, height: dashHeight,
              child: DecoratedBox(decoration: BoxDecoration(color: Colors.grey[300])),
            );
          }),
        );
      },
    );
  }
}

class _ActionCircleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionCircleButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: Colors.white, shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Icon(icon, color: const Color(0xFF1E293B), size: 20),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.grey[600])),
      ],
    );
  }
}
