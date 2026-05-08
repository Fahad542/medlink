import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/utils/trip_fare_format.dart';
import 'package:medlink/widgets/custom_app_bar_widget.dart';
import 'package:medlink/widgets/no_data_widget.dart';
import 'package:medlink/views/Patient App/sos_history/patient_sos_history_detail_view.dart';
import 'package:medlink/views/Patient App/sos_history/patient_sos_history_list_shimmer.dart';
import 'package:medlink/views/Patient App/sos_history/patient_sos_history_viewmodel.dart';
import 'package:medlink/core/localization/app_localizations.dart';

class PatientSosHistoryView extends StatefulWidget {
  const PatientSosHistoryView({super.key});

  @override
  State<PatientSosHistoryView> createState() => _PatientSosHistoryViewState();
}

class _PatientSosHistoryViewState extends State<PatientSosHistoryView> {
  late final PatientSosHistoryViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = PatientSosHistoryViewModel()..load();
    _vm.addListener(_onVm);
  }

  void _onVm() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _vm.removeListener(_onVm);
    super.dispose();
  }

  String _fmt(dynamic iso) {
    final d = DateTime.tryParse(iso?.toString() ?? '');
    if (d == null) return '—';
    return DateFormat('dd MMM yyyy, HH:mm').format(d.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: CustomAppBar(title: context.tr('patient.sos_history.title')),
      body: RefreshIndicator(
        onRefresh: _vm.refresh,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_vm.loading && _vm.items.isEmpty) {
      return const PatientSosHistoryListShimmer();
    }
    if (_vm.errorMessage != null && _vm.items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 48),
          Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            _vm.errorMessage!,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 24),
          Center(
            child: TextButton.icon(
              onPressed: _vm.refresh,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(context.tr('common.try_again')),
            ),
          ),
        ],
      );
    }
    if (_vm.items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 40),
          NoDataWidget(
            title: context.tr('patient.sos_history.empty.title'),
            subTitle: context.tr('patient.sos_history.empty.subtitle'),
            imageHeight: 160,
          ),
        ],
      );
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      itemCount: _vm.items.length,
      itemBuilder: (context, index) {
        final item = _vm.items[index];
        final status = item['status']?.toString();
        final trip = item['trip'];
        final tripMap = trip is Map ? Map<String, dynamic>.from(trip) : null;
        final subtitle = [
          if (item['emergencyType'] != null &&
              item['emergencyType'].toString().trim().isNotEmpty)
            item['emergencyType'].toString(),
          if (item['addressText'] != null &&
              item['addressText'].toString().trim().isNotEmpty)
            _ellipsis(item['addressText'].toString(), 52),
        ].join(' · ');

        String tripLine = '';
        if (tripMap != null) {
          tripLine = [
            tripMap['tripNumber']?.toString() ??
                context.tr('patient.sos_history.trip_number',
                    params: {'id': tripMap['id']}),
            tripMap['status']?.toString() ?? '',
            TripFareFormat.display(tripMap),
          ].where((e) => e.trim().isNotEmpty && e != '—').join(' · ');
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PatientSosHistoryDetailView(sos: item),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.emergency_share_rounded,
                        color: Color(0xFFDC2626),
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  context.tr('patient.sos_history.sos_number',
                                      params: {'id': item['id']}),
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: PatientSosHistoryDetailView.statusColorFor(
                                          status)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  PatientSosHistoryDetailView.statusLabelFor(
                                      status),
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: PatientSosHistoryDetailView.statusColorFor(
                                        status),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _fmt(item['createdAt']),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                          if (subtitle.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                height: 1.3,
                                color: const Color(0xFF475569),
                              ),
                            ),
                          ],
                          if (tripLine.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.local_shipping_outlined,
                                  size: 15,
                                  color: AppColors.primary.withValues(alpha: 0.85),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    tripLine,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            const SizedBox(height: 6),
                            Text(
                              context.tr('patient.sos_history.no_trip_linked'),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF94A3B8),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _ellipsis(String s, int max) {
    final t = s.trim();
    if (t.length <= max) return t;
    return '${t.substring(0, max).trim()}…';
  }
}
