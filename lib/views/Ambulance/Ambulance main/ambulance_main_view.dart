import 'package:flutter/material.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/views/Ambulance/Dashboard/ambulance_dashboard_view.dart';
import 'package:medlink/views/Ambulance/history/ambulance_history_view.dart';
import 'package:medlink/views/Ambulance/profile/ambulance_profile_view.dart';
import 'package:medlink/views/Ambulance/profile/ambulance_earnings_view.dart';
import 'package:medlink/views/Ambulance/Ambulance%20main/ambulance_main_view_model.dart';
import 'package:provider/provider.dart';

class AmbulanceMainView extends StatelessWidget {
  const AmbulanceMainView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AmbulanceMainViewModel(),
      child: Consumer<AmbulanceMainViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            backgroundColor: const Color(0xFFF1F5F9), // Match Patient App
            body: Stack(
              children: [
                // 1. Main Content
                IndexedStack(
                  index: viewModel.currentIndex,
                  children: const [
                    AmbulanceDashboardView(),
                    AmbulanceEarningsView(),
                    AmbulanceHistoryView(),
                    AmbulanceProfileView(),
                  ],
                ),

                // 2. Floating Custom Navigation Bar
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 30, // Floats above bottom
                  child: Container(
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(35), // Pill shape
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildNavItem(context, viewModel, 0, Icons.grid_view_rounded, Icons.grid_view_outlined, "Home"),
                        _buildNavItem(context, viewModel, 1, Icons.account_balance_wallet_rounded, Icons.account_balance_wallet_outlined, "Earnings"),
                        _buildNavItem(context, viewModel, 2, Icons.history_rounded, Icons.history_outlined, "History"),
                        _buildNavItem(context, viewModel, 3, Icons.person_rounded, Icons.person_outline, "Profile"),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, AmbulanceMainViewModel viewModel, int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isSelected = viewModel.currentIndex == index;
    return GestureDetector(
      onTap: () {
        viewModel.setIndex(index);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.fastOutSlowIn,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: isSelected
            ? BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(25),
              )
            : BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(25),
              ),
        child: Row(
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: isSelected ? Colors.white : Colors.grey,
              size: 26,
            ),
              if (isSelected) ...[
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
          ],
        ),
      ),
    );
  }
}
