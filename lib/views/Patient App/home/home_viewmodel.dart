import 'dart:async';
import 'package:flutter/material.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/data/network/api_services.dart';
import 'package:medlink/models/home_ui_models.dart'; // Added import

class HomeViewModel extends ChangeNotifier {
  // State
  bool _isSosVisible = true;
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;
  
  bool get isSosVisible => _isSosVisible;
  int get currentBannerIndex => _currentBannerIndex;

  HomeViewModel() {
    _startAutoScroll();
    fetchDoctorCategories();
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    super.dispose();
  }

  final _apiServices = ApiServices();
  List<CategoryItem> _apiCategories = [];
  bool _categoriesLoading = false;

  bool get categoriesLoading => _categoriesLoading;

  void setCategoriesLoading(bool value) {
    _categoriesLoading = value;
    notifyListeners();
  }

  Future<void> fetchDoctorCategories() async {
    setCategoriesLoading(true);
    try {
      final response = await _apiServices.getDoctorCategories();
      if (response != null && response['success'] == true) {
        final List<dynamic> data = response['data'];
        _apiCategories = data.map((name) => _mapToCategoryItem(name.toString())).toList();
      }
    } catch (e) {
      debugPrint("Error fetching categories: $e");
    } finally {
      setCategoriesLoading(false);
    }
  }

  CategoryItem _mapToCategoryItem(String name) {
    // Map existing icons/colors or defaults
    switch (name.toLowerCase()) {
      case 'cardiologist':
        return CategoryItem(
          image: 'assets/cardiologist.png',
          name: 'Cardiologist',
          color: const Color(0xFF5DB09C),
        );
      case 'dentist':
        return CategoryItem(
          image: 'assets/pediatrician.png', // Assuming pediatrician or using a default for now
          name: 'Dentist',
          color: const Color(0xFFE0E8AA),
        );
      case 'neurologist':
        return CategoryItem(
          image: 'assets/Neurology.png',
          name: 'Neurologist',
          color: const Color(0xFFD89CE8),
        );
      case 'dermatologist':
        return CategoryItem(
          image: 'assets/derma.png',
          name: 'Dermatologist',
          color: const Color(0xFF9DF1C1),
        );
      case 'general':
      default:
        return CategoryItem(
          image: 'assets/general.png',
          name: name,
          color: const Color(0xFFFFCC80),
        );
    }
  }

  void _startAutoScroll() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      int nextPage = _currentBannerIndex + 1;
      if (nextPage > 2) nextPage = 0; // Assuming 3 banners
      setBannerIndex(nextPage);
    });
  }

  // Actions
  void hideSos() {
    _isSosVisible = false;
    notifyListeners();
  }

  void setBannerIndex(int index) {
    _currentBannerIndex = index;
    notifyListeners();
  }

  // Data Sources
  List<CategoryItem> get categories => _apiCategories.isNotEmpty ? _apiCategories : [
    CategoryItem(
      image: 'assets/general.png',
      name: 'General',
      color: const Color(0xFFFFCC80),
    ),
    CategoryItem(
      image: 'assets/cardiologist.png',
      name: 'Cardiologist',
      color: const Color(0xFF5DB09C),
    ),
    CategoryItem(
      image: 'assets/pediatrician.png',
      name: 'Pediatrician',
      color: const Color(0xFFE0E8AA),
    ),
    CategoryItem(
      image: 'assets/derma.png',
      name: 'Dermatologist',
      color: const Color(0xFF9DF1C1),
    ),
    CategoryItem(
      image: 'assets/Neurology.png',
      name: 'Neurologist',
      color: const Color(0xFFD89CE8),
    ),
  ];

  List<QuickActionItem> get quickActions => [
    QuickActionItem(
      title: "Available Doctors",
      subtitle: "Find Specialists",
      image: "assets/doctors.png",
      cardColor: const Color(0xFFCEE9F1),
    ),
    QuickActionItem(
      title: "E-Prescription",
      subtitle: "View Doctor's Rx",
      image: "assets/pres.png",
      cardColor: const Color(0xFFDCE8C0),
    ),
    QuickActionItem(
      title: "Online \nConsult",
      subtitle: "Chat with Doctors",
      image: "assets/consult.png",
      cardColor: const Color(0xFFE3DBF2),
    ),
    QuickActionItem(
      title: "Health \nTips",
      subtitle: "Stay Healthy",
      image: "assets/tip.png",
      cardColor: const Color(0xFFFFEBD2),
    ),
  ];

  List<String> get healthArticles => [
    "5 Tips for Heart Health",
    "Understanding Malaria Symptoms",
    "Balanced Diet for Immunity",
  ];

  List<BannerItem> get banners => [
     BannerItem(
        type: "doctor",
        title: "Find Your\nSpecialist",
        subtitle: "Connect with top doctors.",
        buttonText: "Find Now",
        colors: [const Color(0xFF00695C), const Color(0xFF00897B)],
        shadowColor: const Color(0xFF00695C),
        image: "assets/doctor.png",
        isCompact: true,
      ),
      BannerItem(
        type: "emergency",
        title: "Medical\nEmergency?",
        subtitle: "Get instant ambulance dispatch.",
        buttonText: "Call SOS",
        colors: [const Color(0xFFD32F2F), const Color(0xFFEF5350)],
        shadowColor: const Color(0xFFD32F2F),
        image: "assets/ambulance_driver.png",
        isCompact: true,
      ),
      BannerItem(
        type: "health",
        title: "Health\nInsights",
        subtitle: "Daily tips for a healthy life.",
        buttonText: "Read More",
        colors: [const Color(0xFF0097A7), const Color(0xFF26C6DA)],
        shadowColor: const Color(0xFF0097A7),
        image: "assets/healthy.png",
        isCompact: true,
      ),
  ];
}


