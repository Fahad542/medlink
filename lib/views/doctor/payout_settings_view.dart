import 'package:flutter/material.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/data/network/api_services.dart';
import 'package:medlink/widgets/custom_app_bar_widget.dart';
import 'package:medlink/widgets/custom_button.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medlink/utils/utils.dart';
import 'package:shimmer/shimmer.dart';

class PayoutSettingsView extends StatefulWidget {
  const PayoutSettingsView({super.key});

  @override
  State<PayoutSettingsView> createState() => _PayoutSettingsViewState();
}

class _PayoutSettingsViewState extends State<PayoutSettingsView> {
  final ApiServices _apiServices = ApiServices();
  final _bankNameController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _swiftCodeController = TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPayoutAccount();
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _accountNameController.dispose();
    _accountNumberController.dispose();
    _swiftCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadPayoutAccount() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiServices.getDoctorPayoutAccount();
      if (response != null && response['success'] == true) {
        final rawData = response['data'];
        final data = (rawData is Map && rawData['payoutAccount'] is Map)
            ? rawData['payoutAccount']
            : rawData;
        if (data is Map) {
          _accountNameController.text =
              (data['accountHolderName'] ?? '').toString();
          _bankNameController.text = (data['bankName'] ?? '').toString();
          final maskedCard =
              (data['maskedCardNumber'] ?? data['cardNumberMasked'])?.toString();
          if (maskedCard != null && maskedCard.isNotEmpty) {
            _accountNumberController.text = maskedCard;
          } else if (data['cardLast4'] != null) {
            _accountNumberController.text = '**** **** **** ${data['cardLast4']}';
          }
          if (data['expiryMonth'] != null && data['expiryYear'] != null) {
            _swiftCodeController.text =
                '${data['expiryMonth']}/${data['expiryYear']}';
          }
        }
      }
    } catch (_) {
      if (!mounted) return;
      Utils.toastMessage(context, 'Unable to load payout account', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveBankDetails() async {
    final name = _accountNameController.text.trim();
    final number = _accountNumberController.text.trim();
    final bankName = _bankNameController.text.trim();
    final expiryRaw = _swiftCodeController.text.trim();

    if (name.isEmpty || number.isEmpty) {
      Utils.toastMessage(
        context,
        'Account name and card number are required',
        isError: true,
      );
      return;
    }

    int? expiryMonth;
    int? expiryYear;
    if (expiryRaw.isNotEmpty && expiryRaw.contains('/')) {
      final parts = expiryRaw.split('/');
      if (parts.length == 2) {
        expiryMonth = int.tryParse(parts[0]);
        expiryYear = int.tryParse(parts[1]);
      }
    }

    setState(() => _isSaving = true);
    try {
      final payload = {
        'accountHolderName': name,
        'cardNumber': number.replaceAll(' ', ''),
        if (bankName.isNotEmpty) 'bankName': bankName,
        if (expiryMonth != null) 'expiryMonth': expiryMonth,
        if (expiryYear != null) 'expiryYear': expiryYear,
      };
      final response = await _apiServices.upsertDoctorPayoutAccount(payload);
      if (response != null && response['success'] == true) {
        if (!mounted) return;
        Utils.toastMessage(context, 'Payout account saved');
        Navigator.pop(context);
      } else {
        throw Exception('Failed');
      }
    } catch (_) {
      if (!mounted) return;
      Utils.toastMessage(context, 'Unable to save payout account', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const CustomAppBar(title: "Payout Settings"),
      body: _isLoading
          ? _buildFormShimmer()
          : _buildBankForm(),
    );
  }

  Widget _buildBankForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField("Bank Name", "e.g. Equity Bank", _bankNameController, Icons.account_balance_rounded),
          const SizedBox(height: 20),
          _buildTextField("Account Holder Name", "e.g. John Doe", _accountNameController, Icons.person_outline_rounded),
          const SizedBox(height: 20),
          _buildTextField("Account Number", "Enter account number", _accountNumberController, Icons.numbers_rounded, isNumber: true),
          const SizedBox(height: 20),
          _buildTextField("SWIFT / BIC Code (Optional)", "Enter code", _swiftCodeController, Icons.code_rounded),

          const SizedBox(height: 48),
          CustomButton(
            text: _isSaving ? "Saving..." : "Save Bank Details",
            isLoading: _isSaving,
            onPressed: _saveBankDetails,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller, IconData icon, {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w400,
              fontSize: 15,
              color: Colors.black87,
            ),
            cursorColor: AppColors.primary,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText: hint,
              hintStyle: GoogleFonts.inter(
                color: Colors.grey[400],
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.all(12),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 18),
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormShimmer() {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFieldShimmer(),
            const SizedBox(height: 20),
            _buildFieldShimmer(),
            const SizedBox(height: 20),
            _buildFieldShimmer(),
            const SizedBox(height: 20),
            _buildFieldShimmer(),
            const SizedBox(height: 48),
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 14,
          width: 140,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 62,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ],
    );
  }
}
