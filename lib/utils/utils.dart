import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medlink/data/app_exceptions.dart';

class Utils {
  /// Short user-facing text from thrown API errors (server `message`, not raw JSON).
  static String apiErrorMessage(Object error) {
    if (error is AppException) {
      final m = error.toString();
      if (m.isNotEmpty) return m;
    }
    final raw = error.toString().trim();
    if (raw.startsWith('{') && raw.endsWith('}')) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          final m = decoded['message']?.toString();
          if (m != null && m.isNotEmpty) return m;
        }
      } catch (_) {}
    }
    return raw;
  }

  /// Error toast using [apiErrorMessage] when [error] is not already a [String].
  static void toastError(BuildContext context, Object error) {
    final message =
        error is String ? error : apiErrorMessage(error);
    toastMessage(context, message, isError: true);
  }

  /// Full-width banner on the **root** overlay, **below the status bar** (not bottom SnackBar).
  static void toastMessage(BuildContext context, String message,
      {bool isError = false}) {
    final navigator = Navigator.of(context, rootNavigator: true);
    final overlay = navigator.overlay;
    if (overlay == null) return;

    final topInset = MediaQuery.maybeOf(context)?.padding.top ?? 0;
    final top = topInset + 8;

    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (overlayContext) => Stack(
        children: [
          Positioned(
            top: top,
            left: 12,
            right: 12,
            child: Material(
              color: Colors.transparent,
              elevation: 8,
              shadowColor: Colors.black26,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, -16 * (1 - value)),
                    child: Opacity(
                      opacity: value.clamp(0.0, 1.0),
                      child: child,
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isError
                            ? Colors.red.shade50.withOpacity(0.95)
                            : Colors.green.shade50.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isError
                              ? Colors.red.withOpacity(0.35)
                              : Colors.green.withOpacity(0.35),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            isError
                                ? Icons.error_outline_rounded
                                : Icons.check_circle_outline_rounded,
                            color: isError ? Colors.red.shade700 : Colors.green.shade700,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  isError ? 'Error' : 'Success',
                                  style: GoogleFonts.inter(
                                    color:
                                        isError ? Colors.red.shade700 : Colors.green.shade700,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  message,
                                  style: GoogleFonts.inter(
                                    color: Colors.black87,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }
}
