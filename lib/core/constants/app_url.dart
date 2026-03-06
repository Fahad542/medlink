class AppUrl {
  /// Base URL
  // static const String baseUrl = 'https://medlink-be-production.up.railway.app';

  static const String baseUrl = 'http://192.168.100.59:3000';

  /// Auth Endpoints
  static const String register = '${baseUrl}/auth/register';
  static const String loginEndPoint = '${baseUrl}/auth/login';
  static const String checkEmail = '$register/email/step1';
  static const String verifyEmail = '$register/email/step2';

  /// Legacy Register Steps (Used in api_services.dart)
  static const String registerStep1 = '$register/step1';
  static const String registerStep2 = '$register/step2';
  static const String registerStep3 = '$register/step3';
  static const String registerStep5 = '$register/step3';

  /// Patient Register (New 3-step OTP flow)
  static const String patientRegisterStep1 = '${baseUrl}/auth/patient/send-otp';
  static const String patientRegisterStep2 =
      '${baseUrl}/auth/patient/verify-otp';
  static const String patientRegisterStep3 = '${baseUrl}/auth/patient/register';

  /// Doctor Register (New 3-step OTP flow)
  static const String doctorRegisterStep1 = '${baseUrl}/auth/doctor/send-otp';
  static const String doctorRegisterStep2 = '${baseUrl}/auth/doctor/verify-otp';
  static const String doctorRegisterStep3 = '${baseUrl}/auth/doctor/register';

  /// Patient App Endpoints
  static const String getPatientProfile = '${baseUrl}/patient/profile';
  static const String updatePatientProfile = '${baseUrl}/patient/profile';
  static const String getDoctors = '${baseUrl}/patient/doctors/available';
  static const String getDoctorsCategories =
      '${baseUrl}/patient/doctors/categories';
  static const String getDoctorsBySpecialty =
      '${baseUrl}/patient/doctors/available';
  static const String bookAppointments = '${baseUrl}/patient/appointments';
  static const String getUpcomingAppointments =
      '${baseUrl}/patient/appointments/upcoming';
  static const String getCancelledAppointments =
      '${baseUrl}/patient/appointments/cancelled';
  static const String getPastAppointments =
      '${baseUrl}/patient/appointments/past';
  static const String getHealthArticles = '${baseUrl}/patient/health-articles';

  /// Doctor App Endpoints
  static const String getDoctorProfile = '${baseUrl}/doctor/profile-details';
  static const String updateDoctorProfile = '${baseUrl}/doctor/profile-details';
  static const String getDoctorPatients = '${baseUrl}/doctor/patients';
  static const String getDoctorEarningsByMonth =
      '${baseUrl}/doctor/earnings/by-month';
  static const String getDoctorBalance = '${baseUrl}/doctor/balance';
  static const String getDoctorUpcomingAppointments =
      '${baseUrl}/doctor/appointments/upcoming';
  static const String getDoctorPastAppointments =
      '${baseUrl}/doctor/appointments/past';
  static const String getDoctorCancelledAppointments =
      '${baseUrl}/doctor/appointments/cancelled';
  static const String doctorAppointmentActions =
      '${baseUrl}/doctor/appointments'; // Will append /:id/approve or /:id/cancel dynamically

  /// Common/Appointments Endpoints
  static const String getAppointments = '${baseUrl}/appointments/patient';
  static const String patientCancelAppointment =
      '${baseUrl}/patient/appointments'; // Will append /:id/cancel dynamically

  /// Chat Endpoints
  static const String getChatMessages =
      '${baseUrl}/chat/appointments'; // /{id}/messages
  static const String sendChatMessage =
      '${baseUrl}/chat/appointments'; // /{id}/messages

  /// External Endpoints
  static const String getFirstAidTopics =
      'https://peristomatic-hecht-kynlee.ngrok-free.dev/api/content/get-first-aid-topics';

  /// Helper to get full URL for media/images
  static String getFullUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;

    // Ensure path starts with a single slash
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return '$baseUrl$cleanPath';
  }
}
