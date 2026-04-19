import 'package:flutter/material.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medlink/models/appointment_model.dart';
import 'package:medlink/widgets/consultation_type_badge.dart';
import 'package:medlink/views/Patient App/consultation/video_call_view.dart';

class AppointmentDetailsEditView extends StatefulWidget {
  final AppointmentModel appointment;

  const AppointmentDetailsEditView({super.key, required this.appointment});

  @override
  State<AppointmentDetailsEditView> createState() => _AppointmentDetailsEditViewState();
}

class _AppointmentDetailsEditViewState extends State<AppointmentDetailsEditView> {
  bool _isEditing = false;

  // Controllers
  final TextEditingController _symptomsController = TextEditingController(text: "Fever, Headache, Cough");
  final TextEditingController _diagnosisController = TextEditingController(text: "Viral Influenza");
  final TextEditingController _prescriptionController = TextEditingController(text: "Paracetamol 500mg (BID) - 5 Days\nVitamin C - 1 Daily");
  final TextEditingController _notesController = TextEditingController(text: "Patient advised to rest and hydrate.");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Consultation Details",
          style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
              });
            },
            child: Text(
              _isEditing ? "Done" : "Edit",
              style: GoogleFonts.inter(
                color: _isEditing ? AppColors.primary : Colors.grey[700],
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    backgroundImage: (widget.appointment.user?.profileImage != null && widget.appointment.user!.profileImage!.isNotEmpty)
                        ? NetworkImage(widget.appointment.user!.profileImage!)
                        : null,
                    child: (widget.appointment.user?.profileImage == null || widget.appointment.user!.profileImage!.isEmpty)
                        ? const Icon(Icons.person, size: 30, color: Colors.grey)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.appointment.user?.name ?? "Unknown Patient",
                          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 6),
                        ConsultationTypeBadge(type: widget.appointment.type, compact: true),
                        const SizedBox(height: 6),
                        Text(
                          widget.appointment.status.name.toUpperCase(),
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const SizedBox(height: 24),

            // Video Call Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VideoCallView(
                        isDoctor: true,
                        appointmentId: widget.appointment.id,
                        otherPartyName: widget.appointment.user?.name,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.videocam_rounded, color: Colors.white),
                label: Text(
                  "Join Video Call",
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  shadowColor: AppColors.primary.withOpacity(0.4),
                ),
              ),
            ),
            const SizedBox(height: 24),

            _buildSectionHeader("Symptoms"),
            _buildEditableField(_symptomsController, maxLines: 2),

            const SizedBox(height: 20),

            _buildSectionHeader("Diagnosis"),
            _buildEditableField(_diagnosisController, maxLines: 2),

            const SizedBox(height: 20),

            _buildSectionHeader("Prescription"),
            _buildEditableField(_prescriptionController, maxLines: 5),

            const SizedBox(height: 20),

            _buildSectionHeader("Private Notes"),
            _buildEditableField(_notesController, maxLines: 3),

            const SizedBox(height: 40),
            if (_isEditing)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Save logic would go here
                    setState(() => _isEditing = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Changes saved successfully!")),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 5,
                    shadowColor: AppColors.primary.withOpacity(0.4),
                  ),
                  child: Text(
                    "Save Changes",
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),


          ],
        ),
      ),
    );
  }

  Widget _buildPastActivityItem(String title, String date) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Text(date, style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 12)),
            ],
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey)
        ],
      ),
    );
  }


  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey[700],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildEditableField(TextEditingController controller, {int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: _isEditing ? Border.all(color: AppColors.primary.withOpacity(0.5), width: 1.5) : Border.all(color: Colors.transparent),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        enabled: _isEditing,
        maxLines: maxLines,
        style: GoogleFonts.inter(fontSize: 15, color: AppColors.textPrimary, height: 1.5),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.all(16),
          border: InputBorder.none,
          hintText: "Enter details here...",
          hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
        ),
      ),
    );
  }
}
