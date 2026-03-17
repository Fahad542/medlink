import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:medlink/core/theme/app_theme.dart';
import 'package:medlink/views/Register/register_viewmodel.dart';
import 'package:medlink/views/Patient%20App/home/home_viewmodel.dart';
import 'package:medlink/views/Patient%20App/emergency/emergency_viewmodel.dart';
import 'package:medlink/views/Patient%20App/prescription/doctor_viewmodel.dart';
import 'package:medlink/views/Patient%20App/appointment/appointment_viewmodel.dart';
import 'package:medlink/views/Patient%20App/profile/profile_viewmodel.dart';
import 'package:medlink/views/services/session_view_model.dart';
import 'package:medlink/views/main/main_screen.dart';
import 'package:medlink/views/doctor/doctor_main_screen.dart';
import 'package:medlink/views/Ambulance/Ambulance%20main/ambulance_main_view.dart';
import 'package:medlink/views/Patient%20App/health/health_hub_viewmodel.dart';
import 'package:medlink/views/Login/login_view_model.dart';
import 'package:medlink/views/Login/login_view.dart';
import 'package:medlink/views/Onboarding/splash_view.dart';
import 'package:medlink/views/doctor/doctor_appointments_view_model.dart';
import 'package:medlink/views/doctor/Doctor%20patients/doctor_patients_view_model.dart';
import 'package:medlink/views/doctor/Dashboard/doctor_dashboard_view_model.dart';
import 'package:medlink/views/Patient App/prescriptions/prescription_view_model.dart';
import 'package:medlink/views/call/call_view_model.dart';
// import 'package:medlink/views/home/home_view.dart'; // Removed direct access

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:medlink/services/notification_services.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    NotificationServices notificationServices = NotificationServices();
    notificationServices.requestNotificationPermission();
    notificationServices.firebaseInit();
    notificationServices.getDeviceToken().then((value) {
      if (kDebugMode) {
        print("Device Token: $value");
      }
    });
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const MedLinkApp());
}

class MedLinkApp extends StatelessWidget {
  const MedLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RegisterViewModel()),
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
        ChangeNotifierProvider(create: (_) => EmergencyViewModel()),
        ChangeNotifierProvider(create: (_) => DoctorViewModel()),
        ChangeNotifierProvider(create: (_) => AppointmentViewModel()),
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
        ChangeNotifierProvider(
            create: (_) => UserViewModel()), // Session Management
        ChangeNotifierProvider(create: (_) => LoginViewModel()),
        ChangeNotifierProvider(create: (_) => HealthHubViewModel()),
        ChangeNotifierProvider(create: (_) => DoctorAppointmentsViewModel()),
        ChangeNotifierProvider(create: (_) => DoctorPatientsViewModel()),
        ChangeNotifierProvider(create: (_) => PrescriptionViewModel()),
        ChangeNotifierProvider(create: (_) => DoctorDashboardViewModel()),
        ChangeNotifierProvider(create: (_) => CallViewModel()),
      ],
      child: MaterialApp(
        title: 'MedLink Africa',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        // Start with Splash Screen
        home: const SplashView(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Basic auth check using the global user state
    final userViewModel = Provider.of<UserViewModel>(context);

    if (userViewModel.patient != null) {
      return const MainScreen();
    } else if (userViewModel.doctor != null) {
      return const DoctorMainScreen();
    } else if (userViewModel.driver != null) {
      return const AmbulanceMainView();
    }

    return const LoginView();
  }
}
