import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medlink/models/user_model.dart';
import 'package:medlink/models/doctor_model.dart';
import 'package:medlink/models/ambulance_model.dart';
import 'package:medlink/models/user_login_model.dart';

/// Manages user session and auth token. Persists to SharedPreferences so the user
/// stays logged in after closing the app until they log out.
class UserViewModel with ChangeNotifier {
  UserModel? _patient;
  DoctorModel? _doctor;
  AmbulanceModel? _driver;
  UserLoginModel? _loginSession;

  String? _role;
  String? _accessToken;

  UserModel? get patient => _patient;
  DoctorModel? get doctor => _doctor;
  AmbulanceModel? get driver => _driver;
  UserLoginModel? get loginSession => _loginSession;
  String? get role => _role;
  String? get accessToken => _accessToken;

  // Load user from disk on startup
  Future<void> loadUser() async {
    final SharedPreferences sp = await SharedPreferences.getInstance();

    final String? sessionStr = sp.getString('user_session_v2');
    if (sessionStr != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(sessionStr);
        _loginSession = UserLoginModel.fromJson(data);
        _accessToken = _loginSession?.data?.accessToken;

        // Print token on app startup
        print("====== APP STARTUP TOKEN ======");
        print(_accessToken);
        print("===============================");

        _role = _loginSession?.data?.user?.role?.toLowerCase();

        if (_role == 'ambulance') {
          _role = 'driver'; // Standardize the role internally
        }

        final userJson = _loginSession?.data?.user?.toJson() ?? {};
        if (_role == 'patient') {
          _patient = UserModel.fromJson(userJson);
        } else if (_role == 'doctor') {
          _doctor = DoctorModel.fromJson(userJson);
        } else if (_role == 'driver') {
          _driver = AmbulanceModel.fromJson(userJson);
        }
        notifyListeners();
      } catch (e) {
        print("Error loading session: $e");
        await logout(); // Corrupted data
      }
    }
  }

  Future<void> saveUserLoginSession(UserLoginModel sessionModel) async {
    final SharedPreferences sp = await SharedPreferences.getInstance();

    _loginSession = sessionModel;
    _accessToken = sessionModel.data?.accessToken;
    _role = sessionModel.data?.user?.role?.toLowerCase();

    if (_role == 'ambulance') _role = 'driver';

    final userJson = sessionModel.data?.user?.toJson() ?? {};
    if (_role == 'patient') {
      _patient = UserModel.fromJson(userJson);
    } else if (_role == 'doctor') {
      _doctor = DoctorModel.fromJson(userJson);
    } else if (_role == 'driver') {
      _driver = AmbulanceModel.fromJson(userJson);
    }

    await sp.setString('user_session_v2', jsonEncode(sessionModel.toJson()));
    notifyListeners();
  }

  Future<void> saveUser(dynamic user, String role,
      {String? accessToken}) async {
    final SharedPreferences sp = await SharedPreferences.getInstance();

    _role = role.toLowerCase();
    if (_role == 'ambulance') _role = 'driver';

    if (accessToken != null) {
      _accessToken = accessToken;
    }

    Map<String, dynamic> userJson = {};
    if (_role == 'patient' && user is UserModel) {
      _patient = user;
      userJson = user.toJson();
    } else if (_role == 'doctor' && user is DoctorModel) {
      _doctor = user;
      userJson = user.toJson();
    } else if (_role == 'driver' && user is AmbulanceModel) {
      _driver = user;
      userJson = user.toJson();
    }

    // Wrap everything in UserLoginModel format for consistency
    final loginModel = UserLoginModel(
      success: true,
      data: Data(
        accessToken: _accessToken,
        user: User.fromJson(userJson),
      ),
    );

    _loginSession = loginModel;
    await sp.setString('user_session_v2', jsonEncode(loginModel.toJson()));
    notifyListeners();
  }

  void updatePatient(UserModel updatedPatient) {
    _patient = updatedPatient;
    notifyListeners();
    // We intentionally don't do a full disk write here immediately to keep it fast,
    // or we could update the v2 session model. Since it's fetched on tab open,
    // memory update is sufficient.
  }

  Future<void> logout() async {
    final SharedPreferences sp = await SharedPreferences.getInstance();
    await sp.remove('user_session');
    await sp.remove('user_session_v2');
    _loginSession = null;
    _patient = null;
    _doctor = null;
    _driver = null;
    _role = null;
    _accessToken = null;
    notifyListeners();
  }
}
