import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:medlink/views/Ambulance/profile/ambulance_earnings_view_model.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class AmbulanceEarningsView extends StatefulWidget {
  const AmbulanceEarningsView({super.key});

  @override
  State<AmbulanceEarningsView> createState() => _AmbulanceEarningsViewState();
}

class _AmbulanceEarningsViewState extends State<AmbulanceEarningsView> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AmbulanceEarningsViewModel(),
      child: Consumer<AmbulanceEarningsViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                viewModel.isLoading
                    ? _buildHeaderShimmer(context)
                    : _buildPremiumHeader(context, viewModel),
                Expanded(
                  child: _buildTransactionsScrollable(context, viewModel),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderShimmer(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 24),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 80,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: 140,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumHeader(
      BuildContext context, AmbulanceEarningsViewModel viewModel) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF00695C), AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Text(
            "Total Balance",
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            viewModel.totalBalanceFormatted,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildStatCard("Today", viewModel.earningsTodayFormatted,
                  Icons.today_rounded),
              const SizedBox(width: 12),
              _buildStatCard(
                  "This Week",
                  viewModel.earningsThisWeekFormatted,
                  Icons.calendar_view_week_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsScrollable(
      BuildContext context, AmbulanceEarningsViewModel viewModel) {
    final bottomInset = MediaQuery.paddingOf(context).bottom + 96;
    const listPhysics = AlwaysScrollableScrollPhysics(
      parent: BouncingScrollPhysics(),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: Text(
            "Recent Transactions",
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => viewModel.fetchEarningsSummary(silent: true),
            color: AppColors.primary,
            edgeOffset: 8,
            child: viewModel.transactions.isEmpty
                ? ListView(
                    physics: listPhysics,
                    padding: EdgeInsets.fromLTRB(20, 0, 20, bottomInset),
                    children: [
                      SizedBox(
                        height: 200,
                        child: Center(
                          child: Text(
                            "No transactions yet",
                            style: GoogleFonts.inter(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: listPhysics,
                    padding: EdgeInsets.fromLTRB(20, 0, 20, bottomInset),
                    itemCount: viewModel.transactions.length,
                    itemBuilder: (context, index) {
                      return _buildTransactionItem(
                          viewModel.transactions[index]);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  String _formatTransactionDate(dynamic transactionDate) {
    if (transactionDate == null) return '—';
    DateTime? dt;
    if (transactionDate is String) {
      dt = DateTime.tryParse(transactionDate);
    } else if (transactionDate is Map && transactionDate['\$date'] != null) {
      dt = DateTime.tryParse(transactionDate['\$date'].toString());
    }
    if (dt == null) return transactionDate.toString();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(dt.year, dt.month, dt.day);
    if (dateOnly == today) {
      return 'Today, ${DateFormat('h:mm a').format(dt)}';
    }
    return DateFormat('MMM d, h:mm a').format(dt);
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    final tripNumber = transaction['tripNumber']?.toString() ??
        'Trip #${transaction['id'] ?? '—'}';
    final amount = transaction['amount'];
    final amountNum =
        amount is num ? amount : (num.tryParse(amount?.toString() ?? '0') ?? 0);
    final amountStr = amountNum == amountNum.roundToDouble()
        ? amountNum.toInt().toString()
        : amountNum.toStringAsFixed(2);
    final source = transaction['source']?.toString() ?? 'Wallet';
    final dateStr = _formatTransactionDate(transaction['transactionDate']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_downward_rounded,
                color: Colors.green, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tripNumber,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateStr,
                  style: GoogleFonts.inter(
                    color: Colors.grey[500],
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+\$$amountStr',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                source,
                style: GoogleFonts.inter(
                  color: Colors.grey[400],
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
