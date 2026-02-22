import 'package:flutter/material.dart';
import 'package:medlink/models/user_model.dart';

class DoctorPatientDashboardViewModel extends ChangeNotifier {
  final UserModel patient;

  DoctorPatientDashboardViewModel(this.patient);

  // Example of logic extracted: 
  // Get concise name or initials
  String get patientInitials => patient.name.substring(0, 2).toUpperCase();
  
  // Checking if profile image exists
  bool get hasProfileImage => patient.profileImage != null;
  
  // Format age and gender
  String get ageGenderText => "${patient.gender ?? 'Unknown'}, ${patient.age ?? 'N/A'}";

  // Check if next appointment exists
  bool get hasNextAppointment => patient.nextAppointment != null;
}
