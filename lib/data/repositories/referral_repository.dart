import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/referral_model.dart';
import '../models/user_model.dart';

/// مستودع الإحالات - مسؤول عن جميع عمليات الإحالة في قاعدة البيانات
class ReferralRepository {
  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  ReferralRepository({
    FirebaseFirestore? firestore,
    Uuid? uuid,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _uuid = uuid ?? Uuid();

  // مراجع المجموعات - AJOUTÉES
  CollectionReference get _referralsCollection => _firestore.collection('referrals');
  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference get _referralSharesCollection => _firestore.collection('referral_shares');
  CollectionReference get _invitationsCollection => _firestore.collection('invitations');

  /// إنشاء إحالة جديدة
  Future<ReferralModel> createReferral({
    required String referrerId,
    required String newUserId,
    required String referralCode,
    double rewardAmount = 0.6,
    int clicksRequired = 10,
  }) async {
    try {
      final referralId = _uuid.v4();
      final referral = ReferralModel(
        id: referralId,
        referrerId: referrerId,
        newUserId: newUserId,
        referralCode: referralCode,
        rewardAmount: rewardAmount,
        clicksRequired: clicksRequired,
        createdAt: DateTime.now(),
        status: ReferralStatus.pending,
        newUserClicks: 0,
      );

      await _referralsCollection.doc(referralId).set(referral.toMap());

      return referral;
    } catch (e) {
      throw Exception('فشل في إنشاء الإحالة: $e');
    }
  }

  /// تسجيل مشاركة رابط الإحالة
  Future<void> recordReferralShare({
    required String userId,
    required String referralCode,
    String? platform,
  }) async {
    try {
      final shareId = _uuid.v4();
      await _referralSharesCollection.doc(shareId).set({
        'id': shareId,
        'userId': userId,
        'referralCode': referralCode,
        'platform': platform ?? 'direct',
        'sharedAt': FieldValue.serverTimestamp(),
        'ipAddress': '', // يمكن إضافة IP address إذا كان متاحاً
      });
    } catch (e) {
      throw Exception('فشل في تسجيل مشاركة الإحالة: $e');
    }
  }

  /// تسجيل إرسال دعوة
  Future<void> recordInvitationSent({
    required String userId,
    required String platform,
    required String contactInfo,
  }) async {
    try {
      final invitationId = _uuid.v4();
      await _invitationsCollection.doc(invitationId).set({
        'id': invitationId,
        'userId': userId,
        'platform': platform,
        'contactInfo': contactInfo,
        'sentAt': FieldValue.serverTimestamp(),
        'status': 'sent', // sent, delivered, clicked, converted
      });
    } catch (e) {
      throw Exception('فشل في تسجيل إرسال الدعوة: $e');
    }
  }

  /// تحديث حالة الدعوة
  Future<void> updateInvitationStatus({
    required String invitationId,
    required String status,
    String? referralId,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (referralId != null) {
        updateData['referralId'] = referralId;
      }

      await _invitationsCollection.doc(invitationId).update(updateData);
    } catch (e) {
      throw Exception('فشل في تحديث حالة الدعوة: $e');
    }
  }

  /// جلب إحصائيات مشاركات الإحالة
  Future<ReferralShareStats> getReferralShareStats(String userId) async {
    try {
      final snapshot = await _referralSharesCollection
          .where('userId', isEqualTo: userId)
          .get();

      final shares = snapshot.docs;
      
      // تجميع الإحصائيات حسب المنصة
      final platformStats = <String, int>{};
      for (final share in shares) {
        final data = share.data() as Map<String, dynamic>;
        final platform = data['platform'] ?? 'unknown';
        platformStats[platform] = (platformStats[platform] ?? 0) + 1;
      }

      // الحصول على أول وآخر مشاركة
      DateTime? firstShare;
      DateTime? lastShare;
      
      if (shares.isNotEmpty) {
        final firstData = shares.last.data() as Map<String, dynamic>;
        final lastData = shares.first.data() as Map<String, dynamic>;
        
        firstShare = (firstData['sharedAt'] as Timestamp).toDate();
        lastShare = (lastData['sharedAt'] as Timestamp).toDate();
      }

      return ReferralShareStats(
        totalShares: shares.length,
        platformStats: platformStats,
        firstShare: firstShare,
        lastShare: lastShare,
      );
    } catch (e) {
      throw Exception('فشل في جلب إحصائيات المشاركات: $e');
    }
  }

  /// جلب إحصائيات الدعوات
  Future<InvitationStats> getInvitationStats(String userId) async {
    try {
      final snapshot = await _invitationsCollection
          .where('userId', isEqualTo: userId)
          .get();

      final invitations = snapshot.docs;
      
      // تجميع الإحصائيات حسب الحالة والمنصة
      final statusStats = <String, int>{};
      final platformStats = <String, int>{};
      
      for (final invitation in invitations) {
        final data = invitation.data() as Map<String, dynamic>;
        final status = data['status'] ?? 'unknown';
        final platform = data['platform'] ?? 'unknown';
        
        statusStats[status] = (statusStats[status] ?? 0) + 1;
        platformStats[platform] = (platformStats[platform] ?? 0) + 1;
      }

      return InvitationStats(
        totalInvitations: invitations.length,
        statusStats: statusStats,
        platformStats: platformStats,
        conversionRate: invitations.isNotEmpty 
            ? ((statusStats['converted'] ?? 0) / invitations.length) * 100
            : 0.0,
      );
    } catch (e) {
      throw Exception('فشل في جلب إحصائيات الدعوات: $e');
    }
  }

  /// جلب إحالات المستخدم
 Future<List<ReferralModel>> getUserReferrals(String userId) async {
  try {
    final snapshot = await _referralsCollection
        .where('referrerId', isEqualTo: userId)
        .get();

    final referrals = snapshot.docs
        .map((doc) => ReferralModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();

    // Tri localement par date (createdAt) du plus récent au plus ancien
    referrals.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return referrals;
  } catch (e) {
    throw Exception('فشل في جلب إحالات المستخدم: $e');
  }
}


  /// جلب إحالة محددة
  Future<ReferralModel?> getReferralById(String referralId) async {
    try {
      final doc = await _referralsCollection.doc(referralId).get();
      if (doc.exists) {
        return ReferralModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('فشل في جلب الإحالة: $e');
    }
  }

  /// تحديث حالة الإحالة
  Future<void> updateReferralStatus({
    required String referralId,
    required ReferralStatus status,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status.index,
      };

      // إضافة التواريخ المناسبة بناءً على الحالة
      switch (status) {
        case ReferralStatus.completed:
          updateData['completedAt'] = DateTime.now().toIso8601String();
          break;
        case ReferralStatus.paid:
          updateData['paidAt'] = DateTime.now().toIso8601String();
          break;
        case ReferralStatus.expired:
        case ReferralStatus.cancelled:
          // لا نحتاج لتواريخ إضافية لهذه الحالات
          break;
        case ReferralStatus.pending:
          // إعادة التعيين إلى pending
          updateData['completedAt'] = null;
          updateData['paidAt'] = null;
          break;
      }

      await _referralsCollection.doc(referralId).update(updateData);
    } catch (e) {
      throw Exception('فشل في تحديث حالة الإحالة: $e');
    }
  }

  /// زيادة عداد نقرات المستخدم الجديد
  Future<void> incrementNewUserClicks(String referralId) async {
    try {
      await _referralsCollection.doc(referralId).update({
        'newUserClicks': FieldValue.increment(1),
      });

      // التحقق إذا وصل إلى النقرات المطلوبة
      final referral = await getReferralById(referralId);
      if (referral != null && 
          referral.isCompleted && 
          referral.status == ReferralStatus.pending) {
        await updateReferralStatus(
          referralId: referralId,
          status: ReferralStatus.completed,
        );
      }
    } catch (e) {
      throw Exception('فشل في زيادة نقرات المستخدم الجديد: $e');
    }
  }

  /// تحديث عدد نقرات المستخدم الجديد
  Future<void> updateNewUserClicks({
    required String referralId,
    required int newUserClicks,
  }) async {
    try {
      await _referralsCollection.doc(referralId).update({
        'newUserClicks': newUserClicks,
      });

      // التحقق إذا وصل إلى النقرات المطلوبة
      final referral = await getReferralById(referralId);
      if (referral != null && 
          referral.isCompleted && 
          referral.status == ReferralStatus.pending) {
        await updateReferralStatus(
          referralId: referralId,
          status: ReferralStatus.completed,
        );
      }
    } catch (e) {
      throw Exception('فشل في تحديث نقرات المستخدم الجديد: $e');
    }
  }

  /// جلب الإحالة بواسطة المستخدم الجديد
  Future<ReferralModel?> getReferralByNewUser(String newUserId) async {
    try {
      final snapshot = await _referralsCollection
          .where('newUserId', isEqualTo: newUserId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return ReferralModel.fromMap(snapshot.docs.first.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('فشل في جلب الإحالة بواسطة المستخدم الجديد: $e');
    }
  }

  /// جلب الإحالة بواسطة كود الإحالة والمستخدم الجديد
  Future<ReferralModel?> getReferralByCodeAndNewUser({
    required String referralCode,
    required String newUserId,
  }) async {
    try {
      final snapshot = await _referralsCollection
          .where('referralCode', isEqualTo: referralCode)
          .where('newUserId', isEqualTo: newUserId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return ReferralModel.fromMap(snapshot.docs.first.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('فشل في جلب الإحالة بواسطة الكود والمستخدم: $e');
    }
  }

  /// التحقق من وجود إحالة نشطة للمستخدم الجديد
  Future<bool> hasActiveReferral(String newUserId) async {
    try {
      final snapshot = await _referralsCollection
          .where('newUserId', isEqualTo: newUserId)
          .where('status', whereIn: [
            ReferralStatus.pending.index,
            ReferralStatus.completed.index,
          ])
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('فشل في التحقق من الإحالة النشطة: $e');
    }
  }

  /// جلب عدد الإحالات حسب الحالة
  Future<Map<ReferralStatus, int>> getReferralCountsByStatus(String userId) async {
    try {
      final referrals = await getUserReferrals(userId);
      
      final counts = <ReferralStatus, int>{};
      for (final status in ReferralStatus.values) {
        counts[status] = referrals.where((r) => r.status == status).length;
      }
      
      return counts;
    } catch (e) {
      throw Exception('فشل في جلب عدد الإحالات حسب الحالة: $e');
    }
  }

  /// جلب الإحالات المكتملة وغير المدفوعة
  Future<List<ReferralModel>> getCompletedUnpaidReferrals(String userId) async {
    try {
      final referrals = await getUserReferrals(userId);
      return referrals.where((referral) => 
        referral.status == ReferralStatus.completed
      ).toList();
    } catch (e) {
      throw Exception('فشل في جلب الإحالات المكتملة غير المدفوعة: $e');
    }
  }

  /// جلب الإحالات القابلة للدفع (مكتملة وغير مدفوعة)
  Future<List<ReferralModel>> getPayableReferrals(String userId) async {
    try {
      final referrals = await getUserReferrals(userId);
      return referrals.where((referral) => 
        referral.status == ReferralStatus.completed
      ).toList();
    } catch (e) {
      throw Exception('فشل في جلب الإحالات القابلة للدفع: $e');
    }
  }

  /// تحديث مكافأة الإحالة
  Future<void> updateRewardAmount({
    required String referralId,
    required double rewardAmount,
  }) async {
    try {
      await _referralsCollection.doc(referralId).update({
        'rewardAmount': rewardAmount,
      });
    } catch (e) {
      throw Exception('فشل في تحديث مكافأة الإحالة: $e');
    }
  }

  /// تعليق الإحالة
  Future<void> cancelReferral({
    required String referralId,
    String? reason,
  }) async {
    try {
      await updateReferralStatus(
        referralId: referralId,
        status: ReferralStatus.cancelled,
      );
    } catch (e) {
      throw Exception('فشل في تعليق الإحالة: $e');
    }
  }

  ///标记转介为已支付
  Future<void> markReferralAsPaid(String referralId) async {
    try {
      await updateReferralStatus(
        referralId: referralId,
        status: ReferralStatus.paid,
      );
    } catch (e) {
      throw Exception('فشل في标记转介为已支付: $e');
    }
  }

  /// جلب إحصائيات الإحالة للمستخدم
  Future<ReferralStats> getUserReferralStats(String userId) async {
    try {
      final referrals = await getUserReferrals(userId);
      
      final totalReferrals = referrals.length;
      final completedReferrals = referrals.where((r) => 
        r.status == ReferralStatus.completed || r.status == ReferralStatus.paid
      ).length;
      
      final pendingReferrals = referrals.where((r) => 
        r.status == ReferralStatus.pending
      ).length;
      
      final paidReferrals = referrals.where((r) => 
        r.status == ReferralStatus.paid
      ).length;
      
      final totalEarnings = referrals.where((r) => 
        r.status == ReferralStatus.paid
      ).fold(0.0, (sum, r) => sum + r.rewardAmount);
      
      final potentialEarnings = referrals.where((r) => 
        r.status == ReferralStatus.completed
      ).fold(0.0, (sum, r) => sum + r.rewardAmount);

      return ReferralStats(
        totalReferrals: totalReferrals,
        completedReferrals: completedReferrals,
        pendingReferrals: pendingReferrals,
        paidReferrals: paidReferrals,
        totalEarnings: totalEarnings,
        potentialEarnings: potentialEarnings,
        successRate: totalReferrals > 0 ? (completedReferrals / totalReferrals) * 100 : 0.0,
      );
    } catch (e) {
      throw Exception('فشل في جلب إحصائيات الإحالة: $e');
    }
  }

  /// جلب الإحالات التي تحتاج إلى عمل
  Future<List<ReferralModel>> getReferralsNeedingAction(String userId) async {
    try {
      final referrals = await getUserReferrals(userId);
      
      return referrals.where((referral) {
        // الإحالات المعلقة التي لم تكتمل بعد
        if (referral.status == ReferralStatus.pending && !referral.isCompleted) {
          return true;
        }
        
        // الإحالات المكتملة التي لم تدفع بعد
        if (referral.status == ReferralStatus.completed) {
          return true;
        }
        
        return false;
      }).toList();
    } catch (e) {
      throw Exception('فشل في جلب الإحالات التي تحتاج إلى عمل: $e');
    }
  }

  /// جلب تاريخ الإحالات
  Future<List<ReferralHistory>> getReferralHistory(String userId) async {
    try {
      final referrals = await getUserReferrals(userId);
      
      return referrals.map((referral) {
        return ReferralHistory(
          referral: referral,
          referredUser: null, // يمكن جلب بيانات المستخدم المسجل إذا لزم الأمر
          status: _getStatusText(referral.status),
          progress: (referral.newUserClicks / referral.clicksRequired) * 100,
          daysSinceCreation: DateTime.now().difference(referral.createdAt).inDays,
        );
      }).toList();
    } catch (e) {
      throw Exception('فشل في جلب تاريخ الإحالات: $e');
    }
  }

  /// البحث في الإحالات
  Future<List<ReferralModel>> searchReferrals({
    required String userId,
    required String query,
  }) async {
    try {
      final referrals = await getUserReferrals(userId);
      
      if (query.isEmpty) {
        return referrals;
      }
      
      return referrals.where((referral) =>
        referral.referralCode.toLowerCase().contains(query.toLowerCase()) ||
        referral.newUserId.toLowerCase().contains(query.toLowerCase())
      ).toList();
    } catch (e) {
      throw Exception('فشل في البحث في الإحالات: $e');
    }
  }

  /// حذف الإحالة (لأغراض التطوير فقط)
  Future<void> deleteReferral(String referralId) async {
    try {
      await _referralsCollection.doc(referralId).delete();
    } catch (e) {
      throw Exception('فشل في حذف الإحالة: $e');
    }
  }

  // ============ METHODS HELPERS ============

  /// الحصول على نص الحالة
  String _getStatusText(ReferralStatus status) {
    switch (status) {
      case ReferralStatus.pending:
        return 'قيد الانتظار';
      case ReferralStatus.completed:
        return 'مكتمل';
      case ReferralStatus.paid:
        return 'تم الدفع';
      case ReferralStatus.expired:
        return 'منتهي الصلاحية';
      case ReferralStatus.cancelled:
        return 'ملغى';
    }
  }
}

// ============ CLASSES DE STATISTIQUES MANQUANTES - AJOUTÉES ============

/// إحصائيات مشاركات الإحالة
class ReferralShareStats {
  final int totalShares;
  final Map<String, int> platformStats;
  final DateTime? firstShare;
  final DateTime? lastShare;

  ReferralShareStats({
    required this.totalShares,
    required this.platformStats,
    this.firstShare,
    this.lastShare,
  });

  /// الحصول على المنصة الأكثر استخداماً
  String get mostUsedPlatform {
    if (platformStats.isEmpty) return 'لا توجد مشاركات';
    
    var maxPlatform = '';
    var maxCount = 0;
    
    platformStats.forEach((platform, count) {
      if (count > maxCount) {
        maxCount = count;
        maxPlatform = platform;
      }
    });
    
    return maxPlatform;
  }

  /// عدد الأيام منذ أول مشاركة
  int get daysSinceFirstShare {
    if (firstShare == null) return 0;
    return DateTime.now().difference(firstShare!).inDays;
  }
}

/// إحصائيات الدعوات
class InvitationStats {
  final int totalInvitations;
  final Map<String, int> statusStats;
  final Map<String, int> platformStats;
  final double conversionRate;

  InvitationStats({
    required this.totalInvitations,
    required this.statusStats,
    required this.platformStats,
    required this.conversionRate,
  });

  /// عدد الدعوات المقبولة
  int get acceptedInvitations => statusStats['converted'] ?? 0;

  /// عدد الدعوات المرسلة
  int get sentInvitations => statusStats['sent'] ?? 0;

  /// نسبة النجاح
  double get successRate {
    return totalInvitations > 0 ? (acceptedInvitations / totalInvitations) * 100 : 0.0;
  }
}

// ============ MODÈLES DE STATISTIQUES EXISTANTS ============

/// إحصائيات الإحالة
class ReferralStats {
  final int totalReferrals;
  final int completedReferrals;
  final int pendingReferrals;
  final int paidReferrals;
  final double totalEarnings;
  final double potentialEarnings;
  final double successRate;

  ReferralStats({
    required this.totalReferrals,
    required this.completedReferrals,
    required this.pendingReferrals,
    required this.paidReferrals,
    required this.totalEarnings,
    required this.potentialEarnings,
    required this.successRate,
  });

  /// إجمالي الأرباح المحتملة (مدفوعة + قابلة للدفع)
  double get totalPotentialEarnings => totalEarnings + potentialEarnings;

  /// عدد الإحالات النشطة (معلقة + مكتملة)
  int get activeReferrals => pendingReferrals + completedReferrals;

  /// نسبة الإحالات المدفوعة
  double get paidRate {
    return totalReferrals > 0 ? (paidReferrals / totalReferrals) * 100 : 0.0;
  }
}

/// تاريخ الإحالة
class ReferralHistory {
  final ReferralModel referral;
  final UserModel? referredUser;
  final String status;
  final double progress;
  final int daysSinceCreation;

  ReferralHistory({
    required this.referral,
    required this.referredUser,
    required this.status,
    required this.progress,
    required this.daysSinceCreation,
  });

  /// هل الإحالة نشطة
  bool get isActive => referral.status == ReferralStatus.pending;

  /// هل الإحالة مكتملة
  bool get isCompleted => referral.status == ReferralStatus.completed;

  /// هل الإحالة مدفوعة
  bool get isPaid => referral.status == ReferralStatus.paid;
}