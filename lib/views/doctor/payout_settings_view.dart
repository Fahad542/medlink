import 'package:flutter/material.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/data/network/api_services.dart';
import 'package:medlink/widgets/custom_app_bar_widget.dart';
import 'package:medlink/widgets/custom_button.dart';
import 'package:google_fonts/google_fonts.dart';

class PayoutSettingsView extends StatefulWidget {
  const PayoutSettingsView({super.key});

  @override
  State<PayoutSettingsView> createState() => _PayoutSettingsViewState();
}

class _PayoutSettingsViewState extends State<PayoutSettingsView> with SingleTickerProviderStateMixin {
  final ApiServices _apiServices = ApiServices();
  late TabController _tabController;
  final _bankNameController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _swiftCodeController = TextEditingController();

  final _mobileNumberController = TextEditingController();
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPayoutAccount();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bankNameController.dispose();
    _accountNameController.dispose();
    _accountNumberController.dispose();
    _swiftCodeController.dispose();
    _mobileNumberController.dispose();
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to load payout account')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account name and card number are required')),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payout account saved')),
        );
        Navigator.pop(context);
      } else {
        throw Exception('Failed');
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to save payout account')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const CustomAppBar(title: "Payout Settings"),
      body: Column(
        children: [
          const SizedBox(height: 20),
          // Custom Tab Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 50,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                dividerColor: Colors.transparent, // Remove underlining line
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey[600],
                labelStyle: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                tabs: const [
                  Tab(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text("Bank Account"),
                    ),
                  ),
                  Tab(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text("Mobile Money"),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildBankForm(),
                      _buildMobileForm(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      physics: const BouncingScrollPhysics(),
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

  Widget _buildMobileForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.phone_android_rounded, color: Color(0xFF4CAF50), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Payments will be sent to your registered M-PESA number.",
                    style: GoogleFonts.inter(
                      color: const Color(0xFF2E7D32),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildTextField("M-PESA Number", "e.g. +254 700 000 000", _mobileNumberController, Icons.phone_rounded, isNumber: true),
          
          const SizedBox(height: 48),
          CustomButton(
            text: "Save M-PESA Details",
            backgroundColor: const Color(0xFF4CAF50),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Mobile money details saved successfully")),
              );
            },
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
                color: Colors.grey.withOpacity(0.06),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(
                color: Colors.grey[400],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: Icon(icon, color: Colors.grey[400], size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}
