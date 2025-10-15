import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reshare/features/dashboard/presentation/providers/dashboard_provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../features/earnings/presentation/providers/earnings_provider.dart';

class StatsGrid extends StatelessWidget {
  final DashboardStats? stats; // 🔥 CORRECTION: Paramètre optionnel pour DashboardStats
  
  const StatsGrid({super.key, this.stats});

  @override
  Widget build(BuildContext context) {
    // 🔥 CORRECTION: Utiliser les stats passées en paramètre OU depuis DashboardProvider
    return Consumer2<DashboardProvider, EarningsProvider>(
      builder: (context, dashboardProvider, earningsProvider, child) {
        // Priorité: stats passées en paramètre > DashboardProvider > EarningsProvider
        final effectiveStats = stats ?? dashboardProvider.stats;
        final earningsStats = earningsProvider.stats;
        
        return GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
          ),
          children: [
            _StatCard(
              title: 'أرباح هذا الأسبوع',
              value: '${effectiveStats.weeklyEarnings.toStringAsFixed(3)} د',
              subtitle: '${_calculateWeeklyGrowth(effectiveStats.weeklyEarnings, earningsStats.totalEarnings)}%',
              isPositive: effectiveStats.weeklyEarnings >= 0,
              color: AppColors.primary,
              icon: Icons.trending_up_rounded,
            ),
            _StatCard(
              title: 'نقرات صالحة',
              value: effectiveStats.weeklyClicks.toString(),
              subtitle: 'هذا الأسبوع',
              isPositive: true,
              color: AppColors.secondary,
              icon: Icons.touch_app_rounded,
            ),
            _StatCard(
              title: 'معدل التحويل',
              value: '${effectiveStats.conversionRate.toStringAsFixed(1)}%',
              subtitle: 'نقرات صالحة',
              isPositive: effectiveStats.conversionRate >= 50,
              color: AppColors.success,
              icon: Icons.auto_graph_rounded,
            ),
            _StatCard(
              title: 'متوسط الربح',
              value: '${_calculateAverageEarnings(effectiveStats.weeklyEarnings, effectiveStats.weeklyClicks)} د',
              subtitle: 'لكل نقرة',
              isPositive: true,
              color: AppColors.warning,
              icon: Icons.attach_money_rounded,
            ),
          ],
        );
      },
    );
  }

  // 🔥 NOUVELLE METHODE: Calculer la croissance hebdomadaire
  double _calculateWeeklyGrowth(double weeklyEarnings, double totalEarnings) {
    if (totalEarnings <= 0) return 0.0;
    return ((weeklyEarnings / totalEarnings) * 100).clamp(0.0, 100.0);
  }

  // 🔥 NOUVELLE METHODE: Calculer le revenu moyen par clic
  double _calculateAverageEarnings(double weeklyEarnings, int weeklyClicks) {
    if (weeklyClicks == 0) return 0.0;
    return weeklyEarnings / weeklyClicks;
  }
}

// 🔥 CORRECTION: Version alternative simplifiée utilisant seulement DashboardProvider
class DashboardStatsGrid extends StatelessWidget {
  const DashboardStatsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, dashboardProvider, child) {
        final stats = dashboardProvider.stats;
        
        return GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
          ),
          children: [
            _StatCard(
              title: 'أرباح هذا الأسبوع',
              value: '${stats.weeklyEarnings.toStringAsFixed(3)} د',
              subtitle: '${stats.weeklyGrowth.toStringAsFixed(1)}%',
              isPositive: stats.weeklyGrowth >= 0,
              color: AppColors.primary,
              icon: Icons.trending_up_rounded,
            ),
            _StatCard(
              title: 'نقرات صالحة',
              value: stats.weeklyClicks.toString(),
              subtitle: 'هذا الأسبوع',
              isPositive: true,
              color: AppColors.secondary,
              icon: Icons.touch_app_rounded,
            ),
            _StatCard(
              title: 'معدل التحويل',
              value: '${stats.conversionRate.toStringAsFixed(1)}%',
              subtitle: 'نقرات صالحة',
              isPositive: stats.conversionRate >= 50,
              color: AppColors.success,
              icon: Icons.auto_graph_rounded,
            ),
            _StatCard(
              title: 'متوسط الربح',
              value: '${_calculateAverageEarnings(stats.weeklyEarnings, stats.weeklyClicks)} د',
              subtitle: 'لكل نقرة',
              isPositive: true,
              color: AppColors.warning,
              icon: Icons.attach_money_rounded,
            ),
          ],
        );
      },
    );
  }

  double _calculateAverageEarnings(double weeklyEarnings, int weeklyClicks) {
    if (weeklyClicks == 0) return 0.0;
    return weeklyEarnings / weeklyClicks;
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final bool isPositive;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.isPositive,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon and Title
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontFamily: 'Tajawal',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Value
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Tajawal',
            ),
          ),
          const SizedBox(height: 4),

          // Subtitle
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: isPositive ? AppColors.success : AppColors.error,
              fontFamily: 'Tajawal',
            ),
          ),
        ],
      ),
    );
  }
}