import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reshare/data/models/campaign_model.dart';

import '../../../../core/constants/app_colors.dart';
import '../providers/campaign_provider.dart';

class CampaignDetailsScreen extends StatelessWidget {
  final String campaignId;

  const CampaignDetailsScreen({super.key, required this.campaignId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الحملة'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Consumer<CampaignProvider>(
        builder: (context, campaignProvider, child) {
          final campaign = campaignProvider.selectedCampaign;
          
          if (campaignProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (campaign == null) {
            return const Center(child: Text('الحملة غير موجودة'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Campaign Header
                _buildCampaignHeader(campaign),
                const SizedBox(height: 24),

                // Campaign Description
                _buildCampaignDescription(campaign),
                const SizedBox(height: 24),

                // Campaign Stats
                _buildCampaignStats(campaign),
                const SizedBox(height: 24),

                // Share Button
                _buildShareButton(context, campaign),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCampaignHeader(CampaignModel campaign) {
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
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.campaign_rounded,
              color: AppColors.primary,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  campaign.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Tajawal',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getCampaignTypeText(campaign.type),
                  style: TextStyle(
                    fontSize: 14,
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

  Widget _buildCampaignDescription(CampaignModel campaign) {
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
            'وصف الحملة',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontFamily: 'Tajawal',
            ),
          ),
          const SizedBox(height: 12),
          Text(
            campaign.description,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontFamily: 'Tajawal',
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignStats(CampaignModel campaign) {
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
            'إحصائيات الحملة',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontFamily: 'Tajawal',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                value: campaign.achievedClicks.toString(),
                label: 'نقرات محققة',
                icon: Icons.touch_app_rounded,
              ),
              _buildStatItem(
                value: campaign.remainingClicks.toString(),
                label: 'نقرات متبقية',
                icon: Icons.timelapse_rounded,
              ),
              _buildStatItem(
                value: '${campaign.participantEarnings.toStringAsFixed(3)} د',
                label: 'ربح النقرة',
                icon: Icons.attach_money_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String value,
    required String label,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
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

  Widget _buildShareButton(BuildContext context, CampaignModel campaign) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: () {
          final provider = Provider.of<CampaignProvider>(context, listen: false);
          provider.shareCampaign(campaign);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.share_rounded),
            SizedBox(width: 8),
            Text(
              'مشاركة الحملة',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Tajawal',
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCampaignTypeText(CampaignType type) {
    switch (type) {
      case CampaignType.open:
        return 'حملة مفتوحة - جميع المناطق';
      case CampaignType.regional:
        return 'حملة إقليمية - مناطق محددة';
      case CampaignType.precise:
        return 'حملة دقيقة - مواقع محددة';
    }
  }
}