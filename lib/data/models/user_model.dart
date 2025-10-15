
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String? phoneNumber;
  final double totalEarnings;
  final double availableBalance;
  final double pendingBalance;
  final int totalClicks;
  final int totalShares;
  final int referralCount;
  final UserType userType;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final LocationPreference locationPreference;
  final String? referralCode;
  final String? companyName;
  final String? taxNumber;
  final bool isVerified;
  final List<String>? preferredCategories;

  UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.phoneNumber,
    this.totalEarnings = 0.0,
    this.availableBalance = 0.0,
    this.pendingBalance = 0.0,
    this.totalClicks = 0,
    this.totalShares = 0,
    this.referralCount = 0,
    this.userType = UserType.participant,
    required this.createdAt,
    this.lastLogin,
    this.locationPreference = LocationPreference.open,
    this.referralCode,
    this.companyName,
    this.taxNumber,
    this.isVerified = false,
    this.preferredCategories,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    // 🔥 CORRECTION : Gestion robuste du userType
    UserType parseUserType(dynamic type) {
      if (type == null) return UserType.participant;
      
      if (type is int) {
        return UserType.values[type];
      }
      
      if (type is String) {
        switch (type.toLowerCase()) {
          case 'admin':
          case '0':
            return UserType.admin;
          case 'business':
          case '1':
            return UserType.business;
          case 'participant':
          case '2':
          default:
            return UserType.participant;
        }
      }
      
      return UserType.participant;
    }

    // 🔥 CORRECTION : Gestion robuste de locationPreference
    LocationPreference parseLocationPreference(dynamic preference) {
      if (preference == null) return LocationPreference.open;
      
      if (preference is int) {
        return LocationPreference.values[preference];
      }
      
      if (preference is String) {
        switch (preference.toLowerCase()) {
          case 'regional':
          case '1':
            return LocationPreference.regional;
          case 'precise':
          case '2':
            return LocationPreference.precise;
          case 'open':
          case '0':
          default:
            return LocationPreference.open;
        }
      }
      
      return LocationPreference.open;
    }

    return UserModel(
      id: map['id']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      displayName: map['displayName']?.toString() ?? '',
      phoneNumber: map['phoneNumber']?.toString(),
      totalEarnings: _safeDouble(map['totalEarnings']),
      availableBalance: _safeDouble(map['availableBalance']),
      pendingBalance: _safeDouble(map['pendingBalance']),
      totalClicks: _safeInt(map['totalClicks']),
      totalShares: _safeInt(map['totalShares']),
      referralCount: _safeInt(map['referralCount']),
      userType: parseUserType(map['userType']),
      createdAt: _parseDateTime(map['createdAt']),
      lastLogin: _parseDateTime(map['lastLogin']),
      locationPreference: parseLocationPreference(map['locationPreference']),
      referralCode: map['referralCode']?.toString(),
      companyName: map['companyName']?.toString(),
      taxNumber: map['taxNumber']?.toString(),
      isVerified: map['isVerified'] == true,
      preferredCategories: map['preferredCategories'] != null 
          ? List<String>.from(map['preferredCategories'].map((e) => e.toString()))
          : null,
    );
  }

  // 🔥 Méthodes utilitaires pour la conversion sécurisée
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
      'email': email,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'totalEarnings': totalEarnings,
      'availableBalance': availableBalance,
      'pendingBalance': pendingBalance,
      'totalClicks': totalClicks,
      'totalShares': totalShares,
      'referralCount': referralCount,
      'userType': userType.index, // 🔥 Toujours stocker comme int
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
      'locationPreference': locationPreference.index, // 🔥 Toujours stocker comme int
      'referralCode': referralCode,
      'companyName': companyName,
      'taxNumber': taxNumber,
      'isVerified': isVerified,
      'preferredCategories': preferredCategories,
    };
  }

  UserModel copyWith({
    String? email,
    String? displayName,
    String? phoneNumber,
    double? totalEarnings,
    double? availableBalance,
    double? pendingBalance,
    int? totalClicks,
    int? totalShares,
    int? referralCount,
    UserType? userType,
    DateTime? lastLogin,
    LocationPreference? locationPreference,
    String? referralCode,
    String? companyName,
    String? taxNumber,
    bool? isVerified,
    List<String>? preferredCategories,
  }) {
    return UserModel(
      id: id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      availableBalance: availableBalance ?? this.availableBalance,
      pendingBalance: pendingBalance ?? this.pendingBalance,
      totalClicks: totalClicks ?? this.totalClicks,
      totalShares: totalShares ?? this.totalShares,
      referralCount: referralCount ?? this.referralCount,
      userType: userType ?? this.userType,
      createdAt: createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      locationPreference: locationPreference ?? this.locationPreference,
      referralCode: referralCode ?? this.referralCode,
      companyName: companyName ?? this.companyName,
      taxNumber: taxNumber ?? this.taxNumber,
      isVerified: isVerified ?? this.isVerified,
      preferredCategories: preferredCategories ?? this.preferredCategories,
    );
  }
}

enum UserType { participant, business, admin }
enum LocationPreference { open, regional, precise }