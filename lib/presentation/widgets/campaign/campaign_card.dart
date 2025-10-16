import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/campaign_model.dart';
import '../../../features/campaigns/presentation/providers/campaign_provider.dart';

class CampaignCard extends StatelessWidget {
  final CampaignModel campaign;

  const CampaignCard({super.key, required this.campaign});

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb;
    
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(
        horizontal: isWeb ? 24 : 16,
        vertical: isWeb ? 12 : 8,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Image de la campagne en grand format
          if (campaign.hasImage) _buildCampaignImageLarge(isWeb),
          
          Padding(
            padding: EdgeInsets.all(isWeb ? 20 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Campaign Header
                _buildCampaignHeader(isWeb),
                SizedBox(height: isWeb ? 16 : 12),

                // Campaign Description
                _buildCampaignDescription(isWeb),
                SizedBox(height: isWeb ? 20 : 16),

                // Campaign Stats
                _buildCampaignStats(isWeb),
                SizedBox(height: isWeb ? 20 : 16),

                // Share Button
                _buildShareButton(context, isWeb),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignImageLarge(bool isWeb) {
    final imageHeight = isWeb ? 220.0 : 180.0;
    
    return Container(
      width: double.infinity,
      height: imageHeight,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        child: _buildOptimizedImage(imageHeight),
      ),
    );
  }

  Widget _buildOptimizedImage(double height) {
    // Vérifier si c'est une image base64
    final isBase64 = _isBase64Image(campaign.imageUrl!);
    
    if (isBase64) {
      return _buildBase64Image(campaign.imageUrl!, height);
    } else {
      if (kIsWeb) {
        // Pour le web : utiliser Image.network
        return Image.network(
          campaign.imageUrl!,
          fit: BoxFit.cover,
          height: height,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: AppColors.background,
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildErrorPlaceholder();
          },
        );
      } else {
        // Pour mobile : utiliser CachedNetworkImage
        return CachedNetworkImage(
          imageUrl: campaign.imageUrl!,
          fit: BoxFit.cover,
          height: height,
          placeholder: (context, url) => Container(
            color: AppColors.background,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
          errorWidget: (context, url, error) => _buildErrorPlaceholder(),
        );
      }
    }
  }

  bool _isBase64Image(String imageData) {
    return imageData.startsWith('data:image/') || 
           (imageData.length > 100 && !imageData.startsWith('http')) ||
           imageData.contains('base64');
  }

  Widget _buildBase64Image(String base64Data, double height) {
    try {
      // Nettoyer le data URL si nécessaire
      String imageData = base64Data;
      if (base64Data.startsWith('data:image/')) {
        final parts = base64Data.split(',');
        if (parts.length > 1) imageData = parts[1];
      }

      final bytes = base64.decode(imageData);
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        width: double.infinity,
        height: height,
        errorBuilder: (context, error, stackTrace) {
          print('Base64 image error: $error');
          return _buildErrorPlaceholder();
        },
      );
    } catch (e) {
      print('Base64 decode error: $e');
      return _buildErrorPlaceholder();
    }
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      color: AppColors.background,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image_rounded,
            size: 50,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 8),
          Text(
            'فشل في تحميل الصورة',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontFamily: 'Tajawal',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignHeader(bool isWeb) {
    return Row(
      children: [
        // Campaign Icon
        Container(
          width: isWeb ? 48 : 40,
          height: isWeb ? 48 : 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.campaign_rounded,
            color: AppColors.primary,
            size: isWeb ? 24 : 20,
          ),
        ),
        SizedBox(width: isWeb ? 16 : 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                campaign.title,
                style: TextStyle(
                  fontSize: isWeb ? 18 : 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Tajawal',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: isWeb ? 6 : 4),
              Row(
                children: [
                  _buildCampaignTypeChip(isWeb),
                  SizedBox(width: isWeb ? 12 : 8),
                  _buildCampaignStatusChip(isWeb),
                ],
              ),
              if (campaign.hasImage && campaign.imageExtension != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'صيغة: ${campaign.imageExtension!.toUpperCase()}',
                    style: TextStyle(
                      fontSize: isWeb ? 11 : 10,
                      color: AppColors.textSecondary.withOpacity(0.7),
                      fontFamily: 'Tajawal',
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCampaignTypeChip(bool isWeb) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isWeb ? 10 : 8,
        vertical: isWeb ? 4 : 2,
      ),
      decoration: BoxDecoration(
        color: _getTypeColor(campaign.type).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: _getTypeColor(campaign.type).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        campaign.typeText,
        style: TextStyle(
          fontSize: isWeb ? 11 : 10,
          color: _getTypeColor(campaign.type),
          fontWeight: FontWeight.bold,
          fontFamily: 'Tajawal',
        ),
      ),
    );
  }

  Widget _buildCampaignStatusChip(bool isWeb) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isWeb ? 10 : 8,
        vertical: isWeb ? 4 : 2,
      ),
      decoration: BoxDecoration(
        color: Color(campaign.statusColor).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Color(campaign.statusColor).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        campaign.statusText,
        style: TextStyle(
          fontSize: isWeb ? 11 : 10,
          color: Color(campaign.statusColor),
          fontWeight: FontWeight.bold,
          fontFamily: 'Tajawal',
        ),
      ),
    );
  }

  Widget _buildCampaignDescription(bool isWeb) {
    return Text(
      campaign.description,
      style: TextStyle(
        fontSize: isWeb ? 15 : 14,
        color: AppColors.textSecondary,
        fontFamily: 'Tajawal',
        height: 1.4,
      ),
      maxLines: isWeb ? 3 : 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildCampaignStats(bool isWeb) {
    return Container(
      padding: EdgeInsets.all(isWeb ? 16 : 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            icon: Icons.touch_app_rounded,
            value: '${campaign.achievedClicks}',
            label: 'محققة',
            color: AppColors.success,
            isWeb: isWeb,
          ),
          _StatItem(
            icon: Icons.tablet_rounded,
            value: '${campaign.targetClicks}',
            label: 'مستهدفة',
            color: AppColors.primary,
            isWeb: isWeb,
          ),
          _StatItem(
            icon: Icons.attach_money_rounded,
            value: '${campaign.participantEarnings.toStringAsFixed(3)}',
            label: 'دينار/نقرة',
            color: AppColors.warning,
            isWeb: isWeb,
          ),
          _StatItem(
            icon: Icons.timelapse_rounded,
            value: '${campaign.remainingClicks}',
            label: 'متبقية',
            color: AppColors.info,
            isWeb: isWeb,
          ),
        ],
      ),
    );
  }

  Widget _buildShareButton(BuildContext context, bool isWeb) {
    final canShare = campaign.status == CampaignStatus.active && 
                    campaign.isActive && 
                    campaign.remainingClicks > 0;

    return SizedBox(
      width: double.infinity,
      height: isWeb ? 50 : 45,
      child: ElevatedButton(
        onPressed: canShare ? () => _shareCampaign(context) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: canShare ? AppColors.primary : AppColors.textSecondary.withOpacity(0.3),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 1,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.share_rounded, size: isWeb ? 20 : 18),
            SizedBox(width: isWeb ? 12 : 8),
            Text(
              _getShareButtonText(),
              style: TextStyle(
                fontSize: isWeb ? 16 : 14,
                fontWeight: FontWeight.bold,
                fontFamily: 'Tajawal',
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getShareButtonText() {
    if (campaign.status == CampaignStatus.active && campaign.isActive) {
      return 'مشاركة الحملة';
    } else if (campaign.status == CampaignStatus.pending) {
      return 'قيد المراجعة';
    } else if (campaign.status == CampaignStatus.completed) {
      return 'مكتملة';
    } else if (campaign.status == CampaignStatus.paused) {
      return 'متوقفة';
    } else if (campaign.status == CampaignStatus.rejected) {
      return 'مرفوضة';
    } else {
      return 'غير متاحة';
    }
  }

  Color _getTypeColor(CampaignType type) {
    switch (type) {
      case CampaignType.open:
        return AppColors.success;
      case CampaignType.regional:
        return AppColors.info;
      case CampaignType.precise:
        return AppColors.warning;
    }
  }

  void _shareCampaign(BuildContext context) {
    final campaignProvider = Provider.of<CampaignProvider>(context, listen: false);
    campaignProvider.shareCampaign(campaign);
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم نسخ رابط الحملة: ${campaign.title}',
          style: const TextStyle(fontFamily: 'Tajawal'),
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final bool isWeb;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.isWeb,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: isWeb ? 36 : 30,
          height: isWeb ? 36 : 30,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: isWeb ? 18 : 16,
            color: color,
          ),
        ),
        SizedBox(height: isWeb ? 8 : 6),
        Text(
          value,
          style: TextStyle(
            fontSize: isWeb ? 13 : 12,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            fontFamily: 'Tajawal',
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: isWeb ? 11 : 10,
            color: AppColors.textSecondary,
            fontFamily: 'Tajawal',
          ),
        ),
      ],
    );
  }
}

// Widget optimisé pour afficher les images de campagne (support base64)
class CampaignImageWidget extends StatelessWidget {
  final CampaignModel campaign;
  final double width;
  final double height;
  final BoxFit fit;

  const CampaignImageWidget({
    super.key,
    required this.campaign,
    this.width = double.infinity,
    this.height = 200,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (!campaign.hasImage) {
      return _buildNoImagePlaceholder();
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.background,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _buildOptimizedImage(),
      ),
    );
  }

  Widget _buildOptimizedImage() {
    // Vérifier si c'est une image base64
    final isBase64 = _isBase64Image(campaign.imageUrl!);
    
    if (isBase64) {
      return _buildBase64Image(campaign.imageUrl!);
    } else {
      if (kIsWeb) {
        return Image.network(
          campaign.imageUrl!,
          fit: fit,
          width: width,
          height: height,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: AppColors.background,
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildErrorPlaceholder();
          },
        );
      } else {
        return CachedNetworkImage(
          imageUrl: campaign.imageUrl!,
          fit: fit,
          width: width,
          height: height,
          placeholder: (context, url) => Container(
            color: AppColors.background,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
          errorWidget: (context, url, error) => _buildErrorPlaceholder(),
        );
      }
    }
  }

  bool _isBase64Image(String imageData) {
    return imageData.startsWith('data:image/') || 
           (imageData.length > 100 && !imageData.startsWith('http')) ||
           imageData.contains('base64');
  }

  Widget _buildBase64Image(String base64Data) {
    try {
      String imageData = base64Data;
      if (base64Data.startsWith('data:image/')) {
        final parts = base64Data.split(',');
        if (parts.length > 1) imageData = parts[1];
      }

      final bytes = base64.decode(imageData);
      return Image.memory(
        bytes,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorPlaceholder();
        },
      );
    } catch (e) {
      return _buildErrorPlaceholder();
    }
  }

  Widget _buildNoImagePlaceholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.campaign_rounded,
            size: 50,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 8),
          Text(
            'لا توجد صورة',
            style: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.7),
              fontFamily: 'Tajawal',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      color: AppColors.background,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image_rounded,
            size: 50,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 8),
          Text(
            'فشل في تحميل الصورة',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontFamily: 'Tajawal',
            ),
          ),
        ],
      ),
    );
  }
}

// Widget pour une grille responsive sur le web
class CampaignGrid extends StatelessWidget {
  final List<CampaignModel> campaigns;
  final ScrollController? controller;

  const CampaignGrid({
    super.key,
    required this.campaigns,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb;
    
    return GridView.builder(
      controller: controller,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isWeb ? _calculateCrossAxisCount(context) : 1,
        crossAxisSpacing: isWeb ? 20 : 16,
        mainAxisSpacing: isWeb ? 20 : 16,
        childAspectRatio: isWeb ? 0.8 : 1.2,
      ),
      itemCount: campaigns.length,
      itemBuilder: (context, index) {
        return CampaignCard(campaign: campaigns[index]);
      },
    );
  }

  int _calculateCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 3;
    if (width > 800) return 2;
    return 1;
  }
}