import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:medlink/data/network/api_services.dart';
import 'package:medlink/utils/utils.dart';
import 'package:medlink/views/Login/user_view_model.dart';
import 'package:medlink/models/user_model.dart';
import 'package:medlink/models/doctor_model.dart';
import 'package:medlink/models/ambulance_model.dart';
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

  String _selectedRole = 'patient';
  String get selectedRole => _selectedRole;

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

  void setSelectedRole(String role) {
    _selectedRole = role;
    notifyListeners();
  }

  Future<void> loginApi(BuildContext context) async {
    if (!formKey.currentState!.validate()) return;

    setLoading(true);

    final data = {
      if (_isEmailLogin) 'email': emailController.text.trim(),
      // if (!_isEmailLogin) 'phone_number': phoneController.text.trim(),
      'password': passwordController.text,
    };

    try {
      final response = await _apiServices.loginApi(data);
      setLoading(false);

      if (kDebugMode) {
        print("Login Response: $response");
      }

      if (response != null) {
        // Merge top-level response fields with nested data object
        final Map<String, dynamic> userData = {};
        if (response is Map<String, dynamic>) {
          userData.addAll(response);
        }
        
        final rawData = response['data'] ?? response['user'];
        if (rawData is Map<String, dynamic>) {
          userData.addAll(rawData);
        }
        
        if (userData.isEmpty) {
          Utils.toastMessage(context, "Login failed: No user data", isError: true);
          return;
        }

        // Standardize Role
        String roleToSave = _selectedRole;
        if (roleToSave == 'ambulance') roleToSave = 'driver';

        dynamic currentUser;
        if (roleToSave == 'patient') {
          currentUser = UserModel.fromJson(userData);
        } else if (roleToSave == 'doctor') {
          currentUser = DoctorModel.fromJson(userData);
        } else if (roleToSave == 'driver') {
          currentUser = AmbulanceModel.fromJson(userData);
        }

        // Persist Session
        final userVM = Provider.of<UserViewModel>(context, listen: false);
        await userVM.saveUser(currentUser, roleToSave);

        // Navigation logic based on role
        if (context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) {
              if (roleToSave == 'doctor') {
                return const DoctorMainScreen();
              } else if (roleToSave == 'driver') {
                return const AmbulanceMainView();
              }
              return const MainScreen();
            }),
            (route) => false,
          );
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

  @override
  void dispose() {
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
