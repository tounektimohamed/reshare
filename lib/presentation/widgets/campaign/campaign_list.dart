import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/campaign_model.dart';
import '../../../features/campaigns/presentation/providers/campaign_provider.dart';
import 'campaign_card.dart';

class CampaignList extends StatelessWidget {
  final List<CampaignModel> campaigns;
  final bool showFilters;
  final bool showSearch;
  final VoidCallback? onRefresh;

  const CampaignList({
    super.key,
    required this.campaigns,
    this.showFilters = false,
    this.showSearch = false,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb;
    
    if (campaigns.isEmpty) {
      return _buildEmptyState(isWeb);
    }

    return Column(
      children: [
        if (showFilters) _buildHeader(context, isWeb),
        Expanded(
          child: _buildCampaignsList(isWeb),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, bool isWeb) {
    final activeCampaigns = campaigns.where((c) => c.isActive).length;
    final totalBudget = campaigns.fold<double>(0, (sum, c) => sum + c.budget);
    final totalClicks = campaigns.fold<int>(0, (sum, c) => sum + c.achievedClicks);

    return Container(
      padding: EdgeInsets.all(isWeb ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _HeaderStat(
            value: campaigns.length.toString(),
            label: 'إجمالي الحملات',
            icon: Icons.campaign_rounded,
            color: AppColors.primary,
            isWeb: isWeb,
          ),
          _HeaderStat(
            value: activeCampaigns.toString(),
            label: 'نشطة',
            icon: Icons.play_arrow_rounded,
            color: AppColors.success,
            isWeb: isWeb,
          ),
          _HeaderStat(
            value: '${totalBudget.toStringAsFixed(0)} د',
            label: 'الميزانية',
            icon: Icons.account_balance_wallet_rounded,
            color: AppColors.warning,
            isWeb: isWeb,
          ),
          _HeaderStat(
            value: totalClicks.toString(),
            label: 'النقرات',
            icon: Icons.touch_app_rounded,
            color: AppColors.info,
            isWeb: isWeb,
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignsList(bool isWeb) {
    return RefreshIndicator(
      onRefresh: () async {
        onRefresh?.call();
      },
      backgroundColor: Colors.white,
      color: AppColors.primary,
      child: ListView.separated(
        padding: EdgeInsets.all(isWeb ? 20 : 16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: campaigns.length,
        separatorBuilder: (context, index) => SizedBox(height: isWeb ? 16 : 12),
        itemBuilder: (context, index) {
          return CampaignCard(campaign: campaigns[index]);
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isWeb) {
    return RefreshIndicator(
      onRefresh: () async {
        onRefresh?.call();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: isWeb ? 500 : 400,
          padding: EdgeInsets.all(isWeb ? 40 : 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: isWeb ? 140 : 120,
                height: isWeb ? 140 : 120,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.campaign_rounded,
                  size: isWeb ? 60 : 50,
                  color: AppColors.textSecondary.withOpacity(0.5),
                ),
              ),
              SizedBox(height: isWeb ? 32 : 24),
              Text(
                'لا توجد حملات متاحة',
                style: TextStyle(
                  fontSize: isWeb ? 20 : 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  fontFamily: 'Tajawal',
                ),
              ),
              SizedBox(height: isWeb ? 12 : 8),
              Text(
                'سيظهر هنا الحملات المتاحة للمشاركة عند توفرها',
                style: TextStyle(
                  fontSize: isWeb ? 16 : 14,
                  color: AppColors.textSecondary,
                  fontFamily: 'Tajawal',
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isWeb ? 32 : 24),
              
              Wrap(
                spacing: isWeb ? 16 : 12,
                runSpacing: isWeb ? 16 : 12,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: onRefresh,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: isWeb ? 20 : 16,
                        vertical: isWeb ? 12 : 10,
                      ),
                    ),
                    icon: Icon(Icons.refresh_rounded, size: isWeb ? 20 : 18),
                    label: Text(
                      'تحديث',
                      style: TextStyle(
                        fontSize: isWeb ? 16 : 14,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: isWeb ? 20 : 16,
                        vertical: isWeb ? 12 : 10,
                      ),
                    ),
                    icon: Icon(Icons.add_rounded, size: isWeb ? 20 : 18),
                    label: Text(
                      'إنشاء حملة',
                      style: TextStyle(
                        fontSize: isWeb ? 16 : 14,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final bool isWeb;

  const _HeaderStat({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.isWeb,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: isWeb ? 48 : 40,
          height: isWeb ? 48 : 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: isWeb ? 24 : 20,
            color: color,
          ),
        ),
        SizedBox(height: isWeb ? 8 : 6),
        Text(
          value,
          style: TextStyle(
            fontSize: isWeb ? 14 : 12,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            fontFamily: 'Tajawal',
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: isWeb ? 12 : 10,
            color: AppColors.textSecondary,
            fontFamily: 'Tajawal',
          ),
        ),
      ],
    );
  }
}

class CampaignGrid extends StatelessWidget {
  final List<CampaignModel> campaigns;
  final int crossAxisCount;
  final double childAspectRatio;
  final ScrollController? controller;

  const CampaignGrid({
    super.key,
    required this.campaigns,
    this.crossAxisCount = 2,
    this.childAspectRatio = 0.8,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb;
    final actualCrossAxisCount = isWeb ? _calculateCrossAxisCount(context) : crossAxisCount;

    if (campaigns.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.campaign_rounded,
                size: 64,
                color: Colors.grey.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'لا توجد حملات',
                style: TextStyle(
                  fontSize: isWeb ? 18 : 16,
                  color: Colors.grey,
                  fontFamily: 'Tajawal',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      controller: controller,
      padding: EdgeInsets.all(isWeb ? 20 : 16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: actualCrossAxisCount,
        crossAxisSpacing: isWeb ? 16 : 12,
        mainAxisSpacing: isWeb ? 16 : 12,
        childAspectRatio: isWeb ? _calculateChildAspectRatio(context) : childAspectRatio,
      ),
      itemCount: campaigns.length,
      itemBuilder: (context, index) {
        return _CampaignGridItem(campaign: campaigns[index]);
      },
    );
  }

  int _calculateCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1400) return 4;
    if (width > 1100) return 3;
    if (width > 800) return 2;
    return 1;
  }

  double _calculateChildAspectRatio(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1400) return 0.7;
    if (width > 1100) return 0.75;
    if (width > 800) return 0.8;
    return 0.85;
  }
}

class _CampaignGridItem extends StatelessWidget {
  final CampaignModel campaign;

  const _CampaignGridItem({required this.campaign});

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {},
        child: Padding(
          padding: EdgeInsets.all(isWeb ? 16 : 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Campaign Image - SUPPORT BASE64
              _buildCampaignImage(isWeb),
              SizedBox(height: isWeb ? 12 : 8),
              
              Text(
                campaign.title,
                style: TextStyle(
                  fontSize: isWeb ? 16 : 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Tajawal',
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: isWeb ? 6 : 4),
              
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isWeb ? 8 : 6,
                  vertical: isWeb ? 4 : 2,
                ),
                decoration: BoxDecoration(
                  color: _getTypeColor(campaign.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
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
              ),
              SizedBox(height: isWeb ? 12 : 8),
              
              Row(
                children: [
                  Icon(
                    Icons.attach_money_rounded,
                    size: isWeb ? 14 : 12,
                    color: AppColors.warning,
                  ),
                  SizedBox(width: isWeb ? 6 : 4),
                  Text(
                    '${campaign.participantEarnings.toStringAsFixed(3)} د',
                    style: TextStyle(
                      fontSize: isWeb ? 13 : 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                ],
              ),
              SizedBox(height: isWeb ? 8 : 4),
              
              LinearProgressIndicator(
                value: campaign.targetClicks > 0 
                    ? campaign.achievedClicks / campaign.targetClicks 
                    : 0,
                backgroundColor: AppColors.background,
                color: AppColors.primary,
                minHeight: isWeb ? 6 : 4,
              ),
              SizedBox(height: isWeb ? 6 : 4),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${campaign.achievedClicks}/${campaign.targetClicks}',
                    style: TextStyle(
                      fontSize: isWeb ? 11 : 10,
                      color: AppColors.textSecondary,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                  if (campaign.isActive)
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCampaignImage(bool isWeb) {
    final hasValidImage = campaign.hasImage && 
                         campaign.imageUrl != null && 
                         campaign.imageUrl!.isNotEmpty;
    
    if (!hasValidImage) return _buildImagePlaceholder(isWeb);

    // Détection du type d'image (base64 ou URL)
    final isBase64 = _isBase64Image(campaign.imageUrl!);
    
    return Container(
      height: isWeb ? 100 : 80, 
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8), 
        color: AppColors.background
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8), 
        child: isBase64 ? _buildBase64Image(campaign.imageUrl!, isWeb) : _buildNetworkImage(campaign.imageUrl!, isWeb)
      ),
    );
  }

  bool _isBase64Image(String imageData) {
    return imageData.startsWith('data:image/') || 
           (imageData.length > 100 && !imageData.startsWith('http')) ||
           imageData.contains('base64');
  }

  Widget _buildBase64Image(String base64Data, bool isWeb) {
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
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          print('Base64 image error: $error');
          return _buildImageErrorPlaceholder(isWeb);
        },
      );
    } catch (e) {
      print('Base64 decode error: $e');
      return _buildImageErrorPlaceholder(isWeb);
    }
  }

  Widget _buildNetworkImage(String imageUrl, bool isWeb) {
    if (kIsWeb) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: AppColors.background, 
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null 
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! 
                  : null
              )
            )
          );
        },
        errorBuilder: (context, error, stackTrace) {
          print('Network image error: $error');
          return _buildImageErrorPlaceholder(isWeb);
        },
      );
    } else {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        placeholder: (context, url) => Container(
          color: AppColors.background,
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)
            )
          )
        ),
        errorWidget: (context, url, error) {
          print('CachedNetworkImage error: $error');
          return _buildImageErrorPlaceholder(isWeb);
        },
      );
    }
  }

  Widget _buildImagePlaceholder(bool isWeb) {
    return Container(
      height: isWeb ? 100 : 80,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: AppColors.background,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.campaign_rounded,
              color: AppColors.textSecondary.withOpacity(0.5),
              size: isWeb ? 32 : 24,
            ),
            SizedBox(height: 4),
            Text(
              'لا توجد صورة',
              style: TextStyle(
                fontSize: isWeb ? 10 : 8,
                color: AppColors.textSecondary.withOpacity(0.7),
                fontFamily: 'Tajawal',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageErrorPlaceholder(bool isWeb) {
    return Container(
      height: isWeb ? 100 : 80,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: AppColors.background,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image_rounded,
              color: AppColors.error.withOpacity(0.7),
              size: isWeb ? 32 : 24,
            ),
            SizedBox(height: 4),
            Text(
              'خطأ في التحميل',
              style: TextStyle(
                fontSize: isWeb ? 10 : 8,
                color: AppColors.error,
                fontFamily: 'Tajawal',
              ),
            ),
          ],
        ),
      ),
    );
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
}

class CampaignHorizontalList extends StatelessWidget {
  final List<CampaignModel> campaigns;
  final String title;

  const CampaignHorizontalList({
    super.key,
    required this.campaigns,
    this.title = 'الحملات الموصى بها',
  });

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb;
    
    if (campaigns.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isWeb ? 20 : 16),
          child: Text(
            title,
            style: TextStyle(
              fontSize: isWeb ? 20 : 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Tajawal',
            ),
          ),
        ),
        SizedBox(height: isWeb ? 16 : 12),
        SizedBox(
          height: isWeb ? 240 : 200,
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: isWeb ? 20 : 16),
            scrollDirection: Axis.horizontal,
            itemCount: campaigns.length,
            separatorBuilder: (context, index) => SizedBox(width: isWeb ? 16 : 12),
            itemBuilder: (context, index) {
              return SizedBox(
                width: isWeb ? 180 : 160,
                child: _CampaignGridItem(campaign: campaigns[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}

// DEBUG: Widget amélioré pour tester les images
class CampaignImageDebug extends StatelessWidget {
  final CampaignModel campaign;

  const CampaignImageDebug({super.key, required this.campaign});

  @override
  Widget build(BuildContext context) {
    final isBase64 = campaign.imageUrl != null && 
                    (campaign.imageUrl!.startsWith('data:image/') || 
                     campaign.imageUrl!.contains('base64'));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Debug Image Info:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('hasImage: ${campaign.hasImage}'),
            Text('imageUrl length: ${campaign.imageUrl?.length ?? 0}'),
            Text('isBase64: $isBase64'),
            if (campaign.imageUrl != null) ...[
              Text('startsWith data:image/: ${campaign.imageUrl!.startsWith('data:image/')}'),
              Text('contains base64: ${campaign.imageUrl!.contains('base64')}'),
              Text('startsWith http: ${campaign.imageUrl!.startsWith('http')}'),
            ],
            
            const SizedBox(height: 16),
            
            // Test d'affichage de l'image
            if (campaign.hasImage && campaign.imageUrl != null)
              Container(
                height: 100,
                width: 100,
                child: isBase64 
                  ? _buildBase64ImageDebug(campaign.imageUrl!)
                  : Image.network(
                      campaign.imageUrl!,
                      errorBuilder: (context, error, stackTrace) {
                        return Text('Error: $error');
                      },
                    ),
              )
            else
              Text('Cannot display image - invalid URL'),
          ],
        ),
      ),
    );
  }

  Widget _buildBase64ImageDebug(String base64Data) {
    try {
      String imageData = base64Data;
      if (base64Data.startsWith('data:image/')) {
        final parts = base64Data.split(',');
        if (parts.length > 1) imageData = parts[1];
      }

      final bytes = base64.decode(imageData);
      return Image.memory(bytes);
    } catch (e) {
      return Text('Base64 Error: $e');
    }
  }
}