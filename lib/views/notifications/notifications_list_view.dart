import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/data/network/api_services.dart';
import 'package:medlink/models/in_app_notification_model.dart';
import 'package:medlink/widgets/custom_app_bar_widget.dart';
import 'package:medlink/widgets/notification_detail_sheet.dart';
import 'package:provider/provider.dart';
import 'package:medlink/views/Patient App/home/home_viewmodel.dart';
import 'package:medlink/views/doctor/Dashboard/doctor_dashboard_view_model.dart';

enum NotificationPortal { patient, doctor }

/// Lists in-app notifications from `GET /patient/notifications` or `GET /doctor/notifications`.
class NotificationsListView extends StatefulWidget {
  final NotificationPortal portal;

  const NotificationsListView({super.key, required this.portal});

  @override
  State<NotificationsListView> createState() => _NotificationsListViewState();
}

class _NotificationsListViewState extends State<NotificationsListView> {
  final ApiServices _api = ApiServices();
  List<InAppNotificationModel> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  /// Open screen → mark all read on server → reload list → sync dashboard badge.
  Future<void> _bootstrap() async {
    await _markAllNotificationsReadOnServer();
    await _load();
    await _syncBadgeWithParent();
  }

  Future<void> _markAllNotificationsReadOnServer() async {
    try {
      if (widget.portal == NotificationPortal.patient) {
        await _api.markAllPatientNotificationsRead();
      } else {
        await _api.markAllDoctorNotificationsRead();
      }
    } catch (e) {
      debugPrint('[NotificationsList] mark all read failed: $e');
    }
  }

  Future<void> _syncBadgeWithParent() async {
    if (!mounted) return;
    try {
      if (widget.portal == NotificationPortal.patient) {
        await context.read<HomeViewModel>().fetchUnreadNotificationsCount();
      } else {
        await context
            .read<DoctorDashboardViewModel>()
            .fetchUnreadNotificationsCount();
      }
    } catch (_) {
      // Notifications opened outside patient/doctor shell — skip badge sync.
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = widget.portal == NotificationPortal.patient
          ? await _api.getPatientNotifications(limit: 80)
          : await _api.getDoctorNotifications(limit: 80);

      if (!mounted) return;

      if (res is! Map || res['success'] != true) {
        setState(() {
          _loading = false;
          _error =
              res is Map ? (res['message']?.toString() ?? 'Could not load') : 'Could not load';
        });
        return;
      }

      final data = res['data'];
      if (data is! Map) {
        setState(() {
          _loading = false;
          _items = [];
        });
        unawaited(_syncBadgeWithParent());
        return;
      }

      final rawList = data['notifications'];
      final list = rawList is List
          ? rawList
              .whereType<Map>()
              .map((e) =>
                  InAppNotificationModel.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : <InAppNotificationModel>[];

      setState(() {
        _items = list;
        _loading = false;
      });
      unawaited(_syncBadgeWithParent());
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  /// Short relative label when recent, else calendar date + time.
  static String _relativeOrFullDate(DateTime dt) {
    final local = dt.toLocal();
    final now = DateTime.now();
    final diff = now.difference(local);
    if (diff.isNegative || diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24 && local.day == now.day && local.month == now.month && local.year == now.year) {
      return '${diff.inHours} hr ago';
    }
    if (diff.inDays < 7) return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    return DateFormat('EEE, d MMM yyyy • h:mm a').format(local);
  }

  void _showNotificationDetail(InAppNotificationModel n) {
    showNotificationDetailSheet(
      context,
      n,
      onMarkRead:
          n.isRead ? null : (String id) => _markNotificationReadOnServer(id),
    );
  }

  /// PATCH one notification as read; updates list row + dashboard badge.
  Future<void> _markNotificationReadOnServer(String id) async {
    try {
      if (widget.portal == NotificationPortal.patient) {
        await _api.markPatientNotificationRead(id);
      } else {
        await _api.markDoctorNotificationRead(id);
      }
      if (!mounted) return;
      setState(() {
        final i = _items.indexWhere((e) => e.id == id);
        if (i != -1) {
          _items[i] = _items[i].copyWith(isRead: true);
        }
      });
      await _syncBadgeWithParent();
    } catch (e) {
      debugPrint('[NotificationsList] mark one read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: const CustomAppBar(
        title: 'Notifications',
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return _buildNotificationsShimmer();
    }
    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.red[700], fontSize: 14),
            ),
          ),
        ],
      );
    }
    if (_items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          Column(
            children: [
              Icon(Icons.notifications_none_rounded,
                  size: 64, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                'No notifications yet',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We\'ll notify you about appointments and updates.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final n = _items[index];
        final local = n.createdAt.toLocal();
        final dateLine = DateFormat('EEE, d MMM yyyy').format(local);
        final timeLine = DateFormat('h:mm a').format(local);
        final relative = _relativeOrFullDate(n.createdAt);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          color: n.isRead ? Colors.white : const Color(0xFFF5FFFD),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: n.isRead
                  ? Colors.grey.withValues(alpha: 0.15)
                  : AppColors.primary.withValues(alpha: 0.2),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              relative,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                          Text(
                            ' • ',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            timeLine,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          dateLine,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (!n.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(top: 4),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.notifications_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        n.title,
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  n.body,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 1.35,
                    color: Colors.grey[800],
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationsShimmer() {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: 6,
      itemBuilder: (context, _) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[200]!,
            highlightColor: Colors.grey[50]!,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 130,
                            height: 11,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                width: 72,
                                height: 11,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                width: 56,
                                height: 9,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: MediaQuery.of(context).size.width * 0.42,
                  height: 15,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: MediaQuery.of(context).size.width * 0.55,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}
