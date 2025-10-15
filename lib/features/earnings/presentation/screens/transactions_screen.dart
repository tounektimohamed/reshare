import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reshare/data/models/transaction_model.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../presentation/widgets/earnings/transaction_item.dart';
import '../providers/earnings_provider.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  TransactionType? _selectedFilter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل المعاملات'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Consumer<EarningsProvider>(
        builder: (context, earningsProvider, child) {
          final transactions = _selectedFilter == null
              ? earningsProvider.transactions
              : earningsProvider.transactions
                  .where((t) => t.type == _selectedFilter)
                  .toList();

          return Column(
            children: [
              // Filter Section
              _buildFilterSection(earningsProvider),
              
              // Transactions List
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await earningsProvider.refreshEarnings();
                  },
                  child: earningsProvider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : transactions.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              itemCount: transactions.length,
                              itemBuilder: (context, index) {
                                return TransactionItem(
                                  transaction: transactions[index],
                                );
                              },
                            ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterSection(EarningsProvider earningsProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // Filter Chips
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip(
                  label: 'الكل',
                  selected: _selectedFilter == null,
                  onSelected: (_) {
                    setState(() => _selectedFilter = null);
                  },
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'أرباح',
                  selected: _selectedFilter == TransactionType.earning,
                  onSelected: (_) {
                    setState(() => _selectedFilter = TransactionType.earning);
                  },
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'إحالات',
                  selected: _selectedFilter == TransactionType.referral,
                  onSelected: (_) {
                    setState(() => _selectedFilter = TransactionType.referral);
                  },
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'سحوبات',
                  selected: _selectedFilter == TransactionType.withdrawal,
                  onSelected: (_) {
                    setState(() => _selectedFilter = TransactionType.withdrawal);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required Function(bool) onSelected,
  }) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : AppColors.textPrimary,
          fontFamily: 'Tajawal',
        ),
      ),
      selected: selected,
      onSelected: onSelected,
      backgroundColor: Colors.white,
      selectedColor: AppColors.primary,
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: selected ? AppColors.primary : AppColors.outline,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_rounded,
            size: 80,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 20),
          Text(
            'لا توجد معاملات',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.textSecondary,
              fontFamily: 'Tajawal',
            ),
          ),
          const SizedBox(height: 10),
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
      ),
    );
  }
}