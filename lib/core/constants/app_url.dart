class AppUrl {
  ///auth
  static const String baseUrl = 'https://medlink-be-production.up.railway.app/';
  static const String register = baseUrl + 'auth/register/';
  static const String loginEndPint =  baseUrl + 'auth/login';
  static const String check_email = register + 'email/step1';
  static const String verify_email = register + 'email/step2';
  static const String registerstep1 =  register + 'step1';
  static const String registerstep2 = register + 'step2';
  static const String registerstep3 =  register +'step3';
   static const String registerstep5 =  register + 'step3';
  static const String login_google = register + 'step6';
  static const String login_apple = register + 'step7';
  static const String get_doctors = baseUrl + 'patient/doctors';
  static const String get_doctors_categories = baseUrl + 'patient/doctors/categories';
  static const String get_doctors_by_specialty = baseUrl + 'patient/doctors/available';

  //// patient App
  static const String get_patient_profile = baseUrl + 'patient/profile';
  static const String get_appointments = baseUrl + 'appointments/patient';
  static const String book_appointments = baseUrl + 'patient/appointments';
  static const String get_upcoming_appointments = baseUrl + 'patient/appointments/upcoming';
  static const String get_cancelled_appointments = baseUrl + 'patient/appointments/cancelled';
  static const String get_past_appointments = baseUrl + 'patient/appointments/past';
  static const String cancel_appointment = baseUrl + 'patient/appointments'; // Will append /:id/cancel dynamically
  static const String get_health_articles = baseUrl + 'patient/health-articles';
  static const String get_first_aid_topics = 'https://peristomatic-hecht-kynlee.ngrok-free.dev/api/content/get-first-aid-topics';

  //// Doctor App
  static const String get_doctor_patients = baseUrl + 'doctor/patients';
  static const String get_doctor_earnings_by_month = baseUrl + 'doctor/earnings/by-month';
  static const String get_doctor_balance = baseUrl + 'doctor/balance';
  static const String get_doctor_upcoming_appointments = baseUrl + 'doctor/appointments/upcoming';
}
