import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/views/Ambulance/history/ambulance_history_view_model.dart';
import 'package:medlink/widgets/custom_app_bar_widget.dart';
import 'package:medlink/views/Ambulance/history/ambulance_trip_detail_view.dart';
import 'package:medlink/views/Ambulance/Mission/ambulance_mission_view.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class AmbulanceHistoryView extends StatelessWidget {
  const AmbulanceHistoryView({super.key});

  static AmbulanceHistoryViewModel? _ancestorViewModel(BuildContext context) {
    try {
      return Provider.of<AmbulanceHistoryViewModel>(context, listen: false);
    } on ProviderNotFoundException {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final inherited = _ancestorViewModel(context);
    const child = _AmbulanceHistoryBody();

    if (inherited != null) {
      return ChangeNotifierProvider<AmbulanceHistoryViewModel>.value(
        value: inherited,
        child: child,
      );
    }

    return ChangeNotifierProvider(
      create: (_) {
        final vm = AmbulanceHistoryViewModel();
        vm.fetchHistory();
        return vm;
      },
      child: child,
    );
  }
}

class _AmbulanceHistoryBody extends StatelessWidget {
  const _AmbulanceHistoryBody();

  @override
  Widget build(BuildContext context) {
    return Consumer<AmbulanceHistoryViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: const CustomAppBar(
            title: "Trip History",
            automaticallyImplyLeading: false,
          ),
          body: Column(
            children: [
              Expanded(
                child: viewModel.isLoading
                    ? _buildShimmerList()
                    : RefreshIndicator(
                        onRefresh: () => viewModel.fetchHistory(),
                        child: viewModel.trips.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 16),
                                itemCount: viewModel.trips.length,
                                physics: const BouncingScrollPhysics(
                                    parent: AlwaysScrollableScrollPhysics()),
                                itemBuilder: (context, index) {
                                  final trip = viewModel.trips[index];
                                  return _buildTripCard(context, trip);
                                },
                              ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "No trips yet",
            style: GoogleFonts.inter(
              color: Colors.grey[500],
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: 5,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          height: 100,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildTripCard(BuildContext context, Map<String, dynamic> trip) {
    final String rawStatus = trip['rawStatus'] ?? '';
    final bool isActive =
        ['ACCEPTED', 'ARRIVED', 'IN_PROGRESS'].contains(rawStatus);

    Color statusColor = AppColors.success;
    String statusText = "Completed";

    if (isActive) {
      statusColor = AppColors.primary;
      statusText = "Active";
    } else if (rawStatus == 'CANCELLED') {
      statusColor = Colors.red;
      statusText = "Cancelled";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            if (isActive) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AmbulanceMissionView(),
                ),
              ).then((_) {
                if (!context.mounted) return;
                context.read<AmbulanceHistoryViewModel>().fetchHistory();
              });
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AmbulanceTripDetailView(trip: trip),
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.person,
                              color: AppColors.primary, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              trip['patientName'],
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "${trip['date']} • ${trip['time']}",
                              style: GoogleFonts.inter(
                                  color: Colors.grey[500],
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          trip['earnings'],
                          style: GoogleFonts.inter(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            statusText,
                            style: GoogleFonts.plusJakartaSans(
                              color: statusColor,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[100]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_on_rounded,
                          size: 14, color: Colors.grey[400]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          trip['location'],
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.grey[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
