import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:medlink/data/network/api_services.dart';
import 'package:medlink/services/social_auth_service.dart';
import 'package:medlink/utils/utils.dart';
import 'package:medlink/views/services/session_view_model.dart';
import 'package:medlink/models/user_login_model.dart';
import 'package:provider/provider.dart';
import 'package:medlink/views/main/main_screen.dart';
import 'package:medlink/views/doctor/doctor_main_screen.dart';
import 'package:medlink/views/Ambulance/Ambulance main/ambulance_main_view.dart';

class LoginViewModel with ChangeNotifier {
  final _apiServices = ApiServices();

  bool _loading = false;
  bool get loading => _loading;

  bool _signUpLoading = false;
  bool get signUpLoading => _signUpLoading;

  // --- UI State ---
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool get obscurePassword => _obscurePassword;

  bool _isEmailLogin = false;
  bool get isEmailLogin => _isEmailLogin;

  void setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  void setSignUpLoading(bool value) {
    _signUpLoading = value;
    notifyListeners();
  }

  void toggleObscurePassword() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void toggleLoginType(bool value) {
    _isEmailLogin = value;
    notifyListeners();
  }

  Future<void> loginApi(BuildContext context) async {
    if (!formKey.currentState!.validate()) return;

    setLoading(true);

    final data = {
      if (_isEmailLogin) 'email': emailController.text.trim(),
      if (!_isEmailLogin) 'phone': phoneController.text.trim(),
      'password': passwordController.text,
    };

    try {
      final response = await _apiServices.loginApi(data);
      setLoading(false);

      if (kDebugMode) {
        print("Login Response: $response");
      }

      if (response != null) {
        final loginModel = UserLoginModel.fromJson(response);

        if (loginModel.success == true && loginModel.data != null) {
          final userVM = Provider.of<UserViewModel>(context, listen: false);
          await userVM.saveUserLoginSession(loginModel);

          // Get the role from the API response (API may return DRIVER/driver/ambulance), or fallback to selected role
          String roleToSave =
              loginModel.data?.user?.role?.toString().toLowerCase() ??
                  'patient';
          if (roleToSave == 'ambulance') roleToSave = 'driver';

          // Navigation logic based on role
          if (context.mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) {
                if (roleToSave == 'doctor') {
                  return const DoctorMainScreen();
                }
                if (roleToSave == 'patient') {
                  return const MainScreen();
                }
                if (roleToSave == 'driver') {
                  return const AmbulanceMainView();
                }
                return const MainScreen();
              }),
              (route) => false,
            );
          }
        } else {
          Utils.toastMessage(context, "Login failed: No user data",
              isError: true);
        }
      }
    } catch (e) {
      setLoading(false);
      if (kDebugMode) {
        print("Login Error: $e");
      }
      Utils.toastMessage(context, e.toString(), isError: true);
    }
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    setLoading(true);
    try {
      final google = await SocialAuthService.signInWithGoogle();
      if (!context.mounted) return;
      if (google == null) {
        setLoading(false);
        return;
      }

      const roleUpper = 'PATIENT';
      final response = await _apiServices.socialLogin(
        provider: 'google',
        providerUserId: google.providerUserId,
        role: roleUpper,
        email: google.email,
        fullName: google.fullName,
        phone: '',
      );

      if (!context.mounted) return;
      setLoading(false);

      if (response is! Map) {
        Utils.toastMessage(context, 'Invalid response from server', isError: true);
        return;
      }

      final loginModel =
          UserLoginModel.fromJson(Map<String, dynamic>.from(response as Map));
      if (loginModel.success == true && loginModel.data != null) {
        final userVM = Provider.of<UserViewModel>(context, listen: false);
        await userVM.saveUserLoginSession(loginModel);

        String roleToSave =
            loginModel.data?.user?.role?.toString().toLowerCase() ??
                'patient';
        if (roleToSave == 'ambulance') roleToSave = 'driver';

        if (context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) {
              if (roleToSave == 'doctor') return const DoctorMainScreen();
              if (roleToSave == 'patient') return const MainScreen();
              if (roleToSave == 'driver') return const AmbulanceMainView();
              return const MainScreen();
            }),
            (route) => false,
          );
        }
      } else {
        final msg = response['message']?.toString() ?? 'Google sign-in failed';
        Utils.toastMessage(context, msg, isError: true);
      }
    } catch (e) {
      setLoading(false);
      if (context.mounted) {
        Utils.toastMessage(context, e.toString(), isError: true);
      }
    }
  }

  Future<void> signInWithApple(BuildContext context) async {
    setLoading(true);
    try {
      final apple = await SocialAppleAuth.signInWithApple();
      if (!context.mounted) return;
      if (apple == null) {
        setLoading(false);
        return;
      }

      const roleUpper = 'PATIENT';
      final response = await _apiServices.socialLogin(
        provider: 'apple',
        providerUserId: apple.providerUserId,
        role: roleUpper,
        email: apple.email,
        fullName: apple.fullName,
        phone: '',
      );

      if (!context.mounted) return;
      setLoading(false);

      if (response is! Map) {
        Utils.toastMessage(context, 'Invalid response from server',
            isError: true);
        return;
      }

      final loginModel =
          UserLoginModel.fromJson(Map<String, dynamic>.from(response as Map));
      if (loginModel.success == true && loginModel.data != null) {
        final userVM = Provider.of<UserViewModel>(context, listen: false);
        await userVM.saveUserLoginSession(loginModel);

        String roleToSave =
            loginModel.data?.user?.role?.toString().toLowerCase() ??
                'patient';
        if (roleToSave == 'ambulance') roleToSave = 'driver';

        if (context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) {
              if (roleToSave == 'doctor') return const DoctorMainScreen();
              if (roleToSave == 'patient') return const MainScreen();
              if (roleToSave == 'driver') return const AmbulanceMainView();
              return const MainScreen();
            }),
            (route) => false,
          );
        }
      } else {
        final msg =
            response['message']?.toString() ?? 'Apple sign-in failed';
        Utils.toastMessage(context, msg, isError: true);
      }
    } catch (e) {
      setLoading(false);
      if (context.mounted) {
        Utils.toastMessage(context, e.toString(), isError: true);
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
