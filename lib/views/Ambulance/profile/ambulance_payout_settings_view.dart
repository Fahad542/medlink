import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medlink/data/network/api_services.dart';
import 'package:medlink/widgets/custom_app_bar_widget.dart';
import 'package:medlink/widgets/custom_button.dart';

class AmbulancePayoutSettingsView extends StatefulWidget {
  const AmbulancePayoutSettingsView({super.key});

  @override
  State<AmbulancePayoutSettingsView> createState() =>
      _AmbulancePayoutSettingsViewState();
}

class _AmbulancePayoutSettingsViewState
    extends State<AmbulancePayoutSettingsView> {
  final ApiServices _apiServices = ApiServices();
  final _accountNameController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _expiryController = TextEditingController();
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPayout();
  }

  @override
  void dispose() {
    _accountNameController.dispose();
    _cardNumberController.dispose();
    _bankNameController.dispose();
    _expiryController.dispose();
    super.dispose();
  }

  Future<void> _loadPayout() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiServices.getDriverPayoutAccount();
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
            _cardNumberController.text = maskedCard;
          } else if (data['cardLast4'] != null) {
            _cardNumberController.text = '**** **** **** ${data['cardLast4']}';
          }
          if (data['expiryMonth'] != null && data['expiryYear'] != null) {
            _expiryController.text = '${data['expiryMonth']}/${data['expiryYear']}';
          }
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    final name = _accountNameController.text.trim();
    final number = _cardNumberController.text.trim();
    if (name.isEmpty || number.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account name and card number are required')),
      );
      return;
    }

    int? expiryMonth;
    int? expiryYear;
    final expiryRaw = _expiryController.text.trim();
    if (expiryRaw.contains('/')) {
      final parts = expiryRaw.split('/');
      if (parts.length == 2) {
        expiryMonth = int.tryParse(parts[0]);
        expiryYear = int.tryParse(parts[1]);
      }
    }

    setState(() => _isSaving = true);
    try {
      final ok = await _apiServices.upsertDriverPayoutAccount({
        'accountHolderName': name,
        'cardNumber': number.replaceAll(' ', ''),
        if (_bankNameController.text.trim().isNotEmpty)
          'bankName': _bankNameController.text.trim(),
        if (expiryMonth != null) 'expiryMonth': expiryMonth,
        if (expiryYear != null) 'expiryYear': expiryYear,
      });
      if (!mounted) return;
      if (ok != null && ok['success'] == true) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payout account saved')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to save payout account')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Payout Settings'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _accountNameController,
                    decoration:
                        const InputDecoration(labelText: 'Account holder name'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _cardNumberController,
                    decoration: const InputDecoration(labelText: 'Card number'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _bankNameController,
                    decoration: const InputDecoration(labelText: 'Bank name'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _expiryController,
                    decoration: const InputDecoration(
                        labelText: 'Expiry (MM/YYYY) optional'),
                  ),
                  const SizedBox(height: 20),
                  CustomButton(
                    text: 'Save',
                    isLoading: _isSaving,
                    onPressed: _save,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add payout details before withdrawal requests.',
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
    );
  }
}
