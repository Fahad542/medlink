import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:medlink/views/Ambulance/profile/ambulance_earnings_view_model.dart';
import 'package:medlink/views/Ambulance/profile/ambulance_payout_settings_view.dart';
import 'package:medlink/widgets/emergency_action_dialog.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class AmbulanceEarningsView extends StatefulWidget {
  const AmbulanceEarningsView({super.key});

  @override
  State<AmbulanceEarningsView> createState() => _AmbulanceEarningsViewState();
}

class _AmbulanceEarningsViewState extends State<AmbulanceEarningsView> {
  DateTimeRange? _selectedDateRange;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AmbulanceEarningsViewModel(),
      child: Consumer<AmbulanceEarningsViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            body: RefreshIndicator(
              onRefresh: () => viewModel.fetchEarningsSummary(),
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    viewModel.isLoading
                        ? _buildHeaderShimmer(context)
                        : _buildPremiumHeader(context, viewModel),
                    const SizedBox(height: 24),
                    _buildRecentActivityList(context, viewModel),
                    const SizedBox(height: 12),
                    _buildPayoutAndWithdrawActions(context, viewModel),
                  ],
                ),
              ),
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

  Widget _buildRecentActivityList(
      BuildContext context, AmbulanceEarningsViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Recent Transactions",
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              InkWell(
                onTap: () => _selectDateRange(context),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _selectedDateRange == null
                        ? Colors.transparent
                        : AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _selectedDateRange == null
                          ? Colors.grey.withOpacity(0.3)
                          : AppColors.primary,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.date_range_rounded,
                        size: 14,
                        color: _selectedDateRange == null
                            ? Colors.grey[600]
                            : AppColors.primary,
                      ),
                      if (_selectedDateRange != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          "${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month} - ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          viewModel.transactions.isEmpty
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 20, top: 20),
                  child: Center(
                    child: Text(
                      "No transactions yet",
                      style: GoogleFonts.inter(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
              : SizedBox(
                  height: 350,
                  child: Scrollbar(
                    controller: _scrollController,
                    thickness: 6,
                    radius: const Radius.circular(10),
                    thumbVisibility: true,
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: viewModel.transactions.length,
                      padding: const EdgeInsets.only(right: 12, bottom: 20),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        return _buildTransactionItem(
                            viewModel.transactions[index]);
                      },
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildPayoutAndWithdrawActions(
      BuildContext context, AmbulanceEarningsViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          ListTile(
            tileColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: const Icon(Icons.account_balance_outlined),
            title: const Text('Payout account'),
            subtitle: Text(
              viewModel.maskedPayoutCard != null
                  ? 'Card ${viewModel.maskedPayoutCard}'
                  : 'No payout account saved',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AmbulancePayoutSettingsView()),
              );
              if (!context.mounted) return;
              await viewModel.fetchEarningsSummary();
            },
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _onRequestWithdrawal(context, viewModel),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.account_balance_wallet_outlined),
              label: const Text('Request Withdrawal'),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _onRequestWithdrawal(
      BuildContext context, AmbulanceEarningsViewModel viewModel) {
    if (!viewModel.hasPayoutAccount) {
      showDialog(
        context: context,
        builder: (_) => EmergencyActionDialog(
          title: 'Payout Account Required',
          message:
              'Please add payout information before requesting withdrawal.',
          actionText: 'Add Account',
          actionColor: AppColors.primary,
          onConfirm: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const AmbulancePayoutSettingsView()),
            ).then((_) {
              if (!mounted) return;
              viewModel.fetchEarningsSummary();
            });
          },
        ),
      );
      return;
    }
    _showWithdrawSheet(context, viewModel);
  }

  void _showWithdrawSheet(
      BuildContext context, AmbulanceEarningsViewModel viewModel) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        bool loading = false;
        return StatefulBuilder(builder: (_, setState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Amount'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: noteController,
                  decoration:
                      const InputDecoration(labelText: 'Note (optional)'),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: loading
                        ? null
                        : () async {
                            final amount =
                                double.tryParse(amountController.text.trim());
                            if (amount == null || amount <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Enter valid amount')),
                              );
                              return;
                            }
                            setState(() => loading = true);
                            final ok = await viewModel.requestWithdrawal(
                              amount: amount,
                              note: noteController.text.trim(),
                            );
                            if (!context.mounted) return;
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(ok
                                    ? 'Withdrawal request submitted'
                                    : 'Failed to submit withdrawal request'),
                              ),
                            );
                          },
                    child: loading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Submit Request'),
                  ),
                )
              ],
            ),
          );
        });
      },
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
