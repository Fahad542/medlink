import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:medlink/models/user_model.dart';
import 'package:medlink/models/user_login_model.dart';
import 'package:medlink/views/services/session_view_model.dart';
import 'package:medlink/data/network/api_services.dart';
import 'package:medlink/utils/utils.dart';

class PatientPersonalInfoViewModel extends ChangeNotifier {
  final UserViewModel _userViewModel;
  final ApiServices _apiServices = ApiServices();
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  File? _imageFile;
  File? get imageFile => _imageFile;

  // Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController genderController = TextEditingController();
  final TextEditingController bloodGroupController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController heightController = TextEditingController();

  PatientPersonalInfoViewModel(this._userViewModel) {
    _initializeFields();
    fetchPatientProfile();
  }

  void _initializeFields() {
    final user = _userViewModel.patient;
    if (user != null) {
      _populateControllers(user);
    }
  }

  void _populateControllers(UserModel user) {
    nameController.text = user.name;
    phoneController.text = user.phoneNumber;
    dobController.text = user.dateOfBirth ?? "";
    genderController.text = user.gender ?? "";
    bloodGroupController.text = user.bloodGroup ?? "";
    addressController.text = user.address ?? "";
    ageController.text = user.age?.toString() ?? "";
    weightController.text = user.weight?.toString() ?? "";
    heightController.text = user.height?.toString() ?? "";
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

  Future<void> fetchPatientProfile() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiServices.getPatientProfile();
      if (response != null && response['success'] == true) {
        final Map<String, dynamic> data = response['data'];

        // SYNC: We must preserve the accessToken AND the role when updating the local session
        if (_userViewModel.loginSession != null &&
            _userViewModel.loginSession!.data != null) {
          final currentAccessToken =
              _userViewModel.loginSession!.data!.accessToken;
          final currentRole = _userViewModel.loginSession!.data!.user?.role;

          // Prepare the updated user data
          // IMPORTANT: The backend might return 'fullName' but User model expects 'fullName'
          // and UserModel.fromJson expects 'fullName' or 'name'.
          // We ensure 'role' is preserved because the backend might not return it in the profile call.
          final previousUserId = _userViewModel.loginSession!.data!.user?.id;
          final dynamic rawId = data['id'] ?? data['_id'];
          final int? idFromResponse = rawId is int
              ? rawId
              : int.tryParse(rawId?.toString() ?? '');
          final int? mergedUserId = idFromResponse ?? previousUserId;

          final Map<String, dynamic> updatedUserJson = {
            ...data,
            'role': currentRole ?? 'PATIENT',
            if (mergedUserId != null) 'id': mergedUserId,
          };

          // Wrap in the structure UserLoginModel expects
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
          final updatedUser = UserModel.fromJson(updatedUserJson);
          _populateControllers(updatedUser);
        }
      }
    } catch (e) {
      debugPrint("Error fetching patient profile: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Getter for profile image
  String? get profileImage => _userViewModel.patient?.profileImage;

  Future<void> saveChanges(BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    try {
      final Map<String, String> formData = {
        "fullName": nameController.text.trim(),
        "phone": phoneController.text.trim(),
        "dateOfBirth": dobController.text.trim(),
        "gender": genderController.text.trim(),
        "bloodGroup": bloodGroupController.text.trim(),
        "address": addressController.text.trim(),
        "age": ageController.text.trim(),
        "weight": weightController.text.trim(),
        "height": heightController.text.trim(),
      };

      final response =
          await _apiServices.updatePatientProfile(formData, _imageFile);

      if (response != null && response['success'] == true) {
        // Fetch the updated profile to sync local state
        await fetchPatientProfile();

        if (context.mounted) {
          Utils.toastMessage(context, "Profile updated successfully");
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (context.mounted) {
        Utils.toastError(context, e);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
