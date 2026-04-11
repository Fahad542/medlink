import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/core/constants/app_url.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CustomNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxShape shape;
  final String? placeholderName;
  final String? errorAssetImage;
  final BoxFit fit;

  const CustomNetworkImage({
    super.key,
    this.imageUrl,
    this.width,
    this.height,
    this.borderRadius = 12,
    this.shape = BoxShape.rectangle,
    this.placeholderName,
    this.errorAssetImage,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildErrorWidget();
    }

    final String fullUrl = AppUrl.getFullUrl(imageUrl!);

    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        shape: shape,
        borderRadius: shape == BoxShape.circle ? null : BorderRadius.circular(borderRadius),
      ),
      child: CachedNetworkImage(
        imageUrl: fullUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => _buildLoadingWidget(),
        errorWidget: (context, url, error) {
          debugPrint("Image Load Error: $error for URL: $url");
          return _buildErrorWidget();
        },
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.white,
      child: Container(
        width: width,
        height: height,
        color: Colors.white,
      ),
    );
  }

  Widget _buildErrorWidget() {
    if (errorAssetImage != null && errorAssetImage!.isNotEmpty) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          shape: shape,
          borderRadius: shape == BoxShape.circle ? null : BorderRadius.circular(borderRadius),
        ),
        child: ClipRRect(
          borderRadius: shape == BoxShape.circle ? BorderRadius.circular(999) : BorderRadius.circular(borderRadius),
          child: Image.asset(
            errorAssetImage!,
            fit: BoxFit.contain,
          ),
        ),
      );
    }

    final bool hasName = placeholderName != null && placeholderName!.isNotEmpty;
    final String initials = hasName
        ? placeholderName!
            .trim()
            .split(' ')
            .map((l) => l[0])
            .take(2)
            .join()
            .toUpperCase()
        : "";

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        shape: shape,
        borderRadius: shape == BoxShape.circle ? null : BorderRadius.circular(borderRadius),
      ),
      child: Center(
        child: hasName
            ? Text(
                initials,
                style: GoogleFonts.inter(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: height != null ? height! * 0.4 : 14,
                ),
              )
            : Icon(
                Icons.person_rounded,
                color: AppColors.primary,
                size: height != null ? height! * 0.6 : 24,
              ),
      ),
    );
  }
}
