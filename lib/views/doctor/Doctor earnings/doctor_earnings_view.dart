import 'package:flutter/material.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medlink/views/doctor/payout_settings_view.dart';

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
            body: SingleChildScrollView(
              child: Column(
                children: [
                  _buildPremiumHeader(context, viewModel),
                  const SizedBox(height: 24),
                  _buildBody(context, viewModel),
                ],
              ),
            ),
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
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
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
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
            const SizedBox(height: 20),
            
            // Stat Cards
            Row(
              children: [
                _buildStatCard("Today", viewModel.isLoading ? "..." : viewModel.formatCurrency(viewModel.todayEarning), Icons.today_rounded),
                const SizedBox(width: 12),
                _buildStatCard("This Week", viewModel.isLoading ? "..." : viewModel.formatCurrency(viewModel.thisWeekEarning), Icons.calendar_view_week_rounded),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
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
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
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

  Widget _buildBody(BuildContext context, DoctorEarningsViewModel viewModel) {
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
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("This Month", style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.bold)),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          SizedBox(
            height: 350,
            child: viewModel.isLoading
              ? const Center(child: CircularProgressIndicator())
              : viewModel.recentTransactions.isEmpty
                  ? const NoDataWidget(
                      title: "No Transactions",
                      subTitle: "You have no recent transactions yet.",
                      imageHeight: 120, // Smaller image to fit the 350 height box
                    )
                  : ListView.builder(
                      padding: EdgeInsets.zero,
                      physics: const BouncingScrollPhysics(),
                      itemCount: viewModel.recentTransactions.length,
                      itemBuilder: (context, index) {
                        return _buildTransactionItem(viewModel.recentTransactions[index], viewModel);
                      },
                    ),
          ),
          
          const SizedBox(height: 32),
          
           Text(
            "Payout Settings",
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Container(
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
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.account_balance_rounded, color: AppColors.primary),
              ),
              title: Text("Bank Account", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15)),
              subtitle: Text(
                viewModel.maskedPayoutCard != null
                    ? "Card ${viewModel.maskedPayoutCard}"
                    : "No payout card saved",
                style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 13),
              ),
              trailing: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
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
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _onRequestWithdrawal(context, viewModel),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.account_balance_wallet_outlined),
              label: const Text("Request Withdrawal"),
            ),
          ),
          const SizedBox(height: 16),
        ],
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
                TextField(
                  controller: amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: "Amount",
                    hintText: "Enter withdrawal amount",
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: noteController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: "Note (optional)",
                  ),
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
                        : const Text("Submit Request"),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTransactionItem(dynamic transaction, DoctorEarningsViewModel viewModel) {
    bool isCredit = transaction['isCredit'] ?? true;
    double amount = (transaction['amount'] ?? 0).toDouble();
    String user = transaction['user'] ?? 'Unknown User';
    String dateStr = transaction['date'] ?? '';
    String title = transaction['title'] ?? 'Consultation';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isCredit ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: isCredit ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "$user • ${dateStr != '' ? viewModel.formatDate(dateStr) : ''}",
                  style: GoogleFonts.inter(
                    color: Colors.grey[500],
                    fontSize: 12,
                    fontWeight: FontWeight.w500
                  ),
                ),
              ],
            ),
          ),
          Text(
            "${isCredit ? '+' : '-'}${viewModel.formatCurrency(amount)}",
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isCredit ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
