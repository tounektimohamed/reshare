import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reshare/features/dashboard/presentation/providers/dashboard_provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../presentation/widgets/earnings/earnings_card.dart';
import '../../../../presentation/widgets/earnings/stats_grid.dart';
import '../../../../presentation/widgets/earnings/transaction_item.dart';
import '../providers/earnings_provider.dart';
import 'withdrawal_screen.dart';
import 'transactions_screen.dart';

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<EarningsProvider>(
      builder: (context, earningsProvider, child) {
        return Column(
          children: [
            // Header Section
            _buildHeaderSection(context, earningsProvider),

            // Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await earningsProvider.refreshEarnings();
                },
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Earnings Overview
                      const EarningsCard(),
                      const SizedBox(height: 24),

                      // Quick Stats
                      const StatsGrid(),
                      const SizedBox(height: 24),

                      // Recent Transactions
                      _buildRecentTransactions(context, earningsProvider),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeaderSection(
    BuildContext context,
    EarningsProvider earningsProvider,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // Total Balance
          Text(
            'إجمالي الرصيد',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontFamily: 'Tajawal',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${earningsProvider.stats.availableBalance.toStringAsFixed(3)} دينار',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              fontFamily: 'Tajawal',
            ),
          ),
          const SizedBox(height: 8),

          // 🔥 NOUVEAU: Afficher le solde en attente
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.pending_rounded, size: 16, color: AppColors.warning),
                const SizedBox(width: 6),
                Text(
                  '${earningsProvider.stats.pendingBalance.toStringAsFixed(3)} دينار قيد المراجعة',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.warning,
                    fontFamily: 'Tajawal',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: earningsProvider.stats.availableBalance > 0
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const WithdrawalScreen(),
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: earningsProvider.stats.availableBalance > 0
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'سحب الأموال',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TransactionsScreen(),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'سجل المعاملات',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                ),
              ),
            ],
          ),

          // 🔥 NOUVEAU: Résumé des gains
          const SizedBox(height: 16),
          // 🔥 CORRECTION : Supprimer le cast
          _buildEarningsSummary(earningsProvider.stats),
        ],
      ),
    );
  }

  // 🔥 NOUVELLE METHODE: Résumé des gains
  // 🔥 CORRECTION : Méthode dédiée pour EarningsStats
  Widget _buildEarningsSummary(EarningsStats stats) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text(
                'إجمالي الأرباح',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontFamily: 'Tajawal',
                ),
              ),
              Text(
                '${stats.totalEarnings.toStringAsFixed(2)} د',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Tajawal',
                ),
              ),
            ],
          ),
          Container(height: 30, width: 1, color: AppColors.outline),
          Column(
            children: [
              Text(
                'تم سحبه',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontFamily: 'Tajawal',
                ),
              ),
              Text(
                '${stats.totalWithdrawn.toStringAsFixed(2)} د', // 🔥 Utiliser totalWithdrawn
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Tajawal',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(
    BuildContext context,
    EarningsProvider earningsProvider,
  ) {
    final recentTransactions = earningsProvider.transactions.take(5).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'آخر المعاملات',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  fontFamily: 'Tajawal',
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TransactionsScreen(),
                    ),
                  );
                },
                child: Text(
                  'عرض الكل',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontFamily: 'Tajawal',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (recentTransactions.isEmpty)
            _buildEmptyTransactions()
          else
            Column(
              children: recentTransactions
                  .map(
                    (transaction) => TransactionItem(transaction: transaction),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyTransactions() {
    return Column(
      children: [
        Icon(
          Icons.receipt_long_rounded,
          size: 60,
          color: AppColors.textSecondary.withOpacity(0.5),
        ),
        const SizedBox(height: 16),
        Text(
          'لا توجد معاملات حالياً',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary,
            fontFamily: 'Tajawal',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'ستظهر معاملاتك هنا عند تحقيق أرباح جديدة',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary.withOpacity(0.7),
            fontFamily: 'Tajawal',
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
