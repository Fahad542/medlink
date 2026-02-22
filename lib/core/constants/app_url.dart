class AppUrl {
  ///auth
  static const String baseUrl = 'https://peristomatic-hecht-kynlee.ngrok-free.dev/api/v1/';
  static const String register = baseUrl + 'auth/register/';
  static const String loginEndPint =  baseUrl + 'auth/login';
  static const String check_email = register + 'email/step1';
  static const String verify_email = register + 'email/step2';
  static const String registerstep1 =  register + 'step1';
  static const String registerstep2 = register + 'step2';
  static const String registerstep3 =  register +'step3';
  // static const String registerstep4 =  authurl + 'step4';
   static const String registerstep5 =  register + 'step3';
  // static const String registerstep6 =  authurl + 'step6';
  static const String login_google = register + 'step6';
  static const String login_apple = register + 'step7';
  static const String get_doctors = baseUrl + 'doctors';

  static const String get_doctors_categories = baseUrl + 'doctors/categories';

  //// patient App
  static const String get_appointments = baseUrl + 'appointments/patient';
  static const String book_appointments = baseUrl + 'appointments';
  static const String get_first_aid_topics = 'https://peristomatic-hecht-kynlee.ngrok-free.dev/api/content/get-first-aid-topics';

}
