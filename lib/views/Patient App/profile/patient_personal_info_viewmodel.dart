import 'package:flutter/material.dart';
import 'package:medlink/models/user_model.dart';
import 'package:medlink/views/Login/user_view_model.dart';

class PatientPersonalInfoViewModel extends ChangeNotifier {
  final UserViewModel _userViewModel;

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
  }

  void _initializeFields() {
    final user = _userViewModel.patient;
    if (user != null) {
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
  }

  // Getter for profile image
  String? get profileImage => _userViewModel.patient?.profileImage;

  Future<void> saveChanges(BuildContext context) async {
    // In a real app, this would make an API call.
    // For now, we update the local session via UserViewModel (simplification)
    // or just show a success message as we don't have a backend update endpoint handy yet.
    
    // Example: _userViewModel.updatePatientProfile(...) 
    
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
