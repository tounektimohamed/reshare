// === lib/features/marketplace/presentation/widgets/marketplace_campaign_card.dart ===

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:reshare/data/models/marketplace_campaign_model.dart';

class MarketplaceCampaignCard extends StatelessWidget {
  final MarketplaceCampaignModel campaign;
  final VoidCallback onShare;
  final VoidCallback onContact;
  final VoidCallback onView;

  const MarketplaceCampaignCard({
    super.key,
    required this.campaign,
    required this.onShare,
    required this.onContact,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // En-tête avec image et badges
          _buildCampaignHeader(),
          
          // Contenu
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre et description
                _buildCampaignInfo(),
                const SizedBox(height: 12),
                
                // Tags
                _buildCampaignTags(),
                const SizedBox(height: 16),
                
                // Statistiques
                _buildCampaignStats(),
                const SizedBox(height: 16),
                
                // Boutons d'action
                _buildActionButtons(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignHeader() {
    return Stack(
      children: [
        // Image de la campagne
        Container(
          height: 140,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            color: Colors.grey[200],
          ),
          child: campaign.hasImage
              ? ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: campaign.imageUrl!.startsWith('data:image/')
                      ? Image.memory(
                          base64.decode(campaign.imageUrl!.split(',')[1]),
                          fit: BoxFit.cover,
                        )
                      : Image.network(
                          campaign.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildImagePlaceholder();
                          },
                        ),
                )
              : _buildImagePlaceholder(),
        ),
        
        // Badges
        Positioned(
          top: 8,
          left: 8,
          child: Row(
            children: [
              if (campaign.isFeatured)
                _buildBadge('مميزة', Colors.amber),
              if (campaign.isTrending)
                _buildBadge('رائجة', Colors.red),
              if (campaign.isNew)
                _buildBadge('جديدة', Colors.green),
            ],
          ),
        ),
        
        // Note
        Positioned(
          top: 8,
          right: 8,
          child: _buildRatingBadge(),
        ),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.campaign_rounded,
            size: 40,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 4),
          Text(
            'لا توجد صورة',
            style: TextStyle(
              color: Colors.grey.withOpacity(0.7),
              fontFamily: 'Tajawal',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          fontFamily: 'Tajawal',
        ),
      ),
    );
  }

  Widget _buildRatingBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Text(
            campaign.ratingText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 2),
          const Icon(
            Icons.star_rounded,
            color: Colors.amber,
            size: 14,
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Logo de l'advertiser
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: campaign.advertiserLogo != null
                  ? CircleAvatar(
                      backgroundImage: NetworkImage(campaign.advertiserLogo!),
                    )
                  : Icon(
                      Icons.business_rounded,
                      color: Colors.blue,
                      size: 16,
                    ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    campaign.advertiserName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                  Text(
                    campaign.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Tajawal',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          campaign.description,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontFamily: 'Tajawal',
            height: 1.4,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildCampaignTags() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: campaign.allTags.take(4).map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            tag,
            style: TextStyle(
              fontSize: 10,
              color: Colors.blue,
              fontFamily: 'Tajawal',
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCampaignStats() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.attach_money_rounded,
            value: '${campaign.participantEarnings.toStringAsFixed(3)} د',
            label: 'للنقرة',
          ),
          _buildStatItem(
            icon: Icons.touch_app_rounded,
            value: campaign.achievedClicks.toString(),
            label: 'نقرات',
          ),
          _buildStatItem(
            icon: Icons.share_rounded,
            value: campaign.shareCountText,
            label: 'مشاركة',
          ),
          _buildStatItem(
            icon: Icons.schedule_rounded,
            value: '${campaign.remainingClicks}',
            label: 'متبقية',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.blue),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            fontFamily: 'Tajawal',
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
            fontFamily: 'Tajawal',
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onView,
            icon: const Icon(Icons.visibility_rounded, size: 16),
            label: const Text(
              'عرض',
              style: TextStyle(fontFamily: 'Tajawal'),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue,
              side: const BorderSide(color: Colors.blue),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onContact,
            icon: const Icon(Icons.chat_rounded, size: 16),
            label: const Text(
              'تواصل',
              style: TextStyle(fontFamily: 'Tajawal'),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.green,
              side: const BorderSide(color: Colors.green),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onShare,
            icon: const Icon(Icons.share_rounded, size: 16),
            label: const Text(
              'مشاركة',
              style: TextStyle(fontFamily: 'Tajawal'),
            ),
          ),
        ),
      ],
    );
  }
}