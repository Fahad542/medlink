import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/data/network/api_services.dart';
import 'package:medlink/utils/utils.dart';
import 'package:medlink/widgets/custom_button.dart';
import 'package:medlink/views/services/session_view_model.dart';
import 'package:medlink/views/Login/login_view.dart';
import 'package:provider/provider.dart';

class DeleteAccountSheet extends StatefulWidget {
  const DeleteAccountSheet({Key? key}) : super(key: key);

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const DeleteAccountSheet(),
    );
  }

  @override
  _DeleteAccountSheetState createState() => _DeleteAccountSheetState();
}

class _DeleteAccountSheetState extends State<DeleteAccountSheet> {
  final ApiServices _apiServices = ApiServices();

  static const int _otpLength = 6;
  final List<TextEditingController> _otpControllers =
      List.generate(_otpLength, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
      List.generate(_otpLength, (_) => FocusNode());

  bool _isLoading = false;
  int _step = 1; // 1: Initial Warning, 2: OTP Entry
  String? _debugOtp;

  @override
  void initState() {
    super.initState();
    for (final n in _otpFocusNodes) {
      n.addListener(() {
        if (mounted) setState(() {});
      });
    }
  }

  String get _otpText => _otpControllers.map((c) => c.text).join();

  void _onOtpDigitEntered(int index, String value) {
    if (value.isNotEmpty) {
      if (index < _otpLength - 1) {
        _otpFocusNodes[index + 1].requestFocus();
      } else {
        _otpFocusNodes[index].unfocus();
      }
    } else {
      if (index > 0) {
        _otpFocusNodes[index - 1].requestFocus();
      }
    }
    setState(() {});
  }

  Future<void> _sendOtp() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiServices.sendDeleteAccountOtp();
      setState(() => _isLoading = false);
      if (response != null && response['success'] == true) {
        setState(() => _step = 2);
        final data = response['data'];
        if (data is Map && data.containsKey('otp')) {
          setState(() => _debugOtp = data['otp'].toString());
        }
        Utils.toastMessage(context, 'OTP sent to your registered email/phone');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _otpFocusNodes[0].requestFocus();
        });
      } else {
        Utils.toastMessage(context, response['message'] ?? 'Failed to send OTP', isError: true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      Utils.toastError(context, e);
    }
  }

  Future<void> _verifyOtpAndDelete() async {
    final otp = _otpText.trim();
    if (otp.length < _otpLength) {
      Utils.toastMessage(context, 'Please enter the full $_otpLength-digit OTP', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await _apiServices.verifyDeleteAccountOtp(otp);
      setState(() => _isLoading = false);

      if (response != null && response['success'] == true) {
        Utils.toastMessage(context, 'Account successfully deleted');
        Navigator.pop(context);
        Provider.of<UserViewModel>(context, listen: false).logout();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginView()),
          (route) => false,
        );
      } else {
        Utils.toastMessage(context, response['message'] ?? 'Invalid OTP', isError: true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      Utils.toastError(context, e);
    }
  }

  @override
  void dispose() {
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  Widget _buildOtpDigitField(int index, {required double width}) {
    final isFocused = _otpFocusNodes[index].hasFocus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: width,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isFocused
            ? Border.all(color: AppColors.primary, width: 2)
            : Border.all(color: Colors.grey.shade200),
        boxShadow: [
          if (isFocused)
            BoxShadow(
              color: AppColors.primary.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          else
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Center(
        child: TextField(
          controller: _otpControllers[index],
          focusNode: _otpFocusNodes[index],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
          cursorColor: AppColors.primary,
          maxLength: 1,
          showCursor: false,
          onChanged: (value) => _onOtpDigitEntered(index, value),
          decoration: const InputDecoration(
            counterText: '',
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                _step == 1 ? "Delete Account" : "Verify Deletion",
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.error,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                _step == 1
                    ? "This action is irreversible. All your data will be permanently removed."
                    : "Enter the OTP sent to you to confirm account deletion.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Colors.grey[600],
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 32),

            if (_step == 2) ...[
              if (kDebugMode && _debugOtp != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.bug_report_outlined, size: 16, color: Colors.amber.shade800),
                        const SizedBox(width: 8),
                        Text(
                          "Debug OTP: $_debugOtp",
                          style: TextStyle(
                            color: Colors.amber.shade900,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              LayoutBuilder(
                builder: (context, constraints) {
                  const double minSpacing = 6;
                  const double maxSpacing = 10;
                  const double maxCellWidth = 44;
                  const double minCellWidth = 36;
                  final totalSlots = _otpLength.toDouble();
                  final spacingSlots = (_otpLength - 1).toDouble();
                  final candidateByMax =
                      (constraints.maxWidth - (spacingSlots * maxSpacing)) / totalSlots;
                  final cellWidth = candidateByMax.clamp(minCellWidth, maxCellWidth);
                  final spacing = ((constraints.maxWidth - (cellWidth * totalSlots)) / spacingSlots)
                      .clamp(minSpacing, maxSpacing);

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (int i = 0; i < _otpLength; i++) ...[
                        _buildOtpDigitField(i, width: cellWidth),
                        if (i != _otpLength - 1) SizedBox(width: spacing),
                      ],
                    ],
                  );
                },
              ),
            ],

            const SizedBox(height: 32),

            CustomButton(
              text: _step == 1 ? "Send OTP to Delete" : "Confirm Deletion",
              height: 56,
              fontSize: 16,
              backgroundColor: AppColors.error,
              isLoading: _isLoading,
              onPressed: () {
                if (_step == 1) {
                  _sendOtp();
                } else {
                  _verifyOtpAndDelete();
                }
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
