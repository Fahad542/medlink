import 'package:flutter/material.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medlink/views/doctor/payout_settings_view.dart';
import 'package:intl/intl.dart';

import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:medlink/views/doctor/Doctor%20earnings/doctor_earnings_view_model.dart';
import 'package:medlink/widgets/no_data_widget.dart';

class DoctorEarningsView extends StatelessWidget {
  final bool showBackButton;
  const DoctorEarningsView({super.key, this.showBackButton = false});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DoctorEarningsViewModel(),
      child: Consumer<DoctorEarningsViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            body: Column(
              children: [
                _buildPremiumHeader(context, viewModel),
                Expanded(
                  child: _buildBody(context, viewModel),
                ),
              ],
            ),
            bottomNavigationBar: _buildPayoutAndWithdrawActions(context, viewModel),
          );
        },
      ),
    );
  }

  Widget _buildPremiumHeader(BuildContext context, DoctorEarningsViewModel viewModel) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF00695C), AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 44,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (showBackButton)
                    Positioned(
                      left: 0,
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  Text(
                    "Total Balance",
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            viewModel.isLoading
                ? Shimmer.fromColors(
                    baseColor: Colors.white.withOpacity(0.5),
                    highlightColor: Colors.white,
                    child: Container(
                      height: 32,
                      width: 140,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  )
                : Text(
                    viewModel.formatCurrency(viewModel.totalBalance),
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
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
              child: Icon(icon, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    value,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, DoctorEarningsViewModel viewModel) {
    final (startDateLabel, endDateLabel) = _deriveDateRange(viewModel);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Transform.translate(
            offset: const Offset(0, -20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _dateKpiItem(
                      context,
                      "Start Date",
                      startDateLabel,
                      onTap: () => _openCalendarPicker(context),
                    ),
                  ),
                  Container(width: 1, height: 36, color: Colors.grey[200]),
                  Expanded(
                    child: _dateKpiItem(
                      context,
                      "End Date",
                      endDateLabel,
                      onTap: () => _openCalendarPicker(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                "Recent Transactions",
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await viewModel.fetchBalance();
                await viewModel.fetchPayoutAccount();
              },
              color: AppColors.primary,
              child: viewModel.isLoading
                  ? _buildTransactionListShimmer()
                  : viewModel.recentTransactions.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: ClampingScrollPhysics(),
                          ),
                          children: const [
                            SizedBox(height: 24),
                            NoDataWidget(
                              title: "No Transactions",
                              subTitle: "You have no recent transactions yet.",
                              imageHeight: 120,
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 16),
                          physics: const ClampingScrollPhysics(),
                          itemCount: viewModel.recentTransactions.length,
                          itemBuilder: (context, index) {
                            return _buildTransactionItem(
                                viewModel.recentTransactions[index], viewModel);
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionListShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      physics: const ClampingScrollPhysics(),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 9,
                        width: 95,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 14,
                        width: 125,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 10,
                        width: 145,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      height: 10,
                      width: 70,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 14,
                      width: 90,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _dateKpiItem(
    BuildContext context,
    String label,
    String value, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.grey[500],
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCalendarPicker(BuildContext context) async {
    await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
  }

  (String, String) _deriveDateRange(DoctorEarningsViewModel viewModel) {
    DateTime? minDate;
    DateTime? maxDate;
    for (final tx in viewModel.recentTransactions) {
      if (tx is! Map) continue;
      final m = Map<String, dynamic>.from(tx);
      final raw = m['date'] ?? m['createdAt'] ?? m['created_at'];
      DateTime? dt;
      if (raw is String) dt = DateTime.tryParse(raw);
      if (raw is Map && raw['\$date'] != null) {
        dt = DateTime.tryParse(raw['\$date'].toString());
      }
      if (dt == null) continue;
      if (minDate == null || dt.isBefore(minDate)) minDate = dt;
      if (maxDate == null || dt.isAfter(maxDate)) maxDate = dt;
    }
    if (minDate == null || maxDate == null) return ("N/A", "N/A");
    final fmt = DateFormat('MMM d, yyyy');
    return (fmt.format(minDate.toLocal()), fmt.format(maxDate.toLocal()));
  }

  Widget _buildPayoutAndWithdrawActions(
      BuildContext context, DoctorEarningsViewModel viewModel) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 14,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Payout Settings",
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.account_balance_rounded,
                      color: AppColors.primary, size: 20),
                ),
                title: Text("Bank Account",
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: Text(
                  viewModel.maskedPayoutCard != null
                      ? "Card ${viewModel.maskedPayoutCard}"
                      : "No payout card saved",
                  style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 12),
                ),
                trailing: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: IconButton(
                    icon:
                        const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const PayoutSettingsView()),
                      );
                      if (!context.mounted) return;
                      await viewModel.fetchPayoutAccount();
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _onRequestWithdrawal(context, viewModel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  "Request Withdrawal",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onRequestWithdrawal(
      BuildContext context, DoctorEarningsViewModel viewModel) {
    if (!viewModel.hasPayoutAccount) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Add payout account first"),
          content: const Text(
              "Please add your payout account information before requesting a withdrawal."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Later"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PayoutSettingsView(),
                  ),
                );
              },
              child: const Text("Add Account"),
            ),
          ],
        ),
      );
      return;
    }
    _showWithdrawalRequestSheet(context, viewModel);
  }

  void _showWithdrawalRequestSheet(
      BuildContext context, DoctorEarningsViewModel viewModel) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF8FAFC),
      builder: (ctx) {
        bool submitting = false;
        return StatefulBuilder(
          builder: (ctx, setState) => Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildPayoutStyleField(
                  label: "Amount",
                  hint: "Enter withdrawal amount",
                  controller: amountController,
                  icon: Icons.payments_outlined,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                if (viewModel.availableToWithdraw > 0 &&
                    viewModel.availableToWithdraw < viewModel.totalBalance)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Pending requests: you can request up to ${viewModel.formatCurrency(viewModel.availableToWithdraw)} until they are approved.',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                _buildPayoutStyleField(
                  label: "Note (optional)",
                  hint: "Add a short note",
                  controller: noteController,
                  icon: Icons.sticky_note_2_outlined,
                  maxLines: 2,
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: submitting
                        ? null
                        : () async {
                            final amount =
                                double.tryParse(amountController.text.trim());
                            if (amount == null || amount <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text("Enter a valid amount")),
                              );
                              return;
                            }
                            setState(() => submitting = true);
                            final success = await viewModel.requestWithdrawal(
                              amount: amount,
                              note: noteController.text.trim(),
                            );
                            if (!context.mounted) return;
                            Navigator.pop(ctx);
                            if (success) await viewModel.fetchBalance();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? "Withdrawal request submitted"
                                      : "Failed to submit withdrawal request",
                                ),
                              ),
                            );
                          },
                    child: submitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            "Submit Request",
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPayoutStyleField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w400,
              fontSize: 15,
              color: Colors.black87,
            ),
            cursorColor: AppColors.primary,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText: hint,
              hintStyle: GoogleFonts.inter(
                color: Colors.grey[400],
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.all(12),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 18),
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(dynamic transaction, DoctorEarningsViewModel viewModel) {
    if (transaction is! Map) return const SizedBox.shrink();
    final m = Map<String, dynamic>.from(transaction);
    bool isCredit = m['isCredit'] ?? true;
    double amount = (m['amount'] is num)
        ? (m['amount'] as num).toDouble()
        : double.tryParse(m['amount']?.toString() ?? '') ?? 0.0;
    String dateStr = (m['date'] ?? m['createdAt'] ?? m['created_at'])?.toString() ?? '';
    String title = (m['title'] ?? m['type'] ?? m['description'] ?? 'Consultation')
        .toString();
    final formattedDate = dateStr.isNotEmpty ? viewModel.formatDate(dateStr) : '—';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isCredit ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: isCredit ? Colors.green : Colors.red,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formattedDate,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: Colors.grey[500],
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                "${isCredit ? '+' : '-'}${viewModel.formatCurrency(amount)}",
                textAlign: TextAlign.end,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isCredit ? Colors.green : Colors.red,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
