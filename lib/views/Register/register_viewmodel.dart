import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:medlink/models/user_login_model.dart';
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

  String? _debugOtp;
  String? get debugOtp => _debugOtp;

  int _currentStep = 0;
  int get currentStep => _currentStep;

  int get totalSteps {
    switch (_role) {
      case UserRole.patient:
        return 6;
      case UserRole.doctor:
        return 6;
      case UserRole.driver:
        return 5;
    }
  }

  final PageController pageController = PageController();

  // --- Common Controllers ---
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController emailOtpController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  // --- Patient Controllers ---
  final TextEditingController emergencyNameController = TextEditingController();
  final TextEditingController emergencyPhoneController =
      TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController bloodGroupController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  String? selectedGender;
  DateTime? selectedDob;

  // --- Doctor Controllers ---
  final TextEditingController specializationController =
      TextEditingController();
  final TextEditingController experienceController = TextEditingController();
  final TextEditingController clinicNameController = TextEditingController();
  final TextEditingController clinicAddressController = TextEditingController();
  final TextEditingController aboutController = TextEditingController();
  final TextEditingController consultationFeeController =
      TextEditingController();
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
    _debugOtp = null;
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
  void setGender(String? gender) {
    selectedGender = gender;
    notifyListeners();
  }

  void setDob(DateTime? dob) {
    selectedDob = dob;
    notifyListeners();
  }

  void setProfileImage(String? path) {
    profileImagePath = path;
    notifyListeners();
  }

  void setLicensePath(String? path) {
    licensePath = path;
    notifyListeners();
  }

  void setDriverLicensePath(String? path) {
    driverLicensePath = path;
    notifyListeners();
  }

  void setAvailability(List<String> days) {
    availabilityDays = days;
    notifyListeners();
  }

  void setTimes(TimeOfDay start, TimeOfDay end) {
    startTime = start;
    endTime = end;
    notifyListeners();
  }

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
    if (ageController.text.isEmpty ||
        weightController.text.isEmpty ||
        heightController.text.isEmpty) {
      Utils.toastMessage(context, "Please fill all required fields",
          isError: true);
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
      // New patient 3-step API: Step 1 send OTP (phone only)
      setLoading(true);
      try {
        final phone = phoneController.text.trim();
        final value = await _apiServices.patientSendOtp(phone);
        setLoading(false);
        final data = value is Map ? value['data'] : null;
        if (data is Map && data.containsKey('otp')) {
          _debugOtp = data['otp'].toString();
          notifyListeners();
        }
        final message = (data is Map ? data['message'] : null) ??
            value['message'] ??
            'OTP sent to your phone';
        Utils.toastMessage(context, message.toString());
        nextStep();
      } catch (error, stack) {
        setLoading(false);
        if (kDebugMode) print("patientSendOtp error: $stack");
        Utils.toastMessage(context, error.toString(), isError: true);
      }
    } else if (_role == UserRole.doctor) {
      // Doctor 3-step API: Step 1 send OTP (phone only)
      setLoading(true);
      try {
        final phone = phoneController.text.trim();
        final value = await _apiServices.doctorSendOtp(phone);
        setLoading(false);
        final data = value is Map ? value['data'] : null;
        if (data is Map && data.containsKey('otp')) {
          _debugOtp = data['otp'].toString();
          notifyListeners();
        }
        final message = (data is Map ? data['message'] : null) ??
            value['message'] ??
            'OTP sent to your phone';
        Utils.toastMessage(context, message.toString());
        nextStep();
      } catch (error, stack) {
        setLoading(false);
        if (kDebugMode) print("doctorSendOtp error: $stack");
        Utils.toastMessage(context, error.toString(), isError: true);
      }
    } else {
      // Driver
      final step2Data = {"phone_number": phoneController.text};
      if (await registerStep2(step2Data, context)) {
        nextStep();
      }
    }
  }

  Future<bool> submitStep2Otp(String otp, BuildContext context) async {
    if (_role == UserRole.patient) {
      // New patient 3-step API: Step 2 verify OTP (stores register_token in SharedPreferences)
      setLoading(true);
      try {
        final phone = phoneController.text.trim();
        final value = await _apiServices.patientVerifyOtp(phone, otp);
        setLoading(false);
        final data = value is Map ? value['data'] : null;
        final message = (data is Map ? data['message'] : null) ??
            value['message'] ??
            'OTP verified';
        Utils.toastMessage(context, message.toString());
        return true;
      } catch (error, stack) {
        setLoading(false);
        if (kDebugMode) print("patientVerifyOtp error: $stack");
        Utils.toastMessage(context, error.toString(), isError: true);
        return false;
      }
    }
    if (_role == UserRole.doctor) {
      setLoading(true);
      try {
        final phone = phoneController.text.trim();
        final value = await _apiServices.doctorVerifyOtp(phone, otp);
        setLoading(false);
        final data = value is Map ? value['data'] : null;
        final message = (data is Map ? data['message'] : null) ??
            value['message'] ??
            'OTP verified';
        Utils.toastMessage(context, message.toString());
        return true;
      } catch (error, stack) {
        setLoading(false);
        if (kDebugMode) print("doctorVerifyOtp error: $stack");
        Utils.toastMessage(context, error.toString(), isError: true);
        return false;
      }
    }
    final data = {
      "phoneNumber": phoneController.text,
      "otp_code": otp,
    };
    return await registerStep3WithoutFile(data, context);
  }

  Future<void> resendOtp(BuildContext context) async {
    if (_role == UserRole.patient) {
      setResendLoading(true);
      try {
        final phone = phoneController.text.trim();
        await _apiServices.patientSendOtp(phone);
        setResendLoading(false);
        Utils.toastMessage(context, 'OTP sent to your phone');
      } catch (error, stack) {
        setResendLoading(false);
        if (kDebugMode) print("patientSendOtp resend error: $stack");
        Utils.toastMessage(context, error.toString(), isError: true);
      }
    } else if (_role == UserRole.doctor) {
      setResendLoading(true);
      try {
        final phone = phoneController.text.trim();
        await _apiServices.doctorSendOtp(phone);
        setResendLoading(false);
        Utils.toastMessage(context, 'OTP sent to your phone');
      } catch (error, stack) {
        setResendLoading(false);
        if (kDebugMode) print("doctorSendOtp resend error: $stack");
        Utils.toastMessage(context, error.toString(), isError: true);
      }
    } else {
      final data = {"phone_number": phoneController.text};
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

  // --- Doctor Methods ---
  Future<void> submitDoctorStep4(BuildContext context) async {
    if (specializationController.text.isEmpty) {
      Utils.toastMessage(context, "Please enter specialization", isError: true);
      return;
    }
    if (experienceController.text.isEmpty) {
      Utils.toastMessage(context, "Please enter experience", isError: true);
      return;
    }
    if (clinicNameController.text.isEmpty) {
      Utils.toastMessage(context, "Please enter clinic name", isError: true);
      return;
    }
    if (licensePath == null) {
      Utils.toastMessage(context, "Please upload medical license",
          isError: true);
      return;
    }
    nextStep();
  }

  Future<void> submitDoctorStep5(BuildContext context) async {
    if (consultationFeeController.text.isEmpty) {
      Utils.toastMessage(context, "Please enter consultation fee",
          isError: true);
      return;
    }
    if (availabilityDays.isEmpty) {
      Utils.toastMessage(context, "Please select at least one available day",
          isError: true);
      return;
    }
    nextStep();
  }

  // --- API Methods ---

  Future<bool> registerV1Step(dynamic data, BuildContext context,
      {bool isResend = false}) async {
    if (isResend)
      setResendLoading(true);
    else
      setLoading(true);

    try {
      final value = await _apiServices.registerV1Step(data);
      if (isResend)
        setResendLoading(false);
      else
        setLoading(false);

      if (kDebugMode) print("v1/step Response: $value");

      _tempUserId = value['user_id']?.toString();
      Utils.toastMessage(
          context, value['message'] ?? 'Registration started successfully');
      return true;
    } catch (error, stack) {
      if (isResend)
        setResendLoading(false);
      else
        setLoading(false);
      if (kDebugMode) print("Error in v1/step: ${stack.toString()}");
      Utils.toastMessage(context, error.toString(), isError: true);
      return false;
    }
  }

  Future<bool> registerStep2(dynamic data, BuildContext context,
      {bool isResend = false}) async {
    if (isResend)
      setResendLoading(true);
    else
      setLoading(true);

    try {
      Map<String, dynamic> payload = Map.from(data);
      // if (_tempUserId != null && !payload.containsKey('user_id')) {
      //   payload['user_id'] = _tempUserId;
      // }

      final value = await _apiServices.registerStep2(payload);
      if (isResend)
        setResendLoading(false);
      else
        setLoading(false);

      if (kDebugMode) print("Step 2 Data: $value");
      Utils.toastMessage(context,
          value['message'] ?? (isResend ? 'Code sent' : 'Step 2 successful'));
      return true;
    } catch (error, stack) {
      if (isResend)
        setResendLoading(false);
      else
        setLoading(false);
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
      Utils.toastMessage(
          context, value['message'] ?? 'OTP Verified successfully');
      return true;
    } catch (error, stack) {
      setLoading(false);
      if (kDebugMode) print("Error: ${stack.toString()}");
      Utils.toastMessage(context, error.toString(), isError: true);
      return false;
    }
  }

  Future<bool> registerStep3(
      dynamic data, BuildContext context, File? file) async {
    if (_role != UserRole.patient) {
      // Doctor/Driver: keep existing flow
      return await _registerStep3Legacy(data, context, file);
    }

    // Patient: new 3-step API - Step 3 register (form-data + Bearer register_token)
    setLoading(true);
    try {
      final dobStr = selectedDob != null
          ? "${selectedDob!.year}-${selectedDob!.month.toString().padLeft(2, '0')}-${selectedDob!.day.toString().padLeft(2, '0')}"
          : "";
      final formData = <String, String>{
        "fullName": nameController.text.trim(),
        "email": emailController.text.trim(),
        "phone": phoneController.text.trim(),
        "password": passwordController.text,
        "gender": selectedGender ?? "Male",
        "dob": dobStr.isNotEmpty ? dobStr : "1990-01-01",
        "weight": weightController.text.trim().isNotEmpty
            ? weightController.text.trim()
            : "70",
        "bloodGroup": bloodGroupController.text.trim().isNotEmpty
            ? bloodGroupController.text.trim()
            : "B+",
        // Backend may require these; send placeholder when empty to avoid 500
        "emergencyFullName": emergencyNameController.text.trim().isNotEmpty
            ? emergencyNameController.text.trim()
            : "Not provided",
        "emergencyContactNumber":
            emergencyPhoneController.text.trim().isNotEmpty
                ? emergencyPhoneController.text.trim()
                : "0000000000",
      };

      if (kDebugMode) {
        print("patientRegister formData keys: ${formData.keys.toList()}");
        print("patientRegister hasFile: ${file != null}");
      }

      final value = await _apiServices.patientRegister(formData, file);
      setLoading(false);

      final data = value is Map ? value['data'] : null;
      final accessToken = data is Map ? data['access_token']?.toString() : null;
      final userData = data is Map ? data['user'] : null;

      if (accessToken != null && userData is Map<String, dynamic>) {
        final userVM = Provider.of<UserViewModel>(context, listen: false);
        // Persist session in SharedPreferences (same format as login) so user stays logged in after app close
        final loginModel = UserLoginModel(
          success: true,
          data: Data(
            user: User.fromJson(userData),
            accessToken: accessToken,
          ),
        );
        await userVM.saveUserLoginSession(loginModel);
      }

      Utils.toastMessage(context, 'Registration completed successfully');
      return true;
    } catch (error, stack) {
      setLoading(false);
      if (kDebugMode) print("patientRegister error: $stack");
      Utils.toastMessage(context, error.toString(), isError: true);
      return false;
    }
  }

  Future<bool> _registerStep3Legacy(
      dynamic data, BuildContext context, File? file) async {
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
          "blood_group": bloodGroupController.text.isEmpty
              ? "A+"
              : bloodGroupController.text,
          "emergency_contact_name": emergencyNameController.text.isEmpty
              ? "Contact"
              : emergencyNameController.text,
          "emergency_contact_phone": emergencyPhoneController.text.isEmpty
              ? "0000000000"
              : emergencyPhoneController.text,
        },
        ...(data ?? {}),
      };

      if (kDebugMode) print("Final Register Step 3 Payload: $payload");

      final value = await _apiServices.registerStep3(payload, file);
      setLoading(false);
      Utils.toastMessage(
          context, value['message'] ?? 'Profile completed successfully');
      return true;
    } catch (error, stack) {
      setLoading(false);
      if (kDebugMode) print("Error: ${stack.toString()}");
      Utils.toastMessage(context, error.toString(), isError: true);
      return false;
    }
  }

  Future<bool> registerStep3WithoutFile(
      dynamic data, BuildContext context) async {
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

  Future<bool> submitEmailOtp(
      String email, String otp, BuildContext context) async {
    setEmailLoading(true);
    try {
      final data = {
        'email': email,
        'otp_code': otp,
      };

      final value = await _apiServices.verifyEmailOtp(data);
      setEmailLoading(false);
      Utils.toastMessage(
          context, value['message'] ?? 'Email verified successfully');
      return true;
    } catch (e) {
      setEmailLoading(false);
      Utils.toastMessage(context, e.toString(), isError: true);
      return false;
    }
  }

  /// Doctor 3-step API: Step 3 register. Call after Step 6 (avatar) with profile + license files.
  Future<bool> doctorRegisterStep3(BuildContext context) async {
    setLoading(true);
    try {
      final startStr =
          '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
      final endStr =
          '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
      const dayToNum = {
        'Sun': 0,
        'Mon': 1,
        'Tue': 2,
        'Wed': 3,
        'Thu': 4,
        'Fri': 5,
        'Sat': 6,
      };
      final availabilityList = availabilityDays
          .map((d) => {
                'dayOfWeek': dayToNum[d] ?? 1,
                'startTime': startStr,
                'endTime': endStr,
              })
          .toList();
      final availabilityJson = jsonEncode(availabilityList);

      final formData = <String, String>{
        'fullName': nameController.text.trim(),
        'email': emailController.text.trim(),
        'password': passwordController.text,
        'phone': phoneController.text.trim(),
        'bio': aboutController.text.trim().isNotEmpty
            ? aboutController.text.trim()
            : 'Medical professional',
        'specialization': specializationController.text.trim(),
        'experienceInYears': experienceController.text.trim().isNotEmpty
            ? experienceController.text.trim()
            : '5',
        'clinicName': clinicNameController.text.trim(),
        'clinicAddress': clinicAddressController.text.trim(),
        'perSessionRate': consultationFeeController.text.trim().isNotEmpty
            ? consultationFeeController.text.trim()
            : '0',
        'availability': availabilityJson,
      };

      File? profileFile;
      if (profileImagePath != null) {
        final f = File(profileImagePath!);
        if (f.existsSync()) profileFile = f;
      }
      File? licenseFile;
      if (licensePath != null) {
        final f = File(licensePath!);
        if (f.existsSync()) licenseFile = f;
      }

      final value = await _apiServices.doctorRegister(
        formData,
        profileFile,
        licenseFile,
      );
      setLoading(false);

      final data = value is Map ? value['data'] : null;
      final accessToken = data is Map ? data['access_token']?.toString() : null;
      final userData = data is Map ? data['user'] : null;
      if (accessToken != null && userData is Map<String, dynamic>) {
        final userVM = Provider.of<UserViewModel>(context, listen: false);
        final loginModel = UserLoginModel(
          success: true,
          data: Data(
            user: User.fromJson(userData),
            accessToken: accessToken,
          ),
        );
        await userVM.saveUserLoginSession(loginModel);
      }

      Utils.toastMessage(context, 'Registration completed successfully');
      return true;
    } catch (error, stack) {
      setLoading(false);
      if (kDebugMode) print("doctorRegister error: $stack");
      Utils.toastMessage(context, error.toString(), isError: true);
      return false;
    }
  }

  // --- Setup Validation ---

  void finishPatientSetup(BuildContext context) {
    // Patient session (user + access_token) was already saved in registerStep3 from API response.
    // No need to overwrite here; navigation is handled by the View's Setup Step.
  }

  void finishDoctorSetup(BuildContext context) {
    // Doctor session (user + access_token) was already saved in doctorRegisterStep3 from API response.
    // No need to overwrite here; navigation is handled by the View's Setup Step.
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
