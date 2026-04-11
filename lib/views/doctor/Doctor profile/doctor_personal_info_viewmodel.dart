import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:medlink/models/doctor_model.dart';
import 'package:medlink/models/user_login_model.dart';
import 'package:medlink/views/services/session_view_model.dart';
import 'package:medlink/data/network/api_services.dart';
import 'dart:async';
import 'package:medlink/services/google_maps_service.dart';

class DoctorPersonalInfoViewModel extends ChangeNotifier {
  final UserViewModel _userViewModel;
  final ApiServices _apiServices = ApiServices();
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  File? _imageFile;
  File? get imageFile => _imageFile;

  // Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController specializationController =
      TextEditingController();
  final TextEditingController experienceController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController clinicNameController = TextEditingController();
  final TextEditingController clinicAddressController = TextEditingController();

  List<dynamic> _addressSuggestions = [];
  List<dynamic> get addressSuggestions => _addressSuggestions;
  Timer? _debounce;

  DoctorPersonalInfoViewModel(this._userViewModel) {
    _initializeFields();
    fetchDoctorProfile();
  }

  void _initializeFields() {
    final doctor = _userViewModel.doctor;
    if (doctor != null) {
      _populateControllers(doctor);
    }
  }

  void _populateControllers(DoctorModel doctor) {
    nameController.text = doctor.name;
    specializationController.text = doctor.specialty;
    experienceController.text = doctor.experience;
    bioController.text = doctor.about;
    clinicNameController.text = doctor.hospital;
    clinicAddressController.text = doctor.location;
    // Note: Email and phone might need to be fetched from session or a separate profile call
    final user = _userViewModel.loginSession?.data?.user;
    if (user != null) {
      emailController.text = user.email ?? "";
      phoneController.text = user.phone ?? "";
    }
  }

  Future<void> pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 70,
    );
    if (pickedFile != null) {
      _imageFile = File(pickedFile.path);
      notifyListeners();
    }
  }

  Future<void> fetchDoctorProfile() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Fetch Profile Details
      final profileResponse = await _apiServices.getDoctorProfile();
      // 2. Fetch Practice Settings (availability, fee, duration)
      final settingsResponse = await _apiServices.getPracticeSettings();

      if (profileResponse != null && profileResponse['success'] == true) {
        Map<String, dynamic> data = profileResponse['data'];

        // Merge practice settings if available
        if (settingsResponse != null && settingsResponse['success'] == true) {
          final settingsData = settingsResponse['data'];
          data['practiceSettings'] = settingsData;
          // Flatten some common fields for easier parsing in DoctorModel
          data['consultationFee'] = settingsData['consultationFee'];
          data['sessionDurationMin'] = settingsData['sessionDurationMin'];
          data['availability'] = settingsData['days'];
        }

        if (_userViewModel.loginSession != null &&
            _userViewModel.loginSession!.data != null) {
          final currentAccessToken =
              _userViewModel.loginSession!.data!.accessToken;
          final currentRole = _userViewModel.loginSession!.data!.user?.role;

          final Map<String, dynamic> updatedUserJson = {
            ...data,
            'role': currentRole ?? 'DOCTOR',
          };

          final Map<String, dynamic> updatedSessionJson = {
            'success': true,
            'data': {
              'user': updatedUserJson,
              'access_token': currentAccessToken,
            }
          };

          final updatedLoginModel = UserLoginModel.fromJson(updatedSessionJson);
          await _userViewModel.saveUserLoginSession(updatedLoginModel);

          final updatedDoctor = DoctorModel.fromJson(updatedUserJson);
          _populateControllers(updatedDoctor);
        }
      }
    } catch (e) {
      debugPrint("Error fetching doctor profile: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String? get profileImage => _userViewModel.doctor?.imageUrl;

  Future<void> saveChanges(BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    try {
      final Map<String, String> formData = {
        "fullName": nameController.text.trim(),
        "phone": phoneController.text.trim(),
        "specialization": specializationController.text.trim(),
        // Backend expects yearsExperience (not yearsOfExperience)
        "yearsExperience": experienceController.text.trim(),
        "bio": bioController.text.trim(),
        "clinicName": clinicNameController.text.trim(),
        "clinicAddress": clinicAddressController.text.trim(),
      };

      final response =
          await _apiServices.updateDoctorProfile(formData, _imageFile);

      if (response != null && response['success'] == true) {
        await fetchDoctorProfile();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profile updated successfully")),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error updating profile: $e")),
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateAvailability({
    required Set<String> selectedDays,
    required double consultationFee,
    required double sessionDuration,
    required TimeOfDay? morningStart,
    required TimeOfDay? morningEnd,
    required TimeOfDay? eveningStart,
    required TimeOfDay? eveningEnd,
    required BuildContext context,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final Map<String, int> dayToNum = {
        "Sun": 0,
        "Mon": 1,
        "Tue": 2,
        "Wed": 3,
        "Thu": 4,
        "Fri": 5,
        "Sat": 6
      };

      String? formatTime(TimeOfDay? tod) {
        if (tod == null) return null;
        final hour = tod.hour.toString().padLeft(2, '0');
        final minute = tod.minute.toString().padLeft(2, '0');
        return "$hour:$minute";
      }

      final List<Map<String, dynamic>> daysPayload = selectedDays.map((day) {
        return {
          "dayOfWeek": dayToNum[day],
          "morningStart": formatTime(morningStart),
          "morningEnd": formatTime(morningEnd),
          "eveningStart": formatTime(eveningStart),
          "eveningEnd": formatTime(eveningEnd),
        };
      }).toList();

      final Map<String, dynamic> payload = {
        "consultationFee": consultationFee,
        "sessionDurationMin": sessionDuration.toInt(),
        "days": daysPayload,
      };

      debugPrint("UPDATING PRACTICE SETTINGS: $payload");
      final response = await _apiServices.updateDoctorPracticeSettings(payload);

      if (response != null && response['success'] == true) {
        debugPrint("AVAILABILITY UPDATE SUCCESS. FETCHING PROFILE...");
        await fetchDoctorProfile();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Availability updated successfully")),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error updating availability: $e")),
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void onAddressChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.length > 2) {
        final suggestions = await GoogleMapsService.searchPlaces(query);

        _addressSuggestions = suggestions;
        notifyListeners();
      } else {
        _addressSuggestions = [];
        notifyListeners();
      }
    });
  }

  void selectAddress(String address) {
    clinicAddressController.text = address;
    _addressSuggestions = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
