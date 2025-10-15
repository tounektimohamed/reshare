
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
  final bool isActive;
  final int maxClicksPerUser;
  final double conversionRate;
  final int conversions;

  CampaignModel({
    required this.id,
    required this.businessId,
    required this.title,
    required this.description,
    required this.targetUrl,
    required this.type,
    this.status = CampaignStatus.pending,
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
    this.isActive = true,
    this.maxClicksPerUser = 3,
    this.conversionRate = 0.0,
    this.conversions = 0,
  });

  int get remainingClicks => targetClicks - achievedClicks;
  double get remainingBudget => budget - spent;
  double get participantEarnings => cpc * 0.6;

  factory CampaignModel.fromMap(Map<String, dynamic> map) {
    return CampaignModel(
      id: map['id']?.toString() ?? '',
      businessId: map['businessId']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      targetUrl: map['targetUrl']?.toString() ?? '',
      type: _parseCampaignType(map['type']), // 🔥 CORRECTION ICI
      status: _parseCampaignStatus(map['status']), // 🔥 CORRECTION ICI
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
      isActive: map['isActive'] == true,
      maxClicksPerUser: _safeInt(map['maxClicksPerUser']),
      conversionRate: _safeDouble(map['conversionRate']),
      conversions: _safeInt(map['conversions']),
    );
  }

  // 🔥 NOUVELLE MÉTHODE : Parser CampaignType de manière sécurisée
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

  // 🔥 NOUVELLE MÉTHODE : Parser CampaignStatus de manière sécurisée
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
      'type': type.index, // 🔥 Toujours stocker comme int
      'status': status.index, // 🔥 Toujours stocker comme int
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
      'isActive': isActive,
      'maxClicksPerUser': maxClicksPerUser,
      'conversionRate': conversionRate,
      'conversions': conversions,
    };
  }

  /// إنشاء نسخة معدلة من الحملة
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
    bool? isActive,
    int? maxClicksPerUser,
    double? conversionRate,
    int? conversions,
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
      isActive: isActive ?? this.isActive,
      maxClicksPerUser: maxClicksPerUser ?? this.maxClicksPerUser,
      conversionRate: conversionRate ?? this.conversionRate,
      conversions: conversions ?? this.conversions,
    );
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
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
    };
  }
}