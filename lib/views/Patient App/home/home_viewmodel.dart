import 'dart:async';
import 'package:flutter/material.dart';
import 'package:medlink/core/constants/app_url.dart';
import 'package:medlink/data/network/api_services.dart';
import 'package:medlink/services/chat_socket_service.dart';
import 'package:medlink/views/services/session_view_model.dart';
import 'package:medlink/models/home_ui_models.dart'; // Added import

class HomeViewModel extends ChangeNotifier {
  // State
  bool _isSosVisible = true;
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;
  final UserViewModel _userViewModel;
  final ChatSocketService _chatSocket = ChatSocketService.instance;
  StreamSubscription<Map<String, dynamic>>? _chatSub;
  StreamSubscription<Map<String, dynamic>>? _chatReadSub;
  final Set<String> _seenSocketKeys = {};
  int _unreadMessagesCount = 0;
  
  bool get isSosVisible => _isSosVisible;
  int get currentBannerIndex => _currentBannerIndex;
  int get unreadMessagesCount => _unreadMessagesCount;

  HomeViewModel(this._userViewModel) {
    _startAutoScroll();
    fetchDoctorCategories();
    _ensureChatRealtime();
    fetchUnreadMessagesCount();
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _chatSub?.cancel();
    _chatReadSub?.cancel();
    super.dispose();
  }

  final _apiServices = ApiServices();
  List<CategoryItem> _apiCategories = [];
  bool _categoriesLoading = false;

  int? get _myUserId =>
      _userViewModel.loginSession?.data?.user?.id ??
      int.tryParse(_userViewModel.patient?.id ?? '');

  void _ensureChatRealtime() {
    final token = _userViewModel.accessToken;
    if (token == null || token.isEmpty) return;
    _chatSocket.connect(url: '${AppUrl.baseUrl}/chat', token: token);
    _chatSub?.cancel();
    _chatReadSub?.cancel();
    _chatSub = _chatSocket.newMessageStream.listen(_onChatSocketMessage);
    _chatReadSub = _chatSocket.conversationReadStream.listen((_) {
      unawaited(fetchUnreadMessagesCount());
    });
  }

  Future<void> fetchUnreadMessagesCount() async {
    try {
      final response = await _apiServices.getConversations();
      List<dynamic>? list;
      if (response is Map && response['data'] is List) {
        list = response['data'] as List;
      } else if (response is List) {
        list = response;
      }
      if (list == null) return;

      int total = 0;
      for (final raw in list) {
        if (raw is! Map) continue;
        final item = Map<String, dynamic>.from(raw);
        final other = item['other'];
        if (other is Map) {
          final role = other['role']?.toString().toUpperCase() ?? '';
          if (role.isNotEmpty && role != 'DOCTOR') continue;
        }
        final u = item['unreadCount'] ?? item['unread'] ?? 0;
        final count = u is int ? u : int.tryParse(u.toString()) ?? 0;
        if (count > 0) total += count;
      }

      if (total != _unreadMessagesCount) {
        _unreadMessagesCount = total;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Home unread count error: $e');
    }
  }

  static Map<String, dynamic> _unwrapSocketMessage(Map<String, dynamic> payload) {
    if (payload['message'] is Map) {
      return Map<String, dynamic>.from(payload['message'] as Map);
    }
    if (payload['data'] is Map) {
      return Map<String, dynamic>.from(payload['data'] as Map);
    }
    return payload;
  }

  bool _consumeSocketDedupe(Map<String, dynamic> msg) {
    final rawId = msg['id'];
    final mid = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');
    late final String key;
    if (mid != null && mid > 0) {
      key = 'id:$mid';
    } else {
      final sid = msg['senderId']?.toString() ?? '';
      final rid = msg['recipientId']?.toString() ?? '';
      final sa = msg['sentAt']?.toString() ?? '';
      final body = msg['body']?.toString() ?? '';
      if (sid.isEmpty || sa.isEmpty) return true;
      key = 'fb:$sid|$rid|$sa|$body';
    }
    if (_seenSocketKeys.contains(key)) return false;
    _seenSocketKeys.add(key);
    if (_seenSocketKeys.length > 400) _seenSocketKeys.clear();
    return true;
  }

  void _onChatSocketMessage(Map<String, dynamic> payload) {
    try {
      final myId = _myUserId;
      if (myId == null) return;

      var msg = _unwrapSocketMessage(payload);
      if (msg['id'] == null && payload['id'] != null) {
        msg = Map<String, dynamic>.from(msg)..['id'] = payload['id'];
      }
      if (msg['sosId'] != null || msg['tripId'] != null) return;
      if (!_consumeSocketDedupe(msg)) return;

      final senderId = int.tryParse(msg['senderId']?.toString() ?? '');
      final recipientId = int.tryParse(msg['recipientId']?.toString() ?? '');
      if (senderId == null || recipientId == null) return;

      if (recipientId == myId && senderId != myId) {
        _unreadMessagesCount += 1;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Home chat socket error: $e');
    }
  }

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
        _apiCategories = data.map((json) {
          if (json is Map<String, dynamic>) {
            return _mapToCategoryItem(json['name']?.toString() ?? 'General', id: json['id'] as int?);
          } else {
             return _mapToCategoryItem(json.toString());
          }
        }).toList();
      }
    } catch (e) {
      debugPrint("Error fetching categories: $e");
    } finally {
      setCategoriesLoading(false);
    }
  }

  CategoryItem _mapToCategoryItem(String name, {int? id}) {
    // Map existing icons/colors or defaults
    switch (name.toLowerCase()) {
      case 'cardiologist':
      case 'cardiology':
        return CategoryItem(
          id: id,
          image: 'assets/cardiologist.png',
          name: name,
          color: const Color(0xFF5DB09C),
        );
      case 'dentist':
      case 'dentistry':
        return CategoryItem(
          id: id,
          image: 'assets/pediatrician.png', // Assuming pediatrician or using a default for now
          name: name,
          color: const Color(0xFFE0E8AA),
        );
      case 'neurologist':
      case 'neurology':
        return CategoryItem(
          id: id,
          image: 'assets/Neurology.png',
          name: name,
          color: const Color(0xFFD89CE8),
        );
      case 'dermatologist':
      case 'dermatology':
        return CategoryItem(
          id: id,
          image: 'assets/derma.png',
          name: name,
          color: const Color(0xFF9DF1C1),
        );
      case 'general':
      default:
        return CategoryItem(
          id: id,
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

  // SOS Action
  Future<void> triggerSOS(BuildContext context) async {
    try {
      // Hardcoded coordinates for demo - in real app use Geolocator
      const latitude = 37.7749;
      const longitude = -122.4194;
      
      final response = await _apiServices.createSos(latitude, longitude);
      print("response $response");
      if (response != null && response['success'] == true) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('SOS Alert Sent Successfully! Help is on the way.')),
          );
        }
      } else {
        throw Exception(response['message'] ?? 'Failed to send SOS');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending SOS: $e')),
        );
      }
    }
  }

  void setBannerIndex(int index) {
    _currentBannerIndex = index;
    notifyListeners();
  }

  // Data Sources
  List<CategoryItem> get categories => _apiCategories;

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


