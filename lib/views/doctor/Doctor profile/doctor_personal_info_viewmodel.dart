import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:medlink/core/constants/app_url.dart';
import 'package:medlink/models/doctor_model.dart';
import 'package:medlink/models/user_login_model.dart';
import 'package:medlink/views/services/session_view_model.dart';
import 'package:medlink/data/network/api_services.dart';
import 'package:medlink/services/google_maps_service.dart';
import 'package:medlink/utils/utils.dart';

class DoctorPersonalInfoViewModel extends ChangeNotifier {
  final UserViewModel _userViewModel;
  final ApiServices _apiServices = ApiServices();
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  double _minimumDoctorConsultationFee = 500;
  double get minimumDoctorConsultationFee => _minimumDoctorConsultationFee;

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

  Timer? _addressDebounce;
  final List<Map<String, dynamic>> _addressSuggestions = [];
  List<Map<String, dynamic>> get addressSuggestions =>
      List.unmodifiable(_addressSuggestions);

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

  /// Backend returns either `{ success, data }` or the practice DTO directly
  /// (`consultationFee`, `sessionDurationMin`, `days`).
  static bool _practiceSettingsPayloadLooksValid(dynamic response) {
    if (response == null || response is! Map) return false;
    final m = Map<String, dynamic>.from(response);
    if (m['success'] == true) return true;
    return m.containsKey('days') ||
        m.containsKey('consultationFee') ||
        m.containsKey('sessionDurationMin');
  }

  static Map<String, dynamic>? _extractPracticeSettingsMap(dynamic response) {
    if (response == null || response is! Map) return null;
    final m = Map<String, dynamic>.from(response);
    if (m['success'] == true && m['data'] != null && m['data'] is Map) {
      return Map<String, dynamic>.from(m['data'] as Map);
    }
    if (_practiceSettingsPayloadLooksValid(m) &&
        (m.containsKey('days') || m.containsKey('consultationFee'))) {
      return m;
    }
    return null;
  }

  Future<void> fetchDoctorProfile() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _refreshMinimumConsultationFeeFromOrg();

      // 1. Fetch Profile Details
      final profileResponse = await _apiServices.getDoctorProfile();
      // 2. Fetch Practice Settings (availability, fee, duration)
      final settingsResponse = await _apiServices.getPracticeSettings();

      if (profileResponse != null && profileResponse['success'] == true) {
        Map<String, dynamic> data = profileResponse['data'];

        // Merge practice settings if available
        final settingsMap = _extractPracticeSettingsMap(settingsResponse);
        if (settingsMap != null) {
          data['practiceSettings'] = settingsMap;
          data['consultationFee'] = settingsMap['consultationFee'];
          data['sessionDurationMin'] = settingsMap['sessionDurationMin'];
          data['availability'] = settingsMap['days'];
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

  Future<void> _refreshMinimumConsultationFeeFromOrg() async {
    final v = await _apiServices.getOrganizationMinimumConsultationFee(
      AppUrl.defaultOrganizationIdForFeeRules,
    );
    if (v != null && v > 0) {
      _minimumDoctorConsultationFee = v;
    } else {
      _minimumDoctorConsultationFee = 500;
    }
  }

  /// Call before validating fee (e.g. when opening Availability sheet).
  Future<void> refreshConsultationFeeRulesFromBackend() async {
    await _refreshMinimumConsultationFeeFromOrg();
    notifyListeners();
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
          Utils.toastMessage(context, 'Profile updated successfully');
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (context.mounted) {
        Utils.toastMessage(context, Utils.apiErrorMessage(e), isError: true);
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
    if (consultationFee <= 0) {
      if (context.mounted) {
        Utils.toastMessage(
          context,
          'Please enter a valid consultation fee',
          isError: true,
        );
      }
      return;
    }
    if (consultationFee < minimumDoctorConsultationFee) {
      if (context.mounted) {
        Utils.toastMessage(
          context,
          'Consultation fee must be at least '
          '${minimumDoctorConsultationFee.toStringAsFixed(0)}',
          isError: true,
        );
      }
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final Map<String, int> dayToNum = {
        "Sun": 0, "Mon": 1, "Tue": 2, "Wed": 3, "Thu": 4, "Fri": 5, "Sat": 6
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

      final ok = _practiceSettingsPayloadLooksValid(response);
      if (ok) {
        debugPrint("AVAILABILITY UPDATE SUCCESS. FETCHING PROFILE...");
        await fetchDoctorProfile();
        if (context.mounted) {
          Utils.toastMessage(context, 'Availability updated successfully');
          Navigator.pop(context);
        }
      } else {
        final msg = response is Map
            ? response['message']?.toString()
            : null;
        if (context.mounted) {
          Utils.toastMessage(
            context,
            msg?.isNotEmpty == true
                ? msg!
                : 'Could not update availability. Please try again.',
            isError: true,
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Utils.toastMessage(context, Utils.apiErrorMessage(e), isError: true);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void onAddressChanged(String query) {
    if (_addressDebounce?.isActive ?? false) _addressDebounce!.cancel();
    _addressDebounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.trim().length > 2) {
        final raw = await GoogleMapsService.searchPlaces(query);
        _addressSuggestions.clear();
        for (final p in raw) {
          if (p is Map) {
            final m = Map<String, dynamic>.from(p);
            final desc = m['description']?.toString();
            if (desc != null && desc.isNotEmpty) {
              _addressSuggestions.add(m);
            }
          }
        }
      } else {
        _addressSuggestions.clear();
      }
      notifyListeners();
    });
  }

  void selectAddress(String description) {
    clinicAddressController.text = description;
    _addressSuggestions.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _addressDebounce?.cancel();
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    specializationController.dispose();
    experienceController.dispose();
    bioController.dispose();
    clinicNameController.dispose();
    clinicAddressController.dispose();
    super.dispose();
  }
}
