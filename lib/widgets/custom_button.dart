import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final double? height;
  final double? fontSize;
  final double verticalPadding;
  final double? borderRadius;
  final FontWeight? fontWeight;
  final String? fontFamily;
  final Color? shadowColor;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.height,
    this.fontSize,
    this.verticalPadding = 12,
    this.borderRadius,
    this.fontWeight,
    this.fontFamily,
    this.shadowColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor ?? Colors.white,
          shadowColor: shadowColor ?? Colors.black.withOpacity(0.15),
          elevation: shadowColor != null ? 8 : 4,
          minimumSize: Size(double.infinity, height ?? 50),
          padding: EdgeInsets.symmetric(vertical: verticalPadding),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius ?? 20),
          ),
          textStyle: GoogleFonts.inter(
                fontSize: fontSize ?? 16,
                fontWeight: fontWeight ?? FontWeight.w400,
              ),
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: textColor ?? Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                text,
                style: textColor != null ? TextStyle(color: textColor, fontSize: fontSize) : null,
              ),
      ),
    );
  }
}
