import 'package:cloud_firestore/cloud_firestore.dart';

class CampaignModel {
  final String id;
  final String businessId;
  final String title;
  final String description;
  final String targetUrl;
  final CampaignType type;
  final CampaignStatus status;
  final double budget;
  final double spent;
  final double cpc;
  final int targetClicks;
  final int achievedClicks;
  final int uniqueClicks;
  final List<String>? targetRegions;
  final Location? targetLocation;
  final double targetRadius;
  final DateTime createdAt;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? imageUrl;
  final String? imageExtension; // 🔥 NOUVEAU CHAMP
  final String? imagePath; // 🔥 NOUVEAU CHAMP
  final bool isActive;
  final int maxClicksPerUser;
  final double conversionRate;
  final int conversions;
  final String? advertiserId; // 🔥 NOUVEAU CHAMP

  // NOUVEAUX CHAMPS AJOUTÉS
  final String campaignType; // 'ads' ou 'marketplace'
  final double marketplaceFee; // Frais pour marketplace
  final double totalDeduction; // Total déduit du compte

  CampaignModel({
    required this.id,
    required this.businessId,
    required this.title,
    required this.description,
    required this.targetUrl,
    required this.type,
    this.status = CampaignStatus.active,
    required this.budget,
    this.spent = 0.0,
    required this.cpc,
    required this.targetClicks,
    this.achievedClicks = 0,
    this.uniqueClicks = 0,
    this.targetRegions,
    this.targetLocation,
    this.targetRadius = 5.0,
    required this.createdAt,
    this.startDate,
    this.endDate,
    this.imageUrl,
    this.imageExtension, // 🔥 NOUVEAU
    this.imagePath, // 🔥 NOUVEAU
    this.isActive = true,
    this.maxClicksPerUser = 3,
    this.conversionRate = 0.0,
    this.conversions = 0,
    this.advertiserId, // 🔥 NOUVEAU
    // NOUVEAUX CHAMPS INITIALISÉS
    this.campaignType = 'ads', // Valeur par défaut
    this.marketplaceFee = 0.0, // Valeur par défaut
    this.totalDeduction = 0.0, // Valeur par défaut
  });

  // Getters calculés
  int get remainingClicks => targetClicks - achievedClicks;
  double get remainingBudget => budget - spent;
  double get participantEarnings => cpc * 0.6;
  double get totalCost => cpc * targetClicks;
  bool get isBudgetSufficient => totalCost <= budget;
  double get completionRate =>
      targetClicks > 0 ? (achievedClicks / targetClicks) * 100 : 0.0;
  double get budgetUtilization => budget > 0 ? (spent / budget) * 100 : 0.0;

  // NOUVEAUX GETTERS POUR LE TYPE DE CAMPAGNE
  bool get isMarketplaceCampaign => campaignType == 'marketplace';
  bool get isAdsCampaign => campaignType == 'ads';

  // 🔥 NOUVEAU : Vérifier si la campagne a une image
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  // 🔥 NOUVEAU : Obtenir le type MIME de l'image
  String? get imageMimeType {
    if (imageExtension == null) return null;
    switch (imageExtension!.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/$imageExtension';
    }
  }

  factory CampaignModel.fromMap(Map<String, dynamic> map) {
    return CampaignModel(
      id: map['id']?.toString() ?? '',
      businessId: map['businessId']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      targetUrl: map['targetUrl']?.toString() ?? '',
      type: _parseCampaignType(map['type']),
      status: _parseCampaignStatus(map['status']),
      budget: _safeDouble(map['budget']),
      spent: _safeDouble(map['spent']),
      cpc: _safeDouble(map['cpc']),
      targetClicks: _safeInt(map['targetClicks']),
      achievedClicks: _safeInt(map['achievedClicks']),
      uniqueClicks: _safeInt(map['uniqueClicks']),
      targetRegions: map['targetRegions'] != null
          ? List<String>.from(map['targetRegions'])
          : null,
      targetLocation: map['targetLocation'] != null
          ? Location.fromMap(Map<String, dynamic>.from(map['targetLocation']))
          : null,
      targetRadius: _safeDouble(map['targetRadius']),
      createdAt: _parseDateTime(map['createdAt']),
      startDate: _parseDateTime(map['startDate']),
      endDate: _parseDateTime(map['endDate']),
      imageUrl: map['imageUrl']?.toString(),
      imageExtension: map['imageExtension']?.toString(), // 🔥 NOUVEAU
      imagePath: map['imagePath']?.toString(), // 🔥 NOUVEAU
      isActive: map['isActive'] == true,
      maxClicksPerUser: _safeInt(map['maxClicksPerUser']),
      conversionRate: _safeDouble(map['conversionRate']),
      conversions: _safeInt(map['conversions']),
      advertiserId: map['advertiserId']?.toString(), // 🔥 NOUVEAU
      // NOUVEAUX CHAMPS AVEC VALEURS PAR DÉFAUT SI NULL
      campaignType: map['campaignType']?.toString() ?? 'ads',
      marketplaceFee: _safeDouble(map['marketplaceFee']),
      totalDeduction: _safeDouble(map['totalDeduction']),
    );
  }

  // 🔥 MÉTHODE : Parser CampaignType de manière sécurisée
  static CampaignType _parseCampaignType(dynamic type) {
    if (type == null) return CampaignType.open;

    if (type is int) {
      return CampaignType.values[type];
    }

    if (type is String) {
      switch (type.toLowerCase()) {
        case 'regional':
        case '1':
          return CampaignType.regional;
        case 'precise':
        case '2':
          return CampaignType.precise;
        case 'open':
        case '0':
        default:
          return CampaignType.open;
      }
    }

    return CampaignType.open;
  }

  // 🔥 MÉTHODE : Parser CampaignStatus de manière sécurisée
  static CampaignStatus _parseCampaignStatus(dynamic status) {
    if (status == null) return CampaignStatus.pending;

    if (status is int) {
      return CampaignStatus.values[status];
    }

    if (status is String) {
      switch (status.toLowerCase()) {
        case 'approved':
        case '1':
          return CampaignStatus.approved;
        case 'active':
        case '2':
          return CampaignStatus.active;
        case 'paused':
        case '3':
          return CampaignStatus.paused;
        case 'completed':
        case '4':
          return CampaignStatus.completed;
        case 'rejected':
        case '5':
          return CampaignStatus.rejected;
        case 'pending':
        case '0':
        default:
          return CampaignStatus.pending;
      }
    }

    return CampaignStatus.pending;
  }

  // 🔥 MÉTHODES UTILITAIRES POUR LA CONVERSION SÉCURISÉE
  static double _safeDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _safeInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return DateTime.now();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'businessId': businessId,
      'title': title,
      'description': description,
      'targetUrl': targetUrl,
      'type': type.index,
      'status': status.index,
      'budget': budget,
      'spent': spent,
      'cpc': cpc,
      'targetClicks': targetClicks,
      'achievedClicks': achievedClicks,
      'uniqueClicks': uniqueClicks,
      'targetRegions': targetRegions,
      'targetLocation': targetLocation?.toMap(),
      'targetRadius': targetRadius,
      'createdAt': createdAt.toIso8601String(),
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'imageUrl': imageUrl,
      'imageExtension': imageExtension, // 🔥 NOUVEAU
      'imagePath': imagePath, // 🔥 NOUVEAU
      'isActive': isActive,
      'maxClicksPerUser': maxClicksPerUser,
      'conversionRate': conversionRate,
      'conversions': conversions,
      'advertiserId': advertiserId, // 🔥 NOUVEAU
      // NOUVEAUX CHAMPS AJOUTÉS
      'campaignType': campaignType,
      'marketplaceFee': marketplaceFee,
      'totalDeduction': totalDeduction,
    };
  }

  /// 🔥 NOUVELLE MÉTHODE : Pour la création avec image
  Map<String, dynamic> toCreateMap() {
    return {
      'title': title,
      'description': description,
      'targetUrl': targetUrl,
      'type': type.index,
      'budget': budget,
      'cpc': cpc,
      'targetClicks': targetClicks,
      'imageUrl': imageUrl,
      'imageExtension': imageExtension,
      'imagePath': imagePath,
      'advertiserId': advertiserId ?? businessId,
      'createdAt': createdAt.toIso8601String(),
      'status': CampaignStatus.active.index,
      'isActive': true,
      'spent': 0.0,
      'achievedClicks': 0,
      'uniqueClicks': 0,
      'maxClicksPerUser': maxClicksPerUser,
      'conversionRate': 0.0,
      'conversions': 0,

      // NOUVEAUX CHAMPS AJOUTÉS
      'campaignType': campaignType,
      'marketplaceFee': marketplaceFee,
      'totalDeduction': totalDeduction,
    };
  }

  /// 🔥 NOUVELLE MÉTHODE : Vérifier si la campagne peut être modifiée
  bool get canBeEdited {
    return status == CampaignStatus.pending ||
        status == CampaignStatus.rejected;
  }

  /// 🔥 NOUVELLE MÉTHODE : Vérifier si la campagne peut être activée
  bool get canBeActivated {
    return status == CampaignStatus.approved &&
        isActive == false &&
        remainingBudget > 0 &&
        remainingClicks > 0;
  }

  /// 🔥 NOUVELLE MÉTHODE : Obtenir le statut sous forme de texte
  String get statusText {
    switch (status) {
      case CampaignStatus.pending:
        return 'قيد المراجعة';
      case CampaignStatus.approved:
        return 'مقبولة';
      case CampaignStatus.active:
        return 'نشطة';
      case CampaignStatus.paused:
        return 'متوقفة';
      case CampaignStatus.completed:
        return 'مكتملة';
      case CampaignStatus.rejected:
        return 'مرفوضة';
    }
  }

  /// 🔥 NOUVELLE MÉTHODE : Obtenir le type sous forme de texte
  String get typeText {
    switch (type) {
      case CampaignType.open:
        return 'مفتوحة';
      case CampaignType.regional:
        return 'إقليمية';
      case CampaignType.precise:
        return 'دقيقة';
    }
  }

  /// NOUVELLE MÉTHODE : Obtenir le type de campagne sous forme de texte
  String get campaignTypeText {
    switch (campaignType) {
      case 'marketplace':
        return 'سوق الحملات';
      case 'ads':
      default:
        return 'إعلانات عادية';
    }
  }

  /// 🔥 NOUVELLE MÉTHODE : Obtenir la couleur du statut
  int get statusColor {
    switch (status) {
      case CampaignStatus.pending:
        return 0xFFFFA000; // Amber
      case CampaignStatus.approved:
        return 0xFF4CAF50; // Green
      case CampaignStatus.active:
        return 0xFF2196F3; // Blue
      case CampaignStatus.paused:
        return 0xFFFF9800; // Orange
      case CampaignStatus.completed:
        return 0xFF9C27B0; // Purple
      case CampaignStatus.rejected:
        return 0xFFF44336; // Red
    }
  }

  /// NOUVELLE MÉTHODE : Obtenir la couleur du type de campagne
  int get campaignTypeColor {
    switch (campaignType) {
      case 'marketplace':
        return 0xFF4CAF50; // Green
      case 'ads':
      default:
        return 0xFF2196F3; // Blue
    }
  }

  /// Create a copy of the campaign with updated values
  CampaignModel copyWith({
    String? id,
    String? businessId,
    String? title,
    String? description,
    String? targetUrl,
    CampaignType? type,
    CampaignStatus? status,
    double? budget,
    double? spent,
    double? cpc,
    int? targetClicks,
    int? achievedClicks,
    int? uniqueClicks,
    List<String>? targetRegions,
    Location? targetLocation,
    double? targetRadius,
    DateTime? createdAt,
    DateTime? startDate,
    DateTime? endDate,
    String? imageUrl,
    String? imageExtension, // 🔥 NOUVEAU
    String? imagePath, // 🔥 NOUVEAU
    bool? isActive,
    int? maxClicksPerUser,
    double? conversionRate,
    int? conversions,
    String? advertiserId, // 🔥 NOUVEAU
    // NOUVEAUX CHAMPS AJOUTÉS
    String? campaignType,
    double? marketplaceFee,
    double? totalDeduction,
  }) {
    return CampaignModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      title: title ?? this.title,
      description: description ?? this.description,
      targetUrl: targetUrl ?? this.targetUrl,
      type: type ?? this.type,
      status: status ?? this.status,
      budget: budget ?? this.budget,
      spent: spent ?? this.spent,
      cpc: cpc ?? this.cpc,
      targetClicks: targetClicks ?? this.targetClicks,
      achievedClicks: achievedClicks ?? this.achievedClicks,
      uniqueClicks: uniqueClicks ?? this.uniqueClicks,
      targetRegions: targetRegions ?? this.targetRegions,
      targetLocation: targetLocation ?? this.targetLocation,
      targetRadius: targetRadius ?? this.targetRadius,
      createdAt: createdAt ?? this.createdAt,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      imageUrl: imageUrl ?? this.imageUrl,
      imageExtension: imageExtension ?? this.imageExtension, // 🔥 NOUVEAU
      imagePath: imagePath ?? this.imagePath, // 🔥 NOUVEAU
      isActive: isActive ?? this.isActive,
      maxClicksPerUser: maxClicksPerUser ?? this.maxClicksPerUser,
      conversionRate: conversionRate ?? this.conversionRate,
      conversions: conversions ?? this.conversions,
      advertiserId: advertiserId ?? this.advertiserId, // 🔥 NOUVEAU
      // NOUVEAUX CHAMPS AJOUTÉS
      campaignType: campaignType ?? this.campaignType,
      marketplaceFee: marketplaceFee ?? this.marketplaceFee,
      totalDeduction: totalDeduction ?? this.totalDeduction,
    );
  }

  /// 🔥 NOUVELLE MÉTHODE : Pour mettre à jour l'image
  CampaignModel withImage({
    required String imageUrl,
    required String imageExtension,
    String? imagePath,
  }) {
    return copyWith(
      imageUrl: imageUrl,
      imageExtension: imageExtension,
      imagePath: imagePath,
    );
  }

  /// NOUVELLE MÉTHODE : Pour mettre à jour le type de campagne
  CampaignModel withCampaignType({
    required String campaignType,
    double? marketplaceFee,
    double? totalDeduction,
  }) {
    return copyWith(
      campaignType: campaignType,
      marketplaceFee: marketplaceFee,
      totalDeduction: totalDeduction,
    );
  }

  /// 🔥 NOUVELLE MÉTHODE : Pour activer la campagne
  CampaignModel activate() {
    return copyWith(
      status: CampaignStatus.active,
      isActive: true,
      startDate: DateTime.now(),
    );
  }

  /// 🔥 NOUVELLE MÉTHODE : Pour mettre en pause la campagne
  CampaignModel pause() {
    return copyWith(status: CampaignStatus.paused, isActive: false);
  }

  /// 🔥 NOUVELLE MÉTHODE : Pour compléter la campagne
  CampaignModel complete() {
    return copyWith(
      status: CampaignStatus.completed,
      isActive: false,
      endDate: DateTime.now(),
    );
  }

  /// 🔥 NOUVELLE MÉTHODE : Pour rejeter la campagne
  CampaignModel reject() {
    return copyWith(status: CampaignStatus.rejected, isActive: false);
  }

  /// 🔥 NOUVELLE MÉTHODE : Pour approuver la campagne
  CampaignModel approve() {
    return copyWith(status: CampaignStatus.approved);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CampaignModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'CampaignModel(id: $id, title: $title, type: $type, campaignType: $campaignType, status: $status, budget: $budget, cpc: $cpc, imageUrl: $imageUrl, hasImage: $hasImage)';
  }
}

enum CampaignType { open, regional, precise }

enum CampaignStatus { pending, approved, active, paused, completed, rejected }

class Location {
  final double latitude;
  final double longitude;
  final String? address;

  Location({required this.latitude, required this.longitude, this.address});

  factory Location.fromMap(Map<String, dynamic> map) {
    return Location(
      latitude: _safeDouble(map['latitude']),
      longitude: _safeDouble(map['longitude']),
      address: map['address']?.toString(),
    );
  }

  static double _safeDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toMap() {
    return {'latitude': latitude, 'longitude': longitude, 'address': address};
  }

  Location copyWith({double? latitude, double? longitude, String? address}) {
    return Location(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
    );
  }

  @override
  String toString() {
    return 'Location(lat: $latitude, lng: $longitude, address: $address)';
  }
}

/// 🔥 NOUVELLE CLASSE : Pour les statistiques de campagne
class CampaignStats {
  final int totalClicks;
  final int uniqueClicks;
  final double totalSpent;
  final double conversionRate;
  final int sharesCount;
  final Map<String, int> clicksByRegion;
  final Map<String, int> clicksByDevice;

  CampaignStats({
    required this.totalClicks,
    required this.uniqueClicks,
    required this.totalSpent,
    required this.conversionRate,
    required this.sharesCount,
    required this.clicksByRegion,
    required this.clicksByDevice,
  });

  factory CampaignStats.fromMap(Map<String, dynamic> map) {
    return CampaignStats(
      totalClicks: map['totalClicks'] ?? 0,
      uniqueClicks: map['uniqueClicks'] ?? 0,
      totalSpent: (map['totalSpent'] ?? 0).toDouble(),
      conversionRate: (map['conversionRate'] ?? 0).toDouble(),
      sharesCount: map['sharesCount'] ?? 0,
      clicksByRegion: Map<String, int>.from(map['clicksByRegion'] ?? {}),
      clicksByDevice: Map<String, int>.from(map['clicksByDevice'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalClicks': totalClicks,
      'uniqueClicks': uniqueClicks,
      'totalSpent': totalSpent,
      'conversionRate': conversionRate,
      'sharesCount': sharesCount,
      'clicksByRegion': clicksByRegion,
      'clicksByDevice': clicksByDevice,
    };
  }
}
