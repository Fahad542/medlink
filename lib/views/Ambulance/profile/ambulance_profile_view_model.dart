import 'package:flutter/material.dart';
import 'package:medlink/data/network/api_services.dart';
import 'package:medlink/views/Login/login_view.dart';
import 'package:medlink/views/services/session_view_model.dart';
import 'package:provider/provider.dart';

class AmbulanceProfileViewModel extends ChangeNotifier {
  final ApiServices _apiServices = ApiServices();

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String _fullName = '';
  String _email = '';
  String _phone = '';
  bool _isActive = true;

  bool _isAvailable = true;
  String _vehicleType = '';
  String _vehiclePlate = '';
  String _licenseNo = '';

  String _profilePhotoUrl = '';

  // Dashboard stats
  String _rating = '0.0';
  String _totalTrips = '0';
  String _experience = '0 Yrs';

  String get driverName => _fullName.isEmpty ? '—' : _fullName;
  String get email => _email.isEmpty ? '—' : _email;
  String get phone => _phone.isEmpty ? '—' : _phone;
  String get profilePhotoUrl => _profilePhotoUrl;
  String get licensePlate => _vehiclePlate.isEmpty ? '—' : _vehiclePlate;
  String get vehicleType => _vehicleType.isEmpty ? '—' : _vehicleType;
  String get licenseNo => _licenseNo.isEmpty ? '—' : _licenseNo;
  bool get isActive => _isActive;
  bool get isAvailable => _isAvailable;

  String get rating => _rating;
  String get totalTrips => _totalTrips;
  String get experience => _experience;

  AmbulanceProfileViewModel() {
    fetchDriverProfile();
    fetchDriverDashboard();
  }

  Future<void> fetchDriverProfile() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiServices.getDriverProfile();
      if (response != null && response['success'] == true) {
        final data = response['data'];
        if (data is Map) {
          final user = data['user'];
          if (user is Map) {
            _fullName = user['fullName']?.toString() ?? '';
            _email = user['email']?.toString() ?? '';
            _phone = user['phone']?.toString() ?? '';
            _profilePhotoUrl = user['profilePhotoUrl']?.toString() ?? '';
            _isActive = user['isActive'] == true;
          }
          final driverProfile = data['driverProfile'];
          if (driverProfile is Map) {
            _isAvailable = driverProfile['isAvailable'] == true;
            _vehicleType = driverProfile['vehicleType']?.toString() ?? '';
            _vehiclePlate = driverProfile['vehiclePlate']?.toString() ?? '';
            _licenseNo = driverProfile['licenseNo']?.toString() ?? '';
            // Assuming experience comes from profile or is calculated
            // _experience = ...
          }
        }
      }
    } catch (e) {
      debugPrint('AmbulanceProfileViewModel fetchDriverProfile error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchDriverDashboard() async {
    try {
      final responses = await Future.wait([
        _apiServices.getDriverDashboard(),
        _apiServices.getDriverReviews(),
      ]);

      final dashboardResponse = responses[0];
      final reviewsResponse = responses[1];

      if (dashboardResponse != null && dashboardResponse['success'] == true) {
        final data = dashboardResponse['data'];
        if (data is Map) {
          _totalTrips = data['totalTrips']?.toString() ?? '0';
        }
      }

      if (reviewsResponse != null && reviewsResponse['success'] == true) {
        final data = reviewsResponse['data'];
        if (data is Map) {
          final avg = data['averageRating'];
          _rating = avg != null ? avg.toString() : '0.0';
        }
      }
    } catch (e) {
      debugPrint('AmbulanceProfileViewModel fetchDashboard error: $e');
    }
    notifyListeners();
  }

  Future<void> logout(BuildContext context) async {
    await Provider.of<UserViewModel>(context, listen: false).logout();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginView()),
        (route) => false,
      );
    }
  }
}
