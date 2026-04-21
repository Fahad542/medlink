import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/data/network/api_services.dart';
import 'package:medlink/models/in_app_notification_model.dart';
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF1E293B),
        title: Text(
          'Notifications',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
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
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 0,
          color: n.isRead ? Colors.white : AppColors.primary.withValues(alpha: 0.06),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _showNotificationDetail(n),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 18,
                        color: AppColors.primary.withValues(alpha: 0.85),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dateLine,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  timeLine,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                                Text(
                                  ' • ',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    relative,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (!n.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(top: 4, left: 6),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    n.title,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: const Color(0xFF1E293B),
                    ),
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
                  if (n.type != null && n.type!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      n.type!.replaceAll('_', ' '),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Tap for full details',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: Colors.grey.shade400,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
