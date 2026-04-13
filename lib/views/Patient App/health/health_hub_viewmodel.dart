import 'package:flutter/material.dart';
import 'package:medlink/data/network/api_services.dart';
import 'package:medlink/models/first_aid_topic_model.dart';
import 'package:medlink/models/health_article_model.dart';
import 'package:medlink/models/emergency_number_model.dart';
import 'package:medlink/models/quick_instruction_model.dart';
import 'package:medlink/models/health_video_model.dart';
import 'package:medlink/core/constants/app_colors.dart';

class HealthHubViewModel extends ChangeNotifier {
  final ApiServices _apiServices = ApiServices();

  List<FirstAidTopic> _firstAidTopics = [];
  bool _isLoadingFirstAid = false;

  List<FirstAidTopic> get firstAidTopics => _firstAidTopics;
  bool get isLoadingFirstAid => _isLoadingFirstAid;

  List<HealthArticle> _healthArticles = [];
  bool _isLoadingArticles = false;

  List<HealthArticle> get healthArticles => _healthArticles;
  bool get isLoadingArticles => _isLoadingArticles;

  List<EmergencyNumber> _emergencyNumbers = [];
  bool _isLoadingEmergencyNumbers = false;

  List<EmergencyNumber> get emergencyNumbers => _emergencyNumbers;
  bool get isLoadingEmergencyNumbers => _isLoadingEmergencyNumbers;

  List<QuickInstructionModel> _quickInstructions = [];
  bool _isLoadingQuickInstructions = false;

  List<QuickInstructionModel> get quickInstructions => _quickInstructions;
  bool get isLoadingQuickInstructions => _isLoadingQuickInstructions;

  List<HealthVideo> _healthVideos = [];
  bool _isLoadingVideos = false;

  List<HealthVideo> get healthVideos => _healthVideos;
  bool get isLoadingVideos => _isLoadingVideos;

  Future<void> fetchHealthArticles() async {
    _isLoadingArticles = true;
    notifyListeners();

    try {
      final response = await _apiServices.getHealthArticles();
      if (response != null && response['data'] != null) {
        final List<dynamic> dataList = response['data'];
        _healthArticles = dataList.map((json) => HealthArticle.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint("Error fetching health articles: $e");
    } finally {
      _isLoadingArticles = false;
      notifyListeners();
    }
  }

  Future<void> fetchDoctorArticles() async {
    _isLoadingArticles = true;
    notifyListeners();

    try {
      final response = await _apiServices.getDoctorArticles();
      if (response != null && response['data'] != null) {
        final List<dynamic> dataList = response['data'];
        _healthArticles =
            dataList.map((json) => HealthArticle.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint("Error fetching doctor articles: $e");
    } finally {
      _isLoadingArticles = false;
      notifyListeners();
    }
  }

  Future<bool> uploadArticle({
    required String title,
    required String category,
    required String contentHtml,
    required bool isPublished,
    required String? imagePath,
  }) async {
    _isLoadingArticles = true;
    notifyListeners();

    try {
      final response = await _apiServices.uploadArticle(
        title: title,
        category: category,
        contentHtml: contentHtml,
        isPublished: isPublished,
        imagePath: imagePath,
      );

      if (response != null) {
        await fetchDoctorArticles(); // Refresh the list
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error uploading article: $e");
      return false;
    } finally {
      _isLoadingArticles = false;
      notifyListeners();
    }
  }

  Future<bool> updateArticle({
    required int articleId,
    required String title,
    required String category,
    required String contentHtml,
    required bool isPublished,
    String? imagePath,
  }) async {
    _isLoadingArticles = true;
    notifyListeners();
    try {
      final response = await _apiServices.updateDoctorArticle(
        articleId: articleId,
        title: title,
        category: category,
        contentHtml: contentHtml,
        isPublished: isPublished,
        imagePath: imagePath,
      );
      if (response != null) {
        await fetchDoctorArticles();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error updating article: $e");
      return false;
    } finally {
      _isLoadingArticles = false;
      notifyListeners();
    }
  }

  Future<bool> deleteArticle(int articleId) async {
    _isLoadingArticles = true;
    notifyListeners();
    try {
      final response = await _apiServices.deleteDoctorArticle(articleId);
      if (response != null) {
        _healthArticles.removeWhere((article) => article.id == articleId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error deleting article: $e");
      return false;
    } finally {
      _isLoadingArticles = false;
      notifyListeners();
    }
  }

  Future<void> fetchFirstAidTopics() async {
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

  Future<void> fetchEmergencyNumbers() async {
    _isLoadingEmergencyNumbers = true;
    notifyListeners();

    try {
      final response = await _apiServices.getEmergencyNumbers();
      if (response != null && response['data'] != null) {
        final List<dynamic> dataList = response['data'];
        _emergencyNumbers = dataList.map((json) => EmergencyNumber.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint("Error fetching emergency numbers: $e");
    } finally {
      _isLoadingEmergencyNumbers = false;
      notifyListeners();
    }
  }

  Future<void> fetchQuickInstructions() async {
    _isLoadingQuickInstructions = true;
    notifyListeners();

    try {
      final response = await _apiServices.getQuickInstructions();
      if (response != null && response['data'] != null) {
        final List<dynamic> dataList = response['data'];
        _quickInstructions = dataList.map((json) => QuickInstructionModel.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint("Error fetching quick instructions: $e");
    } finally {
      _isLoadingQuickInstructions = false;
      notifyListeners();
    }
  }

  Future<void> fetchHealthVideos() async {
    _isLoadingVideos = true;
    notifyListeners();

    try {
      final response = await _apiServices.getPatientReels();
      if (response != null && response['data'] != null) {
        final reelsData = response['data'];
        final List<dynamic> dataList = reelsData is List
            ? reelsData
            : (reelsData is Map && reelsData['items'] is List)
                ? reelsData['items'] as List<dynamic>
                : <dynamic>[];
        if (dataList.isEmpty) {
          final fallback = await _apiServices.getHealthVideos();
          if (fallback != null && fallback['data'] != null) {
            final fallbackData = fallback['data'];
            final List<dynamic> fallbackList = fallbackData is List
                ? fallbackData
                : (fallbackData is Map && fallbackData['items'] is List)
                    ? fallbackData['items'] as List<dynamic>
                    : <dynamic>[];
            _healthVideos =
                fallbackList.map((json) => HealthVideo.fromJson(json)).toList();
            return;
          }
        }
        _healthVideos = dataList.map((json) => _mapReelToVideo(json)).toList();
      } else {
        final fallback = await _apiServices.getHealthVideos();
        if (fallback != null && fallback['data'] != null) {
          final fallbackData = fallback['data'];
          final List<dynamic> dataList = fallbackData is List
              ? fallbackData
              : (fallbackData is Map && fallbackData['items'] is List)
                  ? fallbackData['items'] as List<dynamic>
                  : <dynamic>[];
          _healthVideos =
              dataList.map((json) => HealthVideo.fromJson(json)).toList();
        }
      }
    } catch (e) {
      debugPrint("Error fetching health videos: $e");
    } finally {
      _isLoadingVideos = false;
      notifyListeners();
    }
  }

  Future<void> recordReelView(int reelId) async {
    try {
      await _apiServices.markPatientReelViewed(reelId.toString());
    } catch (e) {
      debugPrint("Error marking reel view: $e");
    }
  }

  HealthVideo _mapReelToVideo(dynamic json) {
    final Map<String, dynamic> data = json is Map<String, dynamic>
        ? json
        : <String, dynamic>{};
    return HealthVideo(
      id: data['id'] ?? 0,
      title: (data['title'] ?? data['caption'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      videoUrl: (data['videoUrl'] ?? data['video_url'] ?? '').toString(),
      thumbnailUrl:
          (data['thumbnailUrl'] ?? data['thumbnail_url'] ?? '').toString(),
      category: (data['category'] ?? 'Health').toString(),
      createdAt: (data['createdAt'] ?? data['created_at'] ?? '').toString(),
      viewCount: data['viewCount'] is int
          ? data['viewCount'] as int
          : int.tryParse('${data['viewCount'] ?? 0}') ?? 0,
      likeCount: data['likeCount'] is int
          ? data['likeCount'] as int
          : int.tryParse('${data['likeCount'] ?? 0}') ?? 0,
      likedByMe: data['likedByMe'] == true,
    );
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

  Future<void> refreshData(bool isDoctor) async {
    _isLoadingArticles = true;
    _isLoadingEmergencyNumbers = true;
    _isLoadingQuickInstructions = true;
    _isLoadingFirstAid = true;
    _isLoadingVideos = true;
    notifyListeners();

    if (isDoctor) {
      await fetchDoctorArticles();
    } else {
      // Run all fetches in parallel for efficiency
      await Future.wait([
        fetchHealthArticles(),
        fetchEmergencyNumbers(),
        fetchQuickInstructions(),
        fetchFirstAidTopics(),
        fetchHealthVideos(),
      ]).catchError((e) {
        debugPrint("Parallel fetch error in HealthHub: $e");
        return [];
      });
    }
    
    _isLoadingArticles = false;
    _isLoadingEmergencyNumbers = false;
    _isLoadingQuickInstructions = false;
    _isLoadingFirstAid = false;
    _isLoadingVideos = false;
    notifyListeners();
  }
}
