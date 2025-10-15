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