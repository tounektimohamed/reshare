import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reshare/data/models/referral_model.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../providers/referral_provider.dart';

class ReferralsScreen extends StatelessWidget {
  const ReferralsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ReferralProvider>(
      builder: (context, referralProvider, child) {
        return Column(
          children: [
            // Header Section
            _buildHeaderSection(referralProvider),

            // Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await referralProvider.refreshReferrals();
                },
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildReferralStats(referralProvider),
                      const SizedBox(height: 24),
                    _buildReferralStatusDetails(referralProvider), // NOUVELLE SECTION
                      _buildShareSection(referralProvider),
                      const SizedBox(height: 24),
                      _buildReferralTiers(),
                      const SizedBox(height: 24),
                      _buildReferralsList(referralProvider),
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

  // ---------------- Header Section ----------------
  Widget _buildHeaderSection(ReferralProvider referralProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          Text(
            'برنامج الإحالة',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontFamily: 'Tajawal',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ادعُ أصدقاءك واكسب 0.6 دينار لكل صديق',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontFamily: 'Tajawal',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ---------------- Stats Section ----------------
  Widget _buildReferralStats(ReferralProvider referralProvider) {
  final statusCounts = referralProvider.referralStatusCounts;
  
  return Container(
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
      children: [
        // Ligne 1: Statistiques principales
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              value: statusCounts['total'].toString(),
              label: 'إجمالي الإحالات',
              icon: Icons.people_rounded,
              color: AppColors.primary,
            ),
            _buildStatItem(
              value: statusCounts['completed'].toString(),
              label: 'مكتملة',
              icon: Icons.check_circle_rounded,
              color: AppColors.success,
            ),
            _buildStatItem(
              value: '${referralProvider.stats.totalEarnings.toStringAsFixed(2)} د',
              label: 'أرباح الإحالة',
              icon: Icons.attach_money_rounded,
              color: AppColors.secondary,
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Ligne 2: Statistiques de statut détaillées
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              value: statusCounts['pending'].toString(),
              label: 'قيد المراجعة',
              icon: Icons.pending_rounded,
              color: AppColors.warning,
            ),
            _buildStatItem(
              value: referralProvider.invalidReferralsCount.toString(),
              label: 'غير صالحة',
              icon: Icons.cancel_rounded,
              color: AppColors.error,
            ),
            _buildStatItem(
              value: '${referralProvider.stats.successRate.toStringAsFixed(1)}%',
              label: 'معدل النجاح',
              icon: Icons.trending_up_rounded,
              color: AppColors.info,
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Barre de progression du taux de réussite
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'توزيع الإحالات',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                  Text(
                    '${statusCounts['completed']}/${statusCounts['total']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildReferralDistributionBar(statusCounts),
            ],
          ),
        ),
      ],
    ),
  );
}
Widget _buildReferralStatusDetails(ReferralProvider referralProvider) {
  final statusCounts = referralProvider.referralStatusCounts;
  
  return Container(
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
        Text(
          'تفاصيل حالة الإحالات',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            fontFamily: 'Tajawal',
          ),
        ),
        const SizedBox(height: 16),
        
        // Légende des couleurs
        _buildStatusLegend(),
        const SizedBox(height: 16),
        
        // Détails des statuts
        Column(
          children: [
            _buildStatusDetailItem(
              count: statusCounts['completed']!,
              label: 'مكتملة ونشطة',
              description: 'إحالات مكتملة وتحقق الأرباح',
              color: AppColors.success,
              icon: Icons.check_circle_rounded,
            ),
            const SizedBox(height: 12),
            _buildStatusDetailItem(
              count: statusCounts['pending']!,
              label: 'قيد المراجعة',
              description: 'إحالات تنتظر إكمال النقرات المطلوبة',
              color: AppColors.warning,
              icon: Icons.pending_rounded,
            ),
            const SizedBox(height: 12),
            _buildStatusDetailItem(
              count: referralProvider.invalidReferralsCount,
              label: 'غير صالحة',
              description: 'إحالات ملغاة أو منتهية الصلاحية',
              color: AppColors.error,
              icon: Icons.cancel_rounded,
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _buildStatusLegend() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceAround,
    children: [
      _buildLegendItem(AppColors.success, 'مكتملة'),
      _buildLegendItem(AppColors.warning, 'قيد المراجعة'),
      _buildLegendItem(AppColors.error, 'غير صالحة'),
    ],
  );
}

Widget _buildLegendItem(Color color, String label) {
  return Row(
    children: [
      Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 6),
      Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
          fontFamily: 'Tajawal',
        ),
      ),
    ],
  );
}

Widget _buildStatusDetailItem({
  required int count,
  required String label,
  required String description,
  required Color color,
  required IconData icon,
}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color.withOpacity(0.05),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                  Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontFamily: 'Tajawal',
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
Widget _buildReferralDistributionBar(Map<String, int> statusCounts) {
  final total = statusCounts['total']!;
  if (total == 0) {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  final completedPercent = (statusCounts['completed']! / total) * 100;
  final pendingPercent = (statusCounts['pending']! / total) * 100;
  final invalidPercent = (statusCounts['invalid']! / total) * 100;

  return Container(
    height: 8,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(4),
    ),
    child: Row(
      children: [
        // Partie complétée (verte)
        Expanded(
          flex: completedPercent.round(),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.success,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(4),
              ),
            ),
          ),
        ),
        
        // Partie en attente (orange)
        Expanded(
          flex: pendingPercent.round(),
          child: Container(
            color: AppColors.warning,
          ),
        ),
        
        // Partie invalide (rouge)
        Expanded(
          flex: invalidPercent.round(),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(4),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildStatItem({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Tajawal',
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontFamily: 'Tajawal',
          ),
        ),
      ],
    );
  }

  // ---------------- Share Section ----------------
  Widget _buildShareSection(ReferralProvider referralProvider) {
    return Container(
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
          Text(
            'شارك رابط الإحالة',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontFamily: 'Tajawal',
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.outline),
            ),
            child: Column(
              children: [
                Text(
                  'كود الإحالة الخاص بك',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontFamily: 'Tajawal',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  referralProvider.stats.referralCode,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontFamily: 'Tajawal',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: referralProvider.copyReferralLink,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.copy_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('نسخ الرابط',
                          style: TextStyle(fontFamily: 'Tajawal')),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: referralProvider.shareReferralLink,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.share_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('مشاركة', style: TextStyle(fontFamily: 'Tajawal')),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------- Referral Tiers ----------------
  Widget _buildReferralTiers() {
    return Container(
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
          Text(
            'مستويات الإحالة',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontFamily: 'Tajawal',
            ),
          ),
          const SizedBox(height: 16),
          _buildTierItem(
            level: 'المستوى 1',
            reward: '0.6 دينار',
            requirement: 'لكل صديق حتى 10 أصدقاء',
            color: AppColors.primary,
          ),
          const SizedBox(height: 12),
          _buildTierItem(
            level: 'المستوى 2',
            reward: '0.8 دينار',
            requirement: 'لكل صديق من 11 إلى 20 صديق',
            color: AppColors.secondary,
          ),
          const SizedBox(height: 12),
          _buildTierItem(
            level: 'المستوى 3',
            reward: '1.0 دينار',
            requirement: 'لكل صديق بعد 20 صديق',
            color: AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildTierItem({
    required String level,
    required String reward,
    required String requirement,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.star_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(level,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontFamily: 'Tajawal')),
                Text('$reward - $requirement',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontFamily: 'Tajawal')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Referrals List ----------------
  Widget _buildReferralsList(ReferralProvider referralProvider) {
    final referrals = referralProvider.referrals;

    return Container(
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
          Text(
            'الإحالات الحديثة',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontFamily: 'Tajawal',
            ),
          ),
          const SizedBox(height: 16),
          if (referrals.isEmpty)
            _buildEmptyReferrals()
          else
            Column(
              children: referrals
                  .take(5)
                  .map((referral) => _buildReferralItem(referral))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildReferralItem(ReferralModel referral) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getStatusColor(referral.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(_getStatusIcon(referral.status),
                color: _getStatusColor(referral.status), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('إحالة ${referral.referralCode}',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Tajawal')),
                Text(_getStatusText(referral),
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontFamily: 'Tajawal')),
              ],
            ),
          ),
          Text('${referral.rewardAmount} د',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  fontFamily: 'Tajawal')),
        ],
      ),
    );
  }

  Widget _buildEmptyReferrals() {
    return Column(
      children: [
        Icon(Icons.people_outline_rounded,
            size: 60, color: AppColors.textSecondary.withOpacity(0.5)),
        const SizedBox(height: 16),
        Text('لا توجد إحالات حالياً',
            style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                fontFamily: 'Tajawal')),
        const SizedBox(height: 8),
        Text('ادعُ أصدقاءك لبدء كسب مكافآت الإحالة',
            style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary.withOpacity(0.7),
                fontFamily: 'Tajawal'),
            textAlign: TextAlign.center),
      ],
    );
  }

  // ---------------- Helpers ----------------
  Color _getStatusColor(ReferralStatus status) {
    switch (status) {
      case ReferralStatus.pending:
        return AppColors.warning;
      case ReferralStatus.completed:
        return AppColors.success;
      case ReferralStatus.paid:
        return AppColors.primary;
      case ReferralStatus.expired:
        return AppColors.error;
      case ReferralStatus.cancelled:
        return AppColors.textSecondary;
    }
  }

  IconData _getStatusIcon(ReferralStatus status) {
    switch (status) {
      case ReferralStatus.pending:
        return Icons.pending_rounded;
      case ReferralStatus.completed:
        return Icons.check_circle_rounded;
      case ReferralStatus.paid:
        return Icons.attach_money_rounded;
      case ReferralStatus.expired:
        return Icons.timelapse_rounded;
      case ReferralStatus.cancelled:
        return Icons.cancel_rounded;
    }
  }

  String _getStatusText(ReferralModel referral) {
    switch (referral.status) {
      case ReferralStatus.pending:
        return '${referral.remainingClicks} نقرات متبقية';
      case ReferralStatus.completed:
        return 'مكتمل - في انتظار الدفع';
      case ReferralStatus.paid:
        return 'تم الدفع';
      case ReferralStatus.expired:
        return 'منتهي الصلاحية';
      case ReferralStatus.cancelled:
        return 'ملغى';
    }
  }
}
