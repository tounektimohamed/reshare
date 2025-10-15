
import 'package:cloud_firestore/cloud_firestore.dart';

enum ClickStatus {
  valid,
  pending,
  suspicious,
  invalid,
  fraud,
}

class ClickModel {
  final String id;
  final String campaignId;
  final String shareId;
  final String userId;
  final String participantId;
  final String campaignTitle;
  final double earnings;
  final double platformEarnings;
  final double totalEarnings;
  final ClickStatus status;
  final DateTime clickedAt; // 🔥 CHANGEMENT: DateTime au lieu de String
  final String ip;
  final String userAgent;
  final String referrer;
  final String deviceHash;
  final bool processed;

  ClickModel({
    required this.id,
    required this.campaignId,
    required this.shareId,
    required this.userId,
    required this.participantId,
    required this.campaignTitle,
    required this.earnings,
    required this.platformEarnings,
    required this.totalEarnings,
    required this.status,
    required this.clickedAt,
    required this.ip,
    required this.userAgent,
    required this.referrer,
    required this.deviceHash,
    required this.processed,
  });

  factory ClickModel.fromMap(Map<String, dynamic> map) {
    try {
      return ClickModel(
        id: map['id']?.toString() ?? '',
        campaignId: map['campaignId']?.toString() ?? '',
        shareId: map['shareId']?.toString() ?? '',
        userId: map['userId']?.toString() ?? '',
        participantId: map['participantId']?.toString() ?? '',
        campaignTitle: map['campaignTitle']?.toString() ?? 'حملة غير معروفة',
        earnings: _parseDouble(map['earnings']),
        platformEarnings: _parseDouble(map['platformEarnings']),
        totalEarnings: _parseDouble(map['totalEarnings']),
        status: _parseClickStatus(map['status']),
        clickedAt: _parseTimestamp(map['clickedAt']), // 🔥 CORRECTION
        ip: map['ip']?.toString() ?? '0.0.0.0',
        userAgent: map['userAgent']?.toString() ?? '',
        referrer: map['referrer']?.toString() ?? '',
        deviceHash: map['deviceHash']?.toString() ?? '',
        processed: map['processed'] == true,
      );
    } catch (e) {
      print('❌ Error parsing ClickModel: $e');
      print('📋 Map data: $map');
      rethrow;
    }
  }

  // 🔥 METHODES DE PARSING SÉCURISÉES
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static ClickStatus _parseClickStatus(dynamic status) {
    if (status == null) return ClickStatus.valid;
    
    if (status is int) {
      return ClickStatus.values[status.clamp(0, ClickStatus.values.length - 1)];
    }
    
    if (status is String) {
      switch (status.toLowerCase()) {
        case 'valid': return ClickStatus.valid;
        case 'pending': return ClickStatus.pending;
        case 'suspicious': return ClickStatus.suspicious;
        case 'invalid': return ClickStatus.invalid;
        case 'fraud': return ClickStatus.fraud;
        default: return ClickStatus.valid;
      }
    }
    
    return ClickStatus.valid;
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    try {
      if (timestamp == null) {
        return DateTime.now();
      }
      
      if (timestamp is Timestamp) {
        return timestamp.toDate();
      }
      
      if (timestamp is DateTime) {
        return timestamp;
      }
      
      if (timestamp is String) {
        return DateTime.tryParse(timestamp) ?? DateTime.now();
      }
      
      if (timestamp is int) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
      
      return DateTime.now();
    } catch (e) {
      print('❌ Error parsing timestamp: $e');
      return DateTime.now();
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'campaignId': campaignId,
      'shareId': shareId,
      'userId': userId,
      'participantId': participantId,
      'campaignTitle': campaignTitle,
      'earnings': earnings,
      'platformEarnings': platformEarnings,
      'totalEarnings': totalEarnings,
      'status': status.index,
      'clickedAt': Timestamp.fromDate(clickedAt), // 🔥 Conversion pour Firestore
      'ip': ip,
      'userAgent': userAgent,
      'referrer': referrer,
      'deviceHash': deviceHash,
      'processed': processed,
    };
  }

  @override
  String toString() {
    return 'ClickModel(id: $id, campaign: $campaignTitle, earnings: $earnings, date: $clickedAt)';
  }
}