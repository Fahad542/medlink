import 'package:flutter/material.dart';

class QuickActionItem {
  final String title;
  final String subtitle;
  final String image;
  final Color cardColor;
  final VoidCallback? onTap;

  QuickActionItem({
    required this.title,
    required this.subtitle,
    required this.image,
    required this.cardColor,
    this.onTap,
  });
}

class CategoryItem {
  final int? id;
  final String name;
  final String image;
  final Color color;
  final Color iconColor;

  CategoryItem({
    this.id,
    required this.name,
    required this.image,
    required this.color,
    this.iconColor = Colors.white,
  });
}

class BannerItem {
  final String type;
  final String title;
  final String subtitle;
  final String buttonText;
  final List<Color> colors;
  final Color shadowColor;
  final String image;
  final bool isCompact;

  BannerItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.colors,
    required this.shadowColor,
    required this.image,
    this.isCompact = false,
  });
}
