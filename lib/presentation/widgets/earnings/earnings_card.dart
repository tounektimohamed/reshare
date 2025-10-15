import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../features/earnings/presentation/providers/earnings_provider.dart';

class EarningsCard extends StatelessWidget {
  const EarningsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<EarningsProvider>(
      builder: (context, earningsProvider, child) {
        final stats = earningsProvider.stats;
        
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Total Earnings
              Text(
                'إجمالي الأرباح',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.9),
                  fontFamily: 'Tajawal',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${stats.totalEarnings.toStringAsFixed(3)} دينار',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Tajawal',
                ),
              ),
              const SizedBox(height: 20),

              // Breakdown
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildEarningItem(
                    value: stats.availableBalance,
                    label: 'متاح',
                    color: Colors.white,
                  ),
                  _buildEarningItem(
                    value: stats.pendingBalance,
                    label: 'قيد الانتظار',
                    color: Colors.white.withOpacity(0.8),
                  ),
                  _buildEarningItem(
                    value: stats.monthlyEarnings,
                    label: 'هذا الشهر',
                    color: Colors.white.withOpacity(0.8),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEarningItem({
    required double value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          '${value.toStringAsFixed(2)} د',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
            fontFamily: 'Tajawal',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color.withOpacity(0.8),
            fontFamily: 'Tajawal',
          ),
        ),
      ],
    );
  }
}