import 'package:flutter/material.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medlink/models/doctor_model.dart';
import 'package:medlink/widgets/custom_button.dart';
import 'package:medlink/widgets/custom_app_bar_widget.dart';
import 'package:provider/provider.dart';
import 'package:medlink/views/Patient%20App/appointment/appointment_viewmodel.dart';
import 'package:medlink/views/doctor/Doctor%20profile/doctor_profile_view_model.dart';
import 'package:intl/intl.dart';
import 'appointment_details_view.dart'; // Import Details View

class BookAppointmentView extends StatelessWidget {
  final DoctorModel doctor;

  const BookAppointmentView({super.key, required this.doctor});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => DoctorProfileViewModel(Provider.of<AppointmentViewModel>(context, listen: false)),
      child: _BookAppointmentContent(doctor: doctor),
    );
  }
}

class _BookAppointmentContent extends StatefulWidget {
  final DoctorModel doctor;
  
  const _BookAppointmentContent({required this.doctor});

  @override
  State<_BookAppointmentContent> createState() => _BookAppointmentContentState();
}

class _BookAppointmentContentState extends State<_BookAppointmentContent> {
  DateTime _focusedMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<DoctorProfileViewModel>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: const CustomAppBar(
        title: "Book Appointment",
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const SizedBox(height: 16),
            
            // Custom Calendar Widget
            _buildCalendar(viewModel),

            const SizedBox(height: 24),

            Text(
              "Select Hour",
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
            ),
            const SizedBox(height: 16),

            // Time Slots Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 2.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: viewModel.timeSlots.length,
              itemBuilder: (context, index) {
                final time = viewModel.timeSlots[index];
                final isSelected = viewModel.selectedTime == time;
                return InkWell(
                  onTap: () => viewModel.selectTime(time),
                  borderRadius: BorderRadius.circular(24),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : Colors.grey.withOpacity(0.2),
                      ),
                    ),
                    child: Text(
                      time,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500, // Unbolded
                        color: isSelected ? Colors.white : Colors.grey[600],
                      ),
                    ),
                  ),
                );
              },
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
                offset: const Offset(0,-5)
              )
            ]
        ),
        child: SafeArea( // Ensure button is safe from bottom gestures
          child: SizedBox(
              width: double.infinity,
              child: CustomButton(
                  text: "Confirm Appointment",
                  onPressed: () {
                    if (viewModel.selectedTime == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please select a time slot")),
                      );
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AppointmentDetailsView(
                          doctor: widget.doctor,
                          selectedDate: viewModel.selectedDate,
                          selectedTime: viewModel.selectedTime!,
                        ),
                      ),
                    );
                  }
              ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalendar(DoctorProfileViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08), // Light theme shade
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
           BoxShadow(
             color: Colors.black.withOpacity(0.03),
             blurRadius: 15,
             offset: const Offset(0, 5),
           )
        ]
      ),
      child: Column(
        children: [
          // Header (Month Year + Arrows)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Text(
                 DateFormat('MMMM yyyy').format(_focusedMonth),
                 style: GoogleFonts.inter(
                   fontSize: 16,
                   fontWeight: FontWeight.bold,
                   color: const Color(0xFF1E293B),
                 ),
               ),
               Row(
                 children: [
                   IconButton(
                     onPressed: () {
                       setState(() {
                         _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
                       });
                     },
                     icon: Icon(Icons.chevron_left_rounded, color: Colors.grey[600]),
                     padding: EdgeInsets.zero,
                     constraints: const BoxConstraints(),
                   ),
                   const SizedBox(width: 16),
                   IconButton(
                     onPressed: () {
                       setState(() {
                         _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
                       });
                     },
                     icon: Icon(Icons.chevron_right_rounded, color: Colors.grey[600]),
                     padding: EdgeInsets.zero,
                     constraints: const BoxConstraints(),
                   ),
                 ],
               )
            ],
          ),
          const SizedBox(height: 20),
          
          // Days Header (Sun, Mon...)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"].map((day) {
               return SizedBox(
                 width: 35,
                 child: Text(
                   day, 
                   textAlign: TextAlign.center,
                   style: GoogleFonts.inter(
                     fontSize: 12,
                     color: Colors.grey[700],
                     fontWeight: FontWeight.w500
                   )
                 ),
               );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Days Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 42, // 6 rows * 7 cols to be safe
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              // Calendar Logic
              final firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
              final dayOffset = firstDayOfMonth.weekday % 7; // 0 for Sunday
              
              final int dayNumber = index - dayOffset + 1;
              final int daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;

              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const SizedBox();
              }
              
              final currentDate = DateTime(_focusedMonth.year, _focusedMonth.month, dayNumber);
              final isSelected = DateUtils.isSameDay(viewModel.selectedDate, currentDate);
              final isToday = DateUtils.isSameDay(DateTime.now(), currentDate);

              return InkWell(
                onTap: () {
                  viewModel.selectDate(currentDate);
                },
                borderRadius: BorderRadius.circular(10), // Circle or rounded square
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    shape: BoxShape.circle,
                    border: isToday && !isSelected ? Border.all(color: AppColors.primary, width: 1.5) : null,
                  ),
                  child: Text(
                    "$dayNumber",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.grey[800],
                    ),
                  ),
                ),
              );
            },
          )

        ],
      ),
    );
  }
}
