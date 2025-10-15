
// === lib/data/repositories/click_repository.dart ===

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/click_model.dart';

class ClickRepository {
  final FirebaseFirestore _firestore;

  ClickRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _clicksCollection => _firestore.collection('clicks');

  Future<void> createClick(ClickModel click) async {
    try {
      await _clicksCollection.doc(click.id).set(click.toMap());
    } catch (e) {
      throw Exception('فشل في إنشاء النقرة: $e');
    }
  }

  Future<List<ClickModel>> getUserClicks({
    required String userId,
    int limit = 10,
  }) async {
    try {
      print('🔄 Fetching clicks for user: $userId');
      
      final snapshot = await _clicksCollection
          .where('userId', isEqualTo: userId)
          .get();

      print('📊 Found ${snapshot.docs.length} clicks in database');

      final clicks = <ClickModel>[];
      
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          print('🔍 Processing click ${doc.id}: ${data['campaignTitle']}');
          
          final click = ClickModel.fromMap({
            ...data,
            'id': doc.id, // 🔥 IMPORTANT: Ajouter l'ID du document
          });
          
          clicks.add(click);
          print('✅ Successfully parsed click: ${click.campaignTitle}');
        } catch (e) {
          print('❌ Error parsing click document ${doc.id}: $e');
          continue; // Continuer avec les documents suivants
        }
      }

      // Trier localement par date (plus récent en premier)
      clicks.sort((a, b) => b.clickedAt.compareTo(a.clickedAt));

      final result = clicks.take(limit).toList();
      print('🎯 Returning ${result.length} recent clicks');
      
      return result;
    } catch (e) {
      print('❌ Error in getUserClicks: $e');
      throw Exception('فشل في جلب نقرات المستخدم: $e');
    }
  }

  Future<List<ClickModel>> getCampaignClicks(String campaignId) async {
    try {
      final snapshot = await _clicksCollection
          .where('campaignId', isEqualTo: campaignId)
          .get();

      final clicks = snapshot.docs
          .map((doc) => ClickModel.fromMap({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              }))
          .toList();

      clicks.sort((a, b) => b.clickedAt.compareTo(a.clickedAt));

      return clicks;
    } catch (e) {
      print('❌ Error getting campaign clicks: $e');
      throw Exception('فشل في جلب نقرات الحملة: $e');
    }
  }

  Future<List<ClickModel>> getUserClicksForCampaign({
    required String userId,
    required String campaignId,
  }) async {
    try {
      final snapshot = await _clicksCollection
          .where('userId', isEqualTo: userId)
          .where('campaignId', isEqualTo: campaignId)
          .get();

      final clicks = snapshot.docs
          .map((doc) => ClickModel.fromMap({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              }))
          .toList();

      clicks.sort((a, b) => b.clickedAt.compareTo(a.clickedAt));

      return clicks;
    } catch (e) {
      print('❌ Error getting user clicks for campaign: $e');
      throw Exception('فشل في جلب نقرات المستخدم للحملة: $e');
    }
  }

  Future<String> generateTrackingId({
    required String userId,
    required String campaignId,
  }) async {
    return '${userId}_${campaignId}_${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<List<ClickModel>> getEarningClicks({
    required String userId,
    int? limit,
  }) async {
    try {
      final snapshot = await _clicksCollection
          .where('userId', isEqualTo: userId)
          .where('earnings', isGreaterThan: 0)
          .get();

      final clicks = snapshot.docs
          .map((doc) => ClickModel.fromMap({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              }))
          .toList();

      // Tri local : d'abord par earnings, puis par clickedAt
      clicks.sort((a, b) {
        int earnCompare = b.earnings.compareTo(a.earnings);
        if (earnCompare != 0) return earnCompare;
        return b.clickedAt.compareTo(a.clickedAt);
      });

      if (limit != null) {
        return clicks.take(limit).toList();
      }
      return clicks;
    } catch (e) {
      print('❌ Error getting earning clicks: $e');
      throw Exception('فشل في جلب النقرات المربحة: $e');
    }
  }

  Future<ClickStats> getUserStats({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final snapshot = await _clicksCollection
          .where('userId', isEqualTo: userId)
          .get();

      final clicks = snapshot.docs
          .map((doc) => ClickModel.fromMap({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              }))
          .where((c) =>
              c.clickedAt.isAfter(startDate) &&
              c.clickedAt.isBefore(endDate) &&
              c.status == ClickStatus.valid)
          .toList();

      final totalEarnings = clicks.fold(0.0, (sum, click) => sum + click.earnings);
      final totalClicks = clicks.length;
      final averageEarnings = totalClicks > 0 ? totalEarnings / totalClicks : 0.0;
      final conversionRate = totalClicks > 0 ? (clicks.length / totalClicks) * 100 : 0.0;

      return ClickStats(
        totalEarnings: totalEarnings,
        totalClicks: totalClicks,
        averageEarnings: averageEarnings,
        conversionRate: conversionRate,
      );
    } catch (e) {
      print('❌ Error getting user stats: $e');
      throw Exception('فشل في جلب إحصائيات المستخدم: $e');
    }
  }
}

class ClickStats {
  final double totalEarnings;
  final int totalClicks;
  final double averageEarnings;
  final double conversionRate;

  ClickStats({
    required this.totalEarnings,
    required this.totalClicks,
    required this.averageEarnings,
    required this.conversionRate,
  });
}