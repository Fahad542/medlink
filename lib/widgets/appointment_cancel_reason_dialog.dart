import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/widgets/custom_button.dart';

/// Shows a dialog to collect a cancellation reason. Returns trimmed text on confirm,
/// or null if cancelled / dismissed.
Future<String?> showAppointmentCancelReasonDialog(
  BuildContext context, {
  required String title,
  String? subtitle,
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => _CancelReasonDialogContent(
      title: title,
      subtitle: subtitle,
    ),
  );
}

class _CancelReasonDialogContent extends StatefulWidget {
  const _CancelReasonDialogContent({
    required this.title,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  State<_CancelReasonDialogContent> createState() =>
      _CancelReasonDialogContentState();
}

class _CancelReasonDialogContentState extends State<_CancelReasonDialogContent> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 2),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: AppColors.textPrimary,
              ),
            ),
            if (widget.subtitle != null && widget.subtitle!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                widget.subtitle!,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.grey[600],
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              maxLines: 3,
              minLines: 2,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Cancellation reason',
                hintText: 'Briefly explain why you are cancelling',
                errorText: _errorText,
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                alignLabelWithHint: true,
              ),
              onChanged: (_) {
                if (_errorText != null) {
                  setState(() => _errorText = null);
                }
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.grey[100],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Back',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    text: 'Confirm cancel',
                    backgroundColor: AppColors.primary,
                    height: 48,
                    fontSize: 14,
                    borderRadius: 16,
                    onPressed: () {
                      final raw = _controller.text.trim();
                      if (raw.length < 3) {
                        setState(() => _errorText =
                            'Please enter at least 3 characters');
                        return;
                      }
                      Navigator.of(context).pop(raw);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
