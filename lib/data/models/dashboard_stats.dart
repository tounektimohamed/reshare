class DashboardStats {
  final double totalEarnings;
  final double availableBalance;
  final double pendingBalance;
  final int totalClicks;
  final int totalShares;
  final int referralCount;
  final double weeklyEarnings;
  final int weeklyClicks;
  final double monthlyEarnings;
  final int monthlyClicks;
  final double conversionRate;
  final int activeCampaigns;

  DashboardStats({
    this.totalEarnings = 0.0,
    this.availableBalance = 0.0,
    this.pendingBalance = 0.0,
    this.totalClicks = 0,
    this.totalShares = 0,
    this.referralCount = 0,
    this.weeklyEarnings = 0.0,
    this.weeklyClicks = 0,
    this.monthlyEarnings = 0.0,
    this.monthlyClicks = 0,
    this.conversionRate = 0.0,
    this.activeCampaigns = 0,
  });

  /// Revenu quotidien moyen
  double get dailyAverageEarnings {
    return weeklyEarnings / 7;
  }

  /// Taux de clics hebdomadaire
  double get weeklyClickRate {
    return weeklyClicks / 7;
  }

  /// Taux de croissance mensuelle
  double get monthlyGrowth {
    if (totalEarnings == 0) return 0.0;
    return ((monthlyEarnings / totalEarnings) - 1) * 100;
  }

  /// Taux de croissance hebdomadaire
  double get weeklyGrowth {
    if (monthlyEarnings == 0) return 0.0;
    return ((weeklyEarnings / monthlyEarnings) - 1) * 100;
  }

  /// Créer une copie avec des valeurs mises à jour
  DashboardStats copyWith({
    double? totalEarnings,
    double? availableBalance,
    double? pendingBalance,
    int? totalClicks,
    int? totalShares,
    int? referralCount,
    double? weeklyEarnings,
    int? weeklyClicks,
    double? monthlyEarnings,
    int? monthlyClicks,
    double? conversionRate,
    int? activeCampaigns,
  }) {
    return DashboardStats(
      totalEarnings: totalEarnings ?? this.totalEarnings,
      availableBalance: availableBalance ?? this.availableBalance,
      pendingBalance: pendingBalance ?? this.pendingBalance,
      totalClicks: totalClicks ?? this.totalClicks,
      totalShares: totalShares ?? this.totalShares,
      referralCount: referralCount ?? this.referralCount,
      weeklyEarnings: weeklyEarnings ?? this.weeklyEarnings,
      weeklyClicks: weeklyClicks ?? this.weeklyClicks,
      monthlyEarnings: monthlyEarnings ?? this.monthlyEarnings,
      monthlyClicks: monthlyClicks ?? this.monthlyClicks,
      conversionRate: conversionRate ?? this.conversionRate,
      activeCampaigns: activeCampaigns ?? this.activeCampaigns,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalEarnings': totalEarnings,
      'availableBalance': availableBalance,
      'pendingBalance': pendingBalance,
      'totalClicks': totalClicks,
      'totalShares': totalShares,
      'referralCount': referralCount,
      'weeklyEarnings': weeklyEarnings,
      'weeklyClicks': weeklyClicks,
      'monthlyEarnings': monthlyEarnings,
      'monthlyClicks': monthlyClicks,
      'conversionRate': conversionRate,
      'activeCampaigns': activeCampaigns,
    };
  }

  factory DashboardStats.fromMap(Map<String, dynamic> map) {
    return DashboardStats(
      totalEarnings: (map['totalEarnings'] ?? 0).toDouble(),
      availableBalance: (map['availableBalance'] ?? 0).toDouble(),
      pendingBalance: (map['pendingBalance'] ?? 0).toDouble(),
      totalClicks: (map['totalClicks'] ?? 0).toInt(),
      totalShares: (map['totalShares'] ?? 0).toInt(),
      referralCount: (map['referralCount'] ?? 0).toInt(),
      weeklyEarnings: (map['weeklyEarnings'] ?? 0).toDouble(),
      weeklyClicks: (map['weeklyClicks'] ?? 0).toInt(),
      monthlyEarnings: (map['monthlyEarnings'] ?? 0).toDouble(),
      monthlyClicks: (map['monthlyClicks'] ?? 0).toInt(),
      conversionRate: (map['conversionRate'] ?? 0).toDouble(),
      activeCampaigns: (map['activeCampaigns'] ?? 0).toInt(),
    );
  }

  @override
  String toString() {
    return 'DashboardStats(totalEarnings: $totalEarnings, availableBalance: $availableBalance, pendingBalance: $pendingBalance, totalClicks: $totalClicks)';
  }
}
// === lib/data/models/referral_model.dart ===

class ReferralModel {
  final String id;
  final String referrerId;
  final String newUserId;
  final String referralCode;
  final double rewardAmount;
  final ReferralStatus status;
  final int newUserClicks;
  final int clicksRequired;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? paidAt;

  ReferralModel({
    required this.id,
    required this.referrerId,
    required this.newUserId,
    required this.referralCode,
    required this.rewardAmount,
    this.status = ReferralStatus.pending,
    this.newUserClicks = 0,
    this.clicksRequired = 10,
    required this.createdAt,
    this.completedAt,
    this.paidAt,
  });

  int get remainingClicks => clicksRequired - newUserClicks;
  bool get isCompleted => newUserClicks >= clicksRequired;

  factory ReferralModel.fromMap(Map<String, dynamic> map) {
    return ReferralModel(
      id: map['id'] ?? '',
      referrerId: map['referrerId'] ?? '',
      newUserId: map['newUserId'] ?? '',
      referralCode: map['referralCode'] ?? '',
      rewardAmount: (map['rewardAmount'] ?? 0).toDouble(),
      status: ReferralStatus.values[map['status'] ?? 0],
      newUserClicks: map['newUserClicks'] ?? 0,
      clicksRequired: map['clicksRequired'] ?? 10,
      createdAt: DateTime.parse(map['createdAt']),
      completedAt: map['completedAt'] != null ? DateTime.parse(map['completedAt']) : null,
      paidAt: map['paidAt'] != null ? DateTime.parse(map['paidAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'referrerId': referrerId,
      'newUserId': newUserId,
      'referralCode': referralCode,
      'rewardAmount': rewardAmount,
      'status': status.index,
      'newUserClicks': newUserClicks,
      'clicksRequired': clicksRequired,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'paidAt': paidAt?.toIso8601String(),
    };
  }
}

enum ReferralStatus { pending, completed, paid, expired, cancelled }