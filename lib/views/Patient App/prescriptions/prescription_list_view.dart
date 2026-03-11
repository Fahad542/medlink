import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/views/Patient App/prescriptions/prescription_view_model.dart';
import 'package:medlink/widgets/custom_app_bar_widget.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class PrescriptionListView extends StatefulWidget {
  const PrescriptionListView({super.key});

  @override
  State<PrescriptionListView> createState() => _PrescriptionListViewState();
}

class _PrescriptionListViewState extends State<PrescriptionListView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PrescriptionViewModel>(context, listen: false).fetchPrescriptions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: const CustomAppBar(title: "My Prescriptions"),
      body: Consumer<PrescriptionViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading && viewModel.prescriptions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.prescriptions.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () => viewModel.fetchPrescriptions(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: viewModel.prescriptions.length,
              itemBuilder: (context, index) {
                final prescription = viewModel.prescriptions[index];
                return _buildPrescriptionCard(prescription);
              },
            ),
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
          Icon(Icons.description_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text("No prescriptions found", style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildPrescriptionCard(dynamic p) {
    final doctor = p['doctor'] ?? {};
    final date = DateTime.parse(p['createdAt'] ?? DateTime.now().toString());
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: const Icon(Icons.medication, color: AppColors.primary),
        ),
        title: Text(doctor['fullName'] ?? "Doctor", style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(DateFormat('MMM dd, yyyy').format(date)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (p['chiefComplaint'] != null) ...[
                  const Text("Chief Complaint", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(p['chiefComplaint'], style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 12),
                ],
                const Text("Medications", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ...(p['medications'] as List? ?? []).map((m) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(m['medicineName'] ?? ""),
                  subtitle: Text("${m['dosage']} • ${m['frequency']}"),
                )),
                const SizedBox(height: 12),
                const Text("Tests", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ...(p['tests'] as List? ?? []).map((t) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(t['testName'] ?? ""),
                  trailing: t['reportUrl'] != null 
                    ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
                    : IconButton(
                        icon: const Icon(Icons.upload_file, color: AppColors.primary, size: 20),
                        onPressed: () {
                          // TODO: Implement file picking and upload
                        },
                      ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
