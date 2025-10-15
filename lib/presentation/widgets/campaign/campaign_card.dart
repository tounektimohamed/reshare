import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/campaign_model.dart';
import '../../../features/campaigns/presentation/providers/campaign_provider.dart';

class CampaignCard extends StatelessWidget {
  final CampaignModel campaign;

  const CampaignCard({super.key, required this.campaign});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Campaign Header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.campaign,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        campaign.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _getCampaignTypeText(campaign.type),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Campaign Description
            Text(
              campaign.description,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),

            // Campaign Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StatItem(
                  icon: Icons.touch_app,
                  value: '${campaign.achievedClicks}/${campaign.targetClicks}',
                  label: 'النقرات',
                ),
                _StatItem(
                  icon: Icons.attach_money,
                  value: '${campaign.participantEarnings.toStringAsFixed(3)}',
                  label: 'دينار/نقرة',
                ),
                _StatItem(
                  icon: Icons.schedule,
                  value: '${campaign.remainingClicks}',
                  label: 'متبقية',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Share Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _shareCampaign(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('مشاركة الحملة'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCampaignTypeText(CampaignType type) {
    switch (type) {
      case CampaignType.open: return 'حملة مفتوحة';
      case CampaignType.regional: return 'حملة إقليمية';
      case CampaignType.precise: return 'حملة دقيقة';
    }
  }

  void _shareCampaign(BuildContext context) {
    final campaignProvider = Provider.of<CampaignProvider>(context, listen: false);
    campaignProvider.shareCampaign(campaign);
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}