import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:medlink/models/doctor_model.dart';
import 'package:medlink/models/user_login_model.dart';
import 'package:medlink/views/services/session_view_model.dart';
import 'package:medlink/data/network/api_services.dart';

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
    experienceController.text = doctor.experience ?? "";
    bioController.text = doctor.about;
    clinicNameController.text = doctor.hospital;
    clinicAddressController.text = doctor.location ?? "";
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
      final response = await _apiServices.getDoctorProfile();
      if (response != null && response['success'] == true) {
        final Map<String, dynamic> data = response['data'];

        // SYNC: We must preserve the accessToken AND the role when updating the local session
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

          // Update local controllers with fresh data
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
        "yearsOfExperience": experienceController.text.trim(),
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
}
