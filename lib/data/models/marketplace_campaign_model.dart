// === lib/data/models/marketplace_campaign_model.dart ===

import 'campaign_model.dart';

class MarketplaceCampaignModel extends CampaignModel {
  final bool isFeatured;
  final double rating;
  final int totalShares;
  final String advertiserName;
  final String? advertiserLogo;
  final List<String> tags;
  final DateTime? featuredUntil;

  MarketplaceCampaignModel({
    required String id,
    required String businessId,
    required String title,
    required String description,
    required String targetUrl,
    required CampaignType type,
    CampaignStatus status = CampaignStatus.pending,
    required double budget,
    double spent = 0.0,
    required double cpc,
    required int targetClicks,
    int achievedClicks = 0,
    int uniqueClicks = 0,
    List<String>? targetRegions,
    Location? targetLocation,
    double targetRadius = 5.0,
    required DateTime createdAt,
    DateTime? startDate,
    DateTime? endDate,
    String? imageUrl,
    String? imageExtension,
    String? imagePath,
    bool isActive = true,
    int maxClicksPerUser = 3,
    double conversionRate = 0.0,
    int conversions = 0,
    String? advertiserId,
    
    // Nouveaux champs marketplace
    this.isFeatured = false,
    this.rating = 0.0,
    this.totalShares = 0,
    this.advertiserName = '',
    this.advertiserLogo,
    this.tags = const [],
    this.featuredUntil,
  }) : super(
    id: id,
    businessId: businessId,
    title: title,
    description: description,
    targetUrl: targetUrl,
    type: type,
    status: status,
    budget: budget,
    spent: spent,
    cpc: cpc,
    targetClicks: targetClicks,
    achievedClicks: achievedClicks,
    uniqueClicks: uniqueClicks,
    targetRegions: targetRegions,
    targetLocation: targetLocation,
    targetRadius: targetRadius,
    createdAt: createdAt,
    startDate: startDate,
    endDate: endDate,
    imageUrl: imageUrl,
    imageExtension: imageExtension,
    imagePath: imagePath,
    isActive: isActive,
    maxClicksPerUser: maxClicksPerUser,
    conversionRate: conversionRate,
    conversions: conversions,
    advertiserId: advertiserId,
  );

  factory MarketplaceCampaignModel.fromCampaignModel(
    CampaignModel campaign, {
    bool isFeatured = false,
    double rating = 0.0,
    int totalShares = 0,
    String advertiserName = '',
    String? advertiserLogo,
    List<String> tags = const [],
    DateTime? featuredUntil,
  }) {
    return MarketplaceCampaignModel(
      id: campaign.id,
      businessId: campaign.businessId,
      title: campaign.title,
      description: campaign.description,
      targetUrl: campaign.targetUrl,
      type: campaign.type,
      status: campaign.status,
      budget: campaign.budget,
      spent: campaign.spent,
      cpc: campaign.cpc,
      targetClicks: campaign.targetClicks,
      achievedClicks: campaign.achievedClicks,
      uniqueClicks: campaign.uniqueClicks,
      targetRegions: campaign.targetRegions,
      targetLocation: campaign.targetLocation,
      targetRadius: campaign.targetRadius,
      createdAt: campaign.createdAt,
      startDate: campaign.startDate,
      endDate: campaign.endDate,
      imageUrl: campaign.imageUrl,
      imageExtension: campaign.imageExtension,
      imagePath: campaign.imagePath,
      isActive: campaign.isActive,
      maxClicksPerUser: campaign.maxClicksPerUser,
      conversionRate: campaign.conversionRate,
      conversions: campaign.conversions,
      advertiserId: campaign.advertiserId,
      isFeatured: isFeatured,
      rating: rating,
      totalShares: totalShares,
      advertiserName: advertiserName,
      advertiserLogo: advertiserLogo,
      tags: tags,
      featuredUntil: featuredUntil,
    );
  }

  factory MarketplaceCampaignModel.fromMap(Map<String, dynamic> map) {
    final campaign = CampaignModel.fromMap(map);
    
    return MarketplaceCampaignModel.fromCampaignModel(
      campaign,
      isFeatured: map['isFeatured'] == true,
      rating: (map['rating'] ?? 0.0).toDouble(),
      totalShares: (map['totalShares'] ?? 0).toInt(),
      advertiserName: map['advertiserName']?.toString() ?? '',
      advertiserLogo: map['advertiserLogo']?.toString(),
      tags: map['tags'] != null ? List<String>.from(map['tags']) : [],
      featuredUntil: map['featuredUntil'] != null 
          ? DateTime.parse(map['featuredUntil'])
          : null,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map.addAll({
      'isFeatured': isFeatured,
      'rating': rating,
      'totalShares': totalShares,
      'advertiserName': advertiserName,
      'advertiserLogo': advertiserLogo,
      'tags': tags,
      'featuredUntil': featuredUntil?.toIso8601String(),
    });
    return map;
  }

  // Getters spécifiques à la marketplace
  bool get isTrending => totalShares > 100;
  bool get isPopular => rating >= 4.0;
  bool get isNew => DateTime.now().difference(createdAt).inDays < 7;
  
  String get shareCountText {
    if (totalShares >= 1000) {
      return '${(totalShares / 1000).toStringAsFixed(1)}K';
    }
    return totalShares.toString();
  }

  String get ratingText {
    return rating.toStringAsFixed(1);
  }

  List<String> get allTags {
    final baseTags = <String>[];
    
    // Tags basés sur le type
    switch (type) {
      case CampaignType.open:
        baseTags.add('مفتوحة');
        break;
      case CampaignType.regional:
        baseTags.add('إقليمية');
        break;
      case CampaignType.precise:
        baseTags.add('دقيقة');
        break;
    }
    
    // Tags basés sur le statut
    if (isFeatured) baseTags.add('مميزة');
    if (isTrending) baseTags.add('رائجة');
    if (isPopular) baseTags.add('شائعة');
    if (isNew) baseTags.add('جديدة');
    
    // Ajouter les tags personnalisés
    baseTags.addAll(tags);
    
    return baseTags;
  }
}