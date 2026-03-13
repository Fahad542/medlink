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
              subtitle: Text("Ended in **** 8899", style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 13)),
              trailing: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
                  onPressed: (){
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PayoutSettingsView()));
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
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
