import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medlink/utils/user_facing_errors.dart';

class Utils {
  static void toastMessage(BuildContext context, String message, {bool isError = false}) {
    final overlay = Overlay.of(context, rootOverlay: true);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 50,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 300),
            curve: Curves.bounceIn,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, -50 * (1 - value)),
                child: Opacity(
                  opacity: value.clamp(0.0, 1.0),
                  child: child,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isError
                      ? Colors.red.withOpacity(0.25)
                      : Colors.green.withOpacity(0.25),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
                    color: isError ? Colors.red : Colors.green,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isError ? "Error" : "Success",
                          style: GoogleFonts.inter(
                            color: isError ? Colors.red : Colors.green,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
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
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  /// Prefer over [toastMessage(..., isError: true)] with [Object.toString] in catch blocks.
  static void toastError(BuildContext context, Object error) {
    toastMessage(context, UserFacingErrors.forException(error), isError: true);
  }
}
