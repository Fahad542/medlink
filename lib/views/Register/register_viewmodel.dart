import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:medlink/models/user_model.dart';
import 'package:medlink/models/doctor_model.dart';
import 'package:medlink/models/ambulance_model.dart';
import 'package:medlink/data/network/api_services.dart';
import 'package:medlink/utils/utils.dart';
import 'package:medlink/views/services/session_view_model.dart';
import 'package:provider/provider.dart';

enum UserRole { patient, doctor, driver }

class RegisterViewModel extends ChangeNotifier {
  final _apiServices = ApiServices();

  UserRole _role = UserRole.patient;
  UserRole get role => _role;

  bool _loading = false;
  bool get loading => _loading;

  bool _resendLoading = false;
  bool get resendLoading => _resendLoading;

  bool _emailLoading = false;
  bool get emailLoading => _emailLoading;

  String? _tempUserId;
  String? get tempUserId => _tempUserId;

  int _currentStep = 0;
  int get currentStep => _currentStep;

  int get totalSteps {
    switch (_role) {
      case UserRole.patient: return 6;
      case UserRole.doctor: return 6;
      case UserRole.driver: return 5;
    }
  }

  final PageController pageController = PageController();

  // --- Common Controllers ---
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController emailOtpController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  // --- Patient Controllers ---
  final TextEditingController emergencyNameController = TextEditingController();
  final TextEditingController emergencyPhoneController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController bloodGroupController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  String? selectedGender;
  DateTime? selectedDob;

  // --- Doctor Controllers ---
  final TextEditingController specializationController = TextEditingController();
  final TextEditingController experienceController = TextEditingController();
  final TextEditingController clinicNameController = TextEditingController();
  final TextEditingController clinicAddressController = TextEditingController();
  final TextEditingController aboutController = TextEditingController();
  final TextEditingController consultationFeeController = TextEditingController();
  String? licensePath;
  List<String> availabilityDays = [];
  TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay endTime = const TimeOfDay(hour: 17, minute: 0);

  // --- Driver Controllers ---
  final TextEditingController carNumberController = TextEditingController();
  final TextEditingController carNameController = TextEditingController();
  String? driverLicensePath;

  // --- Shared Media ---
  String? profileImagePath;

  void initRole(UserRole initialRole) {
    _role = initialRole;
    reset();
  }

  void setRole(UserRole newRole) {
    _role = newRole;
    notifyListeners();
  }

  void setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  void setResendLoading(bool value) {
    _resendLoading = value;
    notifyListeners();
  }

  void setEmailLoading(bool value) {
    _emailLoading = value;
    notifyListeners();
  }

  void reset() {
    _currentStep = 0;
    if (pageController.hasClients) {
      pageController.jumpToPage(0);
    }
    nameController.clear();
    emailController.clear();
    emailOtpController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
    phoneController.clear();
    emergencyNameController.clear();
    emergencyPhoneController.clear();
    ageController.clear();
    weightController.clear();
    heightController.clear();
    bloodGroupController.clear();
    dobController.clear();
    
    specializationController.clear();
    experienceController.clear();
    clinicNameController.clear();
    clinicAddressController.clear();
    aboutController.clear();
    consultationFeeController.clear();
    
    carNumberController.clear();
    carNameController.clear();

    selectedGender = null;
    selectedDob = null;
    profileImagePath = null;
    licensePath = null;
    driverLicensePath = null;
    
    availabilityDays = [];
    startTime = const TimeOfDay(hour: 9, minute: 0);
    endTime = const TimeOfDay(hour: 17, minute: 0);
    
    _tempUserId = null;
    notifyListeners();
  }

  void nextStep() {
    if (_currentStep < totalSteps - 1) {
      if (pageController.hasClients) {
        pageController.animateToPage(
          _currentStep + 1,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
        );
      }
      _currentStep++;
      notifyListeners();
    }
  }

  void previousStep(BuildContext context) {
    if (_currentStep > 0) {
      if (pageController.hasClients) {
        pageController.previousPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
        );
      }
      _currentStep--;
      notifyListeners();
    } else {
      Navigator.pop(context);
    }
  }

  void setStep(int step) {
    _currentStep = step;
    if (pageController.hasClients) {
      pageController.animateToPage(
        step,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
    notifyListeners();
  }

  // --- Setters ---
  void setGender(String? gender) { selectedGender = gender; notifyListeners(); }
  void setDob(DateTime? dob) { selectedDob = dob; notifyListeners(); }
  void setProfileImage(String? path) { profileImagePath = path; notifyListeners(); }
  void setLicensePath(String? path) { licensePath = path; notifyListeners(); }
  void setDriverLicensePath(String? path) { driverLicensePath = path; notifyListeners(); }
  void setAvailability(List<String> days) { availabilityDays = days; notifyListeners(); }
  void setTimes(TimeOfDay start, TimeOfDay end) { startTime = start; endTime = end; notifyListeners(); }

  Future<void> submitStep4(BuildContext context) async {
    // Validation
    if (selectedGender == null) {
      Utils.toastMessage(context, "Please select gender", isError: true);
      return;
    }
    if (selectedDob == null) {
      Utils.toastMessage(context, "Please select date of birth", isError: true);
      return;
    }
    if (ageController.text.isEmpty || weightController.text.isEmpty || heightController.text.isEmpty) {
        Utils.toastMessage(context, "Please fill all required fields", isError: true);
        return;
    }
    nextStep();
  }

  Future<void> submitStep5(BuildContext context) async {
    if (emergencyNameController.text.isEmpty) {
      Utils.toastMessage(context, "Please enter contact name", isError: true);
      return;
    }
    if (emergencyPhoneController.text.length < 10) {
      Utils.toastMessage(context, "Invalid phone number", isError: true);
      return;
    }
    nextStep();
  }

  Future<void> submitStep1(BuildContext context) async {
    if (_role == UserRole.patient) {
      final v1StepData = {
        "fullName": nameController.text,
        "phoneNumber": phoneController.text,
        "password": passwordController.text,
        "role": "patient",
      };
      if (await registerV1Step(v1StepData, context)) {
        nextStep();
      }
    } else {
      // Doctor & Driver
      final step2Data = {
        "phone_number": phoneController.text,
      };
      if (await registerStep2(step2Data, context)) {
        nextStep();
      }
    }
  }

  Future<bool> submitStep2Otp(String otp, BuildContext context) async {
    final data = {
      "phoneNumber": phoneController.text,
      "otp_code": otp,
    };
    
    bool otpSuccess = false;
    if (_role == UserRole.patient) {
      otpSuccess = await verifyOtpStep(data, context);
    } else {
      // Doctor / Driver use RegisterStep3 for OTP verify API 
      // (which we separated to registerStep3WithoutFile in viewmodel)
      otpSuccess = await registerStep3WithoutFile(data, context);
    }
    return otpSuccess;
  }

  Future<void> resendOtp(BuildContext context) async {
    if (_role == UserRole.patient) {
      final v1StepData = {
        "fullName": nameController.text,
        "phoneNumber": phoneController.text,
        "password": passwordController.text,
        "role": "patient",
      };
      await registerV1Step(v1StepData, context, isResend: true);
    } else {
      final data = {
        "phone_number": phoneController.text,
      };
      await registerStep2(data, context, isResend: true);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    emailOtpController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    phoneController.dispose();
    emergencyNameController.dispose();
    emergencyPhoneController.dispose();
    ageController.dispose();
    weightController.dispose();
    heightController.dispose();
    bloodGroupController.dispose();
    dobController.dispose();
    specializationController.dispose();
    experienceController.dispose();
    clinicNameController.dispose();
    clinicAddressController.dispose();
    aboutController.dispose();
    consultationFeeController.dispose();
    carNumberController.dispose();
    carNameController.dispose();
    pageController.dispose();
    super.dispose();
  }

  // --- API Methods ---

  Future<bool> registerV1Step(dynamic data, BuildContext context, {bool isResend = false}) async {
    if (isResend) setResendLoading(true); else setLoading(true);

    try {
      final value = await _apiServices.registerV1Step(data);
      if (isResend) setResendLoading(false); else setLoading(false);

      if (kDebugMode) print("v1/step Response: $value");

      _tempUserId = value['user_id']?.toString();
      Utils.toastMessage(context, value['message'] ?? 'Registration started successfully');
      return true;
    } catch (error, stack) {
      if (isResend) setResendLoading(false); else setLoading(false);
      if (kDebugMode) print("Error in v1/step: ${stack.toString()}");
      Utils.toastMessage(context, error.toString(), isError: true);
      return false;
    }
  }

  Future<bool> registerStep2(dynamic data, BuildContext context, {bool isResend = false}) async {
    if (isResend) setResendLoading(true); else setLoading(true);

    try {
      Map<String, dynamic> payload = Map.from(data);
      // if (_tempUserId != null && !payload.containsKey('user_id')) {
      //   payload['user_id'] = _tempUserId;
      // }
      
      final value = await _apiServices.registerStep2(payload);
      if (isResend) setResendLoading(false); else setLoading(false);
      
      if (kDebugMode) print("Step 2 Data: $value");
      Utils.toastMessage(context, value['message'] ?? (isResend ? 'Code sent' : 'Step 2 successful'));
      return true;
    } catch (error, stack) {
      if (isResend) setResendLoading(false); else setLoading(false);
      if (kDebugMode) print("Error: ${stack.toString()}");
      Utils.toastMessage(context, error.toString(), isError: true);
      return false;
    }
  }

  Future<bool> verifyOtpStep(dynamic data, BuildContext context) async {
    setLoading(true);
    try {
      Map<String, dynamic> payload = Map.from(data);
      if (_tempUserId != null) {
        payload['user_id'] = _tempUserId;
      }
      final value = await _apiServices.registerStep2(payload);
      setLoading(false);
      Utils.toastMessage(context, value['message'] ?? 'OTP Verified successfully');
      return true;
    } catch (error, stack) {
      setLoading(false);
      if (kDebugMode) print("Error: ${stack.toString()}");
      Utils.toastMessage(context, error.toString(), isError: true);
      return false;
    }
  }

  Future<bool> registerStep3(dynamic data, BuildContext context, File? file) async {
    setLoading(true);
    try {
      final payload = {
        "fullName": nameController.text.trim(),
        "email": emailController.text.trim(),
        "password": passwordController.text,
        "role": _role.name,
        "phoneNumber": phoneController.text.trim(),
        if (_role == UserRole.patient) ...{
          "gender": selectedGender ?? "Male",
          "dob": selectedDob != null 
              ? "${selectedDob!.year}-${selectedDob!.month.toString().padLeft(2, '0')}-${selectedDob!.day.toString().padLeft(2, '0')}" 
              : "2026-02-12",
          "age": int.tryParse(ageController.text) ?? 12,
          "weight": double.tryParse(weightController.text) ?? 12.3,
          "height": double.tryParse(heightController.text) ?? 34.5,
          "blood_group": bloodGroupController.text.isEmpty ? "A+" : bloodGroupController.text,
          "emergency_contact_name": emergencyNameController.text.isEmpty ? "Contact" : emergencyNameController.text,
          "emergency_contact_phone": emergencyPhoneController.text.isEmpty ? "0000000000" : emergencyPhoneController.text,
        },
        ...(data ?? {}),
      };

      if (kDebugMode) print("Final Register Step 3 Payload: $payload");

      final value = await _apiServices.registerStep3(payload, file); // Uses old step3 that expects file for patient
      setLoading(false);
      
      Utils.toastMessage(context, value['message'] ?? 'Profile completed successfully');
      return true;
    } catch (error, stack) {
      setLoading(false);
      if (kDebugMode) print("Error: ${stack.toString()}");
      Utils.toastMessage(context, error.toString(), isError: true);
      return false;
    }
  }
  
  Future<bool> registerStep3WithoutFile(dynamic data, BuildContext context) async {
    setLoading(true);
    try {
      Map<String, dynamic> payload = Map.from(data);
      if (_tempUserId != null) payload['user_id'] = _tempUserId;

      final value = await _apiServices.registerStep3(payload); 
      setLoading(false);
      if (kDebugMode) print("Step 3 Data: $value");

      Utils.toastMessage(context, value['message'] ?? 'OTP Verified');
      return true;
    } catch (error, stack) {
      setLoading(false);
      if (kDebugMode) print("Step 3 Error: $stack");
      Utils.toastMessage(context, error.toString(), isError: true);
      return false;
    }
  }

  Future<bool> requestEmailOtp(String email, BuildContext context) async {
    setEmailLoading(true);
    try {
      final data = {'email': email};
      final value = await _apiServices.checkEmail(data);
      setEmailLoading(false);
      Utils.toastMessage(context, value['message'] ?? 'OTP sent to email');
      return true;
    } catch (e) {
      setEmailLoading(false);
      Utils.toastMessage(context, e.toString(), isError: true);
      return false;
    }
  }

  Future<bool> submitEmailOtp(String email, String otp, BuildContext context) async {
    setEmailLoading(true);
    try {
      final data = {
        'email': email,
        'otp_code': otp,
      };
      
      final value = await _apiServices.verifyEmailOtp(data);
      setEmailLoading(false);
      Utils.toastMessage(context, value['message'] ?? 'Email verified successfully');
      return true;
    } catch (e) {
      setEmailLoading(false);
      Utils.toastMessage(context, e.toString(), isError: true);
      return false;
    }
  }
  
  // --- Setup Validation ---
  
  void finishPatientSetup(BuildContext context) {
    final userVM = Provider.of<UserViewModel>(context, listen: false);
    final newUser = UserModel(
      id: _tempUserId ?? 'new_user',
      name: nameController.text,
      phoneNumber: phoneController.text,
      profileImage: profileImagePath,
      gender: selectedGender,
      age: int.tryParse(ageController.text),
      weight: double.tryParse(weightController.text),
      height: double.tryParse(heightController.text),
      bloodGroup: bloodGroupController.text,
      dateOfBirth: selectedDob?.toString().split(" ")[0],
      emergencyContactName: emergencyNameController.text,
      emergencyContactPhone: emergencyPhoneController.text,
    );
    userVM.saveUser(newUser, 'patient');
    // We don't handle navigation here, to keep ViewModel clean, 
    // it will be handled by the View's Setup Step
  }

  void finishDoctorSetup(BuildContext context) {
    final userVM = Provider.of<UserViewModel>(context, listen: false);
    final newDoctor = DoctorModel(
      id: _tempUserId ?? 'new_doctor',
      name: nameController.text,
      specialty: specializationController.text,
      hospital: clinicNameController.text,
      rating: 5.0,
      imageUrl: profileImagePath ?? '',
      isAvailable: true,
      consultationFee: double.tryParse(consultationFeeController.text) ?? 0.0,
      about: aboutController.text,
      experience: experienceController.text,
      location: clinicAddressController.text,
    );
    userVM.saveUser(newDoctor, 'doctor');
  }

  void finishDriverSetup(BuildContext context) {
    final userVM = Provider.of<UserViewModel>(context, listen: false);
    final newDriver = AmbulanceModel(
      id: _tempUserId ?? 'new_driver',
      driverName: nameController.text,
      plateNumber: carNumberController.text,
      currentLat: 0.0,
      currentLng: 0.0,
      vehicleType: carNameController.text,
      status: "Idle",
      estimatedArrival: "20 min",
    );
    userVM.saveUser(newDriver, 'driver');
  }
}
