class AppUrl {
  /// Base URL
  static const String baseUrl = 'https://medlink-be-production.up.railway.app';
  // static const String baseUrl = 'http://192.168.100.78:3000'; // Real IP (for physical devices)

  /// Common Auth Endpoints
  static const String loginEndPoint = '${baseUrl}/auth/login';
  static const String getAppointments = '${baseUrl}/appointments/patient';
  static const String getChatMessages = '${baseUrl}/chat/user'; // /{recipientId}/messages
  static const String sendChatMessage = '${baseUrl}/chat/user'; // /{recipientId}/messages
  static const String register = '${baseUrl}/auth/register';
  static const String registerStep1 = '$register/step1';
  static const String registerStep2 = '$register/step2';
  static const String registerStep3 = '$register/step3';
  /// Helper to get full URL for media/images
  static String getFullUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;

    // Ensure path starts with a single slash
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return '$baseUrl$cleanPath';
  }

  /// Patient App Endpoints
   static const String patientRegisterStep1 = '${baseUrl}/auth/patient/send-otp';
   static const String patientRegisterStep2 = '${baseUrl}/auth/patient/verify-otp';
   static const String patientRegisterStep3 = '${baseUrl}/auth/patient/register';
  static const String getPatientProfile = '${baseUrl}/patient/profile';
  static const String updatePatientProfile = '${baseUrl}/patient/profile';
  static const String getDoctors = '${baseUrl}/patient/doctors/available';
  static const String getDoctorsCategories = '${baseUrl}/patient/doctors/categories';
  static const String getDoctorsBySpecialty = '${baseUrl}/patient/doctors/available';
  static const String bookAppointments = '${baseUrl}/patient/appointments';
  static const String getUpcomingAppointments = '${baseUrl}/patient/appointments/upcoming';
  static const String getCancelledAppointments = '${baseUrl}/patient/appointments/cancelled';
  static const String getPastAppointments = '${baseUrl}/patient/appointments/past';
  static const String getHealthArticles = '${baseUrl}/patient/health-articles';
  static const String getPatientPrescriptions = '${baseUrl}/patient/prescriptions';
  static const String getPrescriptionByAppointment = '${baseUrl}/patient/prescriptions/by-appointment'; // /{id}
  static const String patientCancelAppointment = '${baseUrl}/patient/appointments';
  static const String uploadTestReport = '${baseUrl}/patient/prescriptions'; // /{id}/tests/{testId}/report
  static const String getChatHistory = '${baseUrl}/chat/history/patient'; // /{patientId}/doctors
  static const String getUnifiedChatHistory = '${baseUrl}/chat/history'; // /doctor/{doctorId}/patient/{patientId}
  static const String getEmergencyNumbers = '${baseUrl}/health-hub/emergency-numbers';
  static const String getQuickInstructions = '${baseUrl}/health-hub/quick-instructions';
  static const String getFirstAidTopics = '${baseUrl}/health-hub/first-aid';
  static const String getHealthVideos = '${baseUrl}/health-hub/videos';

  /// Doctor App Endpoints
  static const String doctorRegisterStep1 = '${baseUrl}/auth/doctor/send-otp';
  static const String doctorRegisterStep2 = '${baseUrl}/auth/doctor/verify-otp';
  static const String doctorRegisterStep3 = '${baseUrl}/auth/doctor/register';
  static const String getDoctorProfile = '${baseUrl}/doctor/profile-details';
  static const String updateDoctorProfile = '${baseUrl}/doctor/profile-details';
  static const String getDoctorPatients = '${baseUrl}/doctor/patients';
  static const String getDoctorEarningsByMonth = '${baseUrl}/doctor/earnings/by-month';
  static const String getDoctorBalance = '${baseUrl}/doctor/balance';
  static const String getDoctorUpcomingAppointments = '${baseUrl}/doctor/appointments/upcoming';
  static const String getDoctorPastAppointments = '${baseUrl}/doctor/appointments/past';
  static const String getDoctorCancelledAppointments = '${baseUrl}/doctor/appointments/cancelled';
  static const String updateDoctorAvailability = '${baseUrl}/doctor/availability';
  static const String doctorAppointmentActions = '${baseUrl}/doctor/appointments';
  static const String getDoctorArticles = '${baseUrl}/doctor/my-articles';
  static const String uploadArticle = '${baseUrl}/doctor/articles';
  static const String getPatientProfileForDoctor = '${baseUrl}/doctor/patient'; // /{id}/profile
  static const String getDoctorChatHistory = '${baseUrl}/chat/history/doctor'; // /{doctorId}/patients
  static const String getDoctorAppointmentsHistory = '${baseUrl}/doctor/appointments-history'; // ?patientId={id}
  static const String getPrescriptionDetails = '${baseUrl}/doctor/appointments'; // /{id}/prescription-details

}
