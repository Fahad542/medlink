import 'package:flutter/material.dart';
import 'package:medlink/data/network/api_services.dart';
import 'package:medlink/models/first_aid_topic_model.dart';
import 'package:medlink/core/constants/app_colors.dart';

class HealthHubViewModel extends ChangeNotifier {
  final ApiServices _apiServices = ApiServices();

  List<FirstAidTopic> _firstAidTopics = [];
  bool _isLoadingFirstAid = false;

  List<FirstAidTopic> get firstAidTopics => _firstAidTopics;
  bool get isLoadingFirstAid => _isLoadingFirstAid;

  void fetchFirstAidTopics() async {
    _isLoadingFirstAid = true;
    notifyListeners();

    try {
      final response = await _apiServices.getFirstAidTopics();
      if (response != null && response['data'] != null) {
        final List<dynamic> dataList = response['data'];
        _firstAidTopics = dataList.map((json) => FirstAidTopic.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint("Error fetching first aid topics: $e");
    } finally {
      _isLoadingFirstAid = false;
      notifyListeners();
    }
  }

  // Helper method to assign predictable colors and icons based on title keywords
  Map<String, dynamic> getTopicStyle(String title) {
    String lowerTitle = title.toLowerCase();
    
    if (lowerTitle.contains('cpr') || lowerTitle.contains('heart') || lowerTitle.contains('attack')) {
      return {"color": Colors.red, "icon": Icons.favorite_rounded};
    } else if (lowerTitle.contains('burn')) {
      return {"color": Colors.deepOrange, "icon": Icons.local_fire_department_rounded};
    } else if (lowerTitle.contains('chok')) {
      return {"color": Colors.orange, "icon": Icons.help_center_rounded};
    } else if (lowerTitle.contains('fracture') || lowerTitle.contains('bone') || lowerTitle.contains('break')) {
      return {"color": Colors.blue, "icon": Icons.medical_services_rounded};
    } else if (lowerTitle.contains('allerg')) {
      return {"color": Colors.purple, "icon": Icons.coronavirus_rounded};
    } else if (lowerTitle.contains('poison')) {
      return {"color": Colors.green, "icon": Icons.warning_amber_rounded};
    } else if (lowerTitle.contains('bleed') || lowerTitle.contains('blood') || lowerTitle.contains('cut') || lowerTitle.contains('wound')) {
      return {"color": Colors.redAccent, "icon": Icons.bloodtype_rounded};
    } else if (lowerTitle.contains('faint') || lowerTitle.contains('conscious')) {
      return {"color": Colors.teal, "icon": Icons.person_off_rounded};
    } else if (lowerTitle.contains('head') || lowerTitle.contains('concussion')) {
       return {"color": Colors.indigo, "icon": Icons.personal_injury_rounded};
    } else if (lowerTitle.contains('bite') || lowerTitle.contains('sting')) {
       return {"color": Colors.lime, "icon": Icons.bug_report_rounded};
    }

    // Default style
    return {"color": AppColors.primary, "icon": Icons.health_and_safety_rounded};
  }
}
