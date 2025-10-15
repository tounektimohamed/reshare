import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/transaction_model.dart';

class TransactionItem extends StatelessWidget {
  final TransactionModel transaction;

  const TransactionItem({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getTypeColor(transaction.type).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              _getTypeIcon(transaction.type),
              color: _getTypeColor(transaction.type),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getTypeText(transaction.type),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Tajawal',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  transaction.description ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontFamily: 'Tajawal',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(transaction.createdAt),
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary.withOpacity(0.7),
                    fontFamily: 'Tajawal',
                  ),
                ),
              ],
            ),
          ),

          // Amount and Status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${transaction.amount.toStringAsFixed(2)} د',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _getAmountColor(transaction.type),
                  fontFamily: 'Tajawal',
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getStatusColor(transaction.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getStatusText(transaction.status),
                  style: TextStyle(
                    fontSize: 10,
                    color: _getStatusColor(transaction.status),
                    fontFamily: 'Tajawal',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(TransactionType type) {
    switch (type) {
      case TransactionType.earning:
        return AppColors.success;
      case TransactionType.referral:
        return AppColors.primary;
      case TransactionType.withdrawal:
        return AppColors.secondary;
      case TransactionType.refund:
        return AppColors.warning;
      case TransactionType.bonus:
        return AppColors.info;
    }
  }

  IconData _getTypeIcon(TransactionType type) {
    switch (type) {
      case TransactionType.earning:
        return Icons.touch_app_rounded;
      case TransactionType.referral:
        return Icons.people_rounded;
      case TransactionType.withdrawal:
        return Icons.account_balance_wallet_rounded;
      case TransactionType.refund:
        return Icons.replay_rounded;
      case TransactionType.bonus:
        return Icons.card_giftcard_rounded;
    }
  }

  String _getTypeText(TransactionType type) {
    switch (type) {
      case TransactionType.earning:
        return 'ربح من نقرة';
      case TransactionType.referral:
        return 'مكافأة إحالة';
      case TransactionType.withdrawal:
        return 'سحب أموال';
      case TransactionType.refund:
        return 'استرداد أموال';
      case TransactionType.bonus:
        return 'مكافأة إضافية';
    }
  }

  Color _getAmountColor(TransactionType type) {
    switch (type) {
      case TransactionType.earning:
      case TransactionType.referral:
      case TransactionType.bonus:
        return AppColors.success;
      case TransactionType.withdrawal:
      case TransactionType.refund:
        return AppColors.error;
    }
  }

  Color _getStatusColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.pending:
        return AppColors.warning;
      case TransactionStatus.processing:
        return AppColors.info;
      case TransactionStatus.completed:
        return AppColors.success;
      case TransactionStatus.failed:
        return AppColors.error;
      case TransactionStatus.cancelled:
        return AppColors.textSecondary;
    }
  }

  String _getStatusText(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.pending:
        return 'قيد الانتظار';
      case TransactionStatus.processing:
        return 'قيد المعالجة';
      case TransactionStatus.completed:
        return 'مكتمل';
      case TransactionStatus.failed:
        return 'فاشل';
      case TransactionStatus.cancelled:
        return 'ملغى';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}