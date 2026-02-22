import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medlink/models/user_model.dart';
import 'package:medlink/models/doctor_model.dart';
import 'package:medlink/models/ambulance_model.dart';

class UserViewModel with ChangeNotifier {
  UserModel? _patient;
  DoctorModel? _doctor;
  AmbulanceModel? _driver;
  
  String? _role;

  UserModel? get patient => _patient;
  DoctorModel? get doctor => _doctor;
  AmbulanceModel? get driver => _driver;
  String? get role => _role;

  // Load user from disk on startup
  Future<void> loadUser() async {
    final SharedPreferences sp = await SharedPreferences.getInstance();
    final String? session = sp.getString('user_session');
    
    if (session != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(session);
        _role = data['role'];
        final Map<String, dynamic> userData = data['data'];

        if (_role == 'patient') {
          _patient = UserModel.fromJson(userData);
        } else if (_role == 'doctor') {
          _doctor = DoctorModel.fromJson(userData);
        } else if (_role == 'driver') {
          _driver = AmbulanceModel.fromJson(userData);
        }
        notifyListeners();
      } catch (e) {
        print("Error loading session: $e");
        await logout(); // Corrupted data
      }
    }
  }

  Future<void> saveUser(dynamic user, String role) async {
    final SharedPreferences sp = await SharedPreferences.getInstance();
    _role = role;
    
    Map<String, dynamic> userData = {};
    if (role == 'patient' && user is UserModel) {
      _patient = user;
      userData = user.toJson();
    } else if (role == 'doctor' && user is DoctorModel) {
      _doctor = user;
      userData = user.toJson();
    } else if (role == 'driver' && user is AmbulanceModel) {
      _driver = user;
      userData = user.toJson();
    }

    final session = jsonEncode({
      'role': role,
      'data': userData,
    });
    
    await sp.setString('user_session', session);
    notifyListeners();
  }

  Future<void> logout() async {
    final SharedPreferences sp = await SharedPreferences.getInstance();
    await sp.remove('user_session');
    _patient = null;
    _doctor = null;
    _driver = null;
    _role = null;
    notifyListeners();
  }
}
