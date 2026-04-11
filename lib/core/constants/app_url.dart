class AppUrl {
  /// Base URL
  /// Base URL
  ///static const String baseUrl = 'https://medlink-be-production.up.railway.app';

  static const String baseUrl =
      'https://www.medlink-africa.com';
//   static const String baseUrl =
//       'http://192.168.0.101:3000'; // Emulator Magic IP (points to your machine)

  /// Common Auth Endpoints
  static const String loginEndPoint = '${baseUrl}/auth/login';
  static const String verifyOtp = '${baseUrl}/auth/verify-otp';
  static const String forgotPassword = '${baseUrl}/auth/password/forgot';
  static const String resetPassword = '${baseUrl}/auth/password/reset';
  static const String deleteAccountSendOtp =
      '${baseUrl}/auth/account/delete/send-otp';
  static const String deleteAccountVerifyOtp =
      '${baseUrl}/auth/account/delete/verify-otp';
  static const String socialLogin = '${baseUrl}/auth/social-login';

  static const String getChatMessages =
      '${baseUrl}/chat/user'; // /{recipientId}/messages
  static const String sendChatMessage =
      '${baseUrl}/chat/user'; // /{recipientId}/messages
  static const String sendSosChat = '${baseUrl}/chat/sos'; // /{sosId}/send
  static const String getAppointments = '${baseUrl}/appointments/patient';
  static const String getSosChatMessages =
      '${baseUrl}/chat/sos'; // /{sosId}/messages
  static const String sendTripChat = '${baseUrl}/chat/trip'; // /{tripId}/send
  static const String getTripChatMessages =
      '${baseUrl}/chat/trip'; // /{tripId}/messages
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
  static const String patientRegisterStep2 = verifyOtp;
  static const String patientRegisterStep3 = '${baseUrl}/auth/patient/register';
  static const String getPatientProfile = '${baseUrl}/patient/profile';
  static const String updatePatientProfile = '${baseUrl}/patient/profile';
  static const String getDoctors = '${baseUrl}/patient/doctors/available';
  static const String getDoctorsCategories =
      '${baseUrl}/patient/doctors/categories';
  static const String getDoctorsBySpecialty =
      '${baseUrl}/patient/doctors/available';
  static const String getDoctorReviewsForPatient =
      '${baseUrl}/patient/doctors'; // /{doctorId}/reviews
  static const String bookAppointments = '${baseUrl}/patient/appointments';
  static const String getBookedSlots =
      '${baseUrl}/patient/doctors'; // /{id}/booked-slots
  static const String getUpcomingAppointments =
      '${baseUrl}/patient/appointments/upcoming';
  static const String getCancelledAppointments =
      '${baseUrl}/patient/appointments/cancelled';
  static const String getPastAppointments =
      '${baseUrl}/patient/appointments/past';
  static const String getHealthArticles = '${baseUrl}/patient/health-articles';
  static const String getPatientPrescriptions =
      '${baseUrl}/patient/prescriptions';
  static const String getPrescriptionByAppointment =
      '${baseUrl}/patient/prescriptions/by-appointment'; // /{id}
  static const String patientCancelAppointment =
      '${baseUrl}/patient/appointments';
  static const String uploadTestReport =
      '${baseUrl}/patient/prescriptions'; // /{id}/tests/{testId}/report
  static const String getChatHistory =
      '${baseUrl}/chat/history/patient'; // /{patientId}/doctors
  static const String getChatConversations = '${baseUrl}/chat/conversations';
  static const String uploadImage = '${baseUrl}/upload/image';
  static const String getUnifiedChatHistory =
      '${baseUrl}/chat/history'; // /doctor/{doctorId}/patient/{patientId}
  static const String getEmergencyNumbers =
      '${baseUrl}/health-hub/emergency-numbers';
  static const String getQuickInstructions =
      '${baseUrl}/health-hub/quick-instructions';
  static const String getFirstAidTopics = '${baseUrl}/health-hub/first-aid';
  static const String getHealthVideos = '${baseUrl}/health-hub/videos';

  /// Doctor App Endpoints
  static const String doctorRegisterStep1 = '${baseUrl}/auth/doctor/send-otp';
  static const String doctorRegisterStep2 = verifyOtp;
  static const String doctorRegisterStep3 = '${baseUrl}/auth/doctor/register';
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
  static const String updateDoctorAvailability =
      '${baseUrl}/doctor/availability';
  static const String doctorAppointmentActions =
      '${baseUrl}/doctor/appointments';
  static const String getDoctorArticles = '${baseUrl}/doctor/my-articles';
  static const String uploadArticle = '${baseUrl}/doctor/articles';
  static const String getPatientProfileForDoctor =
      '${baseUrl}/doctor/patient'; // /{id}/profile
  static const String getDoctorChatHistory =
      '${baseUrl}/chat/history/doctor'; // /{doctorId}/patients
  static const String getDoctorAppointmentsHistory =
      '${baseUrl}/doctor/appointments-history'; // ?patientId={id}
  static const String getPrescriptionDetails =
      '${baseUrl}/doctor/appointments'; // /{id}/prescription-
  static const String updateDoctorPracticeSettings =
      '${baseUrl}/doctor/practice-settings';
  static const String updateDoctorAvailabilitySlots =
      '${baseUrl}/doctor/availability/slots';
  static const String doctorReviews = '${baseUrl}/doctor/reviews';
  static const String doctorPayoutAccount = '${baseUrl}/doctor/payout-account';
  static const String doctorWithdrawals = '${baseUrl}/doctor/withdrawals';
  static const String doctorWithdrawalRequest =
      '${baseUrl}/doctor/withdrawals/request';

  /// Driver App Endpoints
  static const String getDriverProfile = '${baseUrl}/driver/profile';
  static const String updateDriverStatus = '${baseUrl}/driver/status';
  static const String getDriverDashboard = '${baseUrl}/driver/dashboard';
  static const String getDriverEmergencyRequests =
      '${baseUrl}/driver/emergency-requests';
  static const String driverTrips = '${baseUrl}/driver/trips';
  static const String driverEarnings = '${baseUrl}/driver/earnings';

  /// Agora Token
  static const String getAgoraToken = '${baseUrl}/agora/token';
  static const String initiateCall = '${baseUrl}/agora/initiate-call';
  static const String checkIncomingCall = '${baseUrl}/agora/incoming-call';
  static const String callStatus = '${baseUrl}/agora/status';
  static const String updateCallStatus = '${baseUrl}/agora/update-status';

  static const String driverRegisterStep1 = '${baseUrl}/auth/driver/send-otp';
  static const String driverRegisterStep2 = verifyOtp;
  static const String driverRegisterStep3 = '${baseUrl}/auth/driver/register';
  // Note: Some driver endpoints were duplicated below, removing them to fix conflicts
  static const String getDriverEarningsSummary =
      '${baseUrl}/driver/earnings/summary';
  static const String getDriverEarningsTransactions =
      '${baseUrl}/driver/earnings/transactions';
  static const String driverReviews = '${baseUrl}/driver/reviews';
  static const String driverPayoutAccount = '${baseUrl}/driver/payout-account';
  static const String driverWithdrawals = '${baseUrl}/driver/withdrawals';
  static const String driverWithdrawalRequest =
      '${baseUrl}/driver/withdrawals/request';

  /// Patient App Endpoints
  static const String createSos = '${baseUrl}/patient/sos';
  static const String emergencyContacts =
      '${baseUrl}/patient/emergency-contacts';
  static const String patientReels = '${baseUrl}/patient/reels';
  static const String appointmentCheckout =
      '${baseUrl}/patient/appointments'; // /{id}/payment/checkout
  static const String confirmManualPayment =
      '${baseUrl}/patient/payments/confirm-manual';
  static const String reviewDoctor =
      '${baseUrl}/patient/appointments'; // /{appointmentId}/review-doctor
  static const String reviewDriver =
      '${baseUrl}/patient/trips'; // /{tripId}/review-driver
}
