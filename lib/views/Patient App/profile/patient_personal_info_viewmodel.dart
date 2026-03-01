import 'package:flutter/material.dart';
import 'package:medlink/models/user_model.dart';
import 'package:medlink/views/services/session_view_model.dart';
import 'package:medlink/data/network/api_services.dart';

class PatientPersonalInfoViewModel extends ChangeNotifier {
  final UserViewModel _userViewModel;
  final ApiServices _apiServices = ApiServices();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

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

  Future<void> fetchPatientProfile() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await _apiServices.getPatientProfile();
      if (response != null && response['success'] == true) {
        final Map<String, dynamic> data = response['data'];
        final updatedUser = UserModel.fromJson(data);
        
        // Populate fields with latest data
        _populateControllers(updatedUser);
      }
    } catch (e) {
      print("Error fetching patient profile: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Getter for profile image
  String? get profileImage => _userViewModel.patient?.profileImage;

  Future<void> saveChanges(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile updated successfully (Local Session Only)")),
    );
    Navigator.pop(context);
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    dobController.dispose();
    genderController.dispose();
    bloodGroupController.dispose();
    addressController.dispose();
    ageController.dispose();
    weightController.dispose();
    heightController.dispose();
    super.dispose();
  }
}
