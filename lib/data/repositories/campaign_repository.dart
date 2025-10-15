
// === lib/data/repositories/campaign_repository.dart ===

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reshare/data/models/user_model.dart';
import '../models/campaign_model.dart';

class CampaignRepository {
  final FirebaseFirestore _firestore;

  CampaignRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _campaignsCollection => _firestore.collection('campaigns');

 // Dans CampaignRepository - méthode getAvailableCampaigns
Future<List<CampaignModel>> getAvailableCampaigns({
  required String userId,
  required LocationPreference locationPreference,
  CampaignType? campaignType,
}) async {
  try {
    print('🔄 Loading available campaigns for user: $userId');
    print('📍 User location preference: ${locationPreference.name}');

    Query query = _campaignsCollection
        .where('isActive', isEqualTo: true)
        .where('status', isEqualTo: 'active'); // 🔥 CORRECTION: Utiliser 'active' au lieu de l'index

    if (campaignType != null) {
      query = query.where('type', isEqualTo: campaignType.index);
    }

    final snapshot = await query.get();
    
    print('📊 Found ${snapshot.docs.length} active campaigns in database');
    
    // 🔥 DEBUG: Afficher toutes les campagnes trouvées
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      print('🔍 Campaign: ${data['title']} - status: ${data['status']} - isActive: ${data['isActive']}');
    }

    final campaigns = snapshot.docs
        .map((doc) {
          try {
            final data = doc.data() as Map<String, dynamic>;
            return CampaignModel.fromMap({
              ...data,
              'id': doc.id,
            });
          } catch (e) {
            print('❌ Error processing campaign ${doc.id}: $e');
            return null;
          }
        })
        .where((campaign) => campaign != null)
        .cast<CampaignModel>()
        .toList();

    print('✅ Successfully loaded ${campaigns.length} campaigns for user');
    return campaigns;

  } catch (e) {
    print('❌ Error loading available campaigns: $e');
    throw Exception('فشل في جلب الحملات المتاحة: $e');
  }
}
  Future<List<CampaignModel>> getCampaignsByCategory({
    required String category,
    required String userId,
    required LocationPreference locationPreference,
  }) async {
    try {
      final snapshot = await _campaignsCollection
          .where('categories', arrayContains: category)
          .where('isActive', isEqualTo: true)
          .where('status', isEqualTo: CampaignStatus.active.index)
          .get();
      
      return snapshot.docs
          .map((doc) => CampaignModel.fromMap({
            ...doc.data() as Map<String, dynamic>,
            'id': doc.id,
          }))
          .toList();
    } catch (e) {
      print('❌ Error loading campaigns by category: $e');
      throw Exception('فشل في جلب الحملات حسب التصنيف: $e');
    }
  }

  Future<CampaignModel?> getCampaignById(String campaignId) async {
    try {
      print('🔄 Loading campaign: $campaignId');
      
      final doc = await _campaignsCollection.doc(campaignId).get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        print('📊 Campaign data: ${data['title']} - type: ${data['type']}');
        
        return CampaignModel.fromMap({
          ...data,
          'id': doc.id,
        });
      }
      
      print('⚠️ Campaign not found: $campaignId');
      return null;
    } catch (e) {
      print('❌ Error loading campaign: $e');
      throw Exception('فشل في جلب الحملة: $e');
    }
  }

  Future<void> recordCampaignShare({
    required String userId,
    required String campaignId,
    required String shareLink,
  }) async {
    try {
      await _firestore.collection('shares').add({
        'userId': userId,
        'campaignId': campaignId,
        'shareLink': shareLink,
        'sharedAt': DateTime.now().toIso8601String(),
        'status': 'active',
      });
      print('✅ Campaign share recorded for user: $userId');
    } catch (e) {
      print('❌ Error recording campaign share: $e');
      throw Exception('فشل في تسجيل المشاركة: $e');
    }
  }

  /// جلب الحملات الموصى بها
  Future<List<CampaignModel>> getRecommendedCampaigns({
    required String userId,
    required LocationPreference locationPreference,
    List<String>? preferredCategories,
    int limit = 5,
  }) async {
    try {
      print('🔄 Loading recommended campaigns for user: $userId');

      Query query = _campaignsCollection
          .where('isActive', isEqualTo: true)
          .where('status', isEqualTo: CampaignStatus.active.index)
          .limit(limit);

      final snapshot = await query.get();
      
      var campaigns = snapshot.docs
          .map((doc) => CampaignModel.fromMap({
            ...doc.data() as Map<String, dynamic>,
            'id': doc.id,
          }))
          .toList();

      // ترتيب الحملات بناءً على التفضيلات
      if (preferredCategories != null && preferredCategories.isNotEmpty) {
        campaigns.sort((a, b) {
          final aEarnings = a.participantEarnings;
          final bEarnings = b.participantEarnings;
          return bEarnings.compareTo(aEarnings);
        });
      }

      print('✅ Loaded ${campaigns.length} recommended campaigns');
      return campaigns;
    } catch (e) {
      print('❌ Error loading recommended campaigns: $e');
      throw Exception('فشل في جلب الحملات الموصى بها: $e');
    }
  }

  Future<List<CampaignModel>> searchCampaigns({
    required String query,
    required String userId,
    required LocationPreference locationPreference,
  }) async {
    try {
      print('🔍 Searching campaigns for: $query');

      // Note: Firestore doesn't support full-text search natively
      // This is a basic implementation
      final snapshot = await _campaignsCollection
          .where('isActive', isEqualTo: true)
          .where('status', isEqualTo: CampaignStatus.active.index)
          .get();
      
      final allCampaigns = snapshot.docs
          .map((doc) => CampaignModel.fromMap({
            ...doc.data() as Map<String, dynamic>,
            'id': doc.id,
          }))
          .toList();

      final filteredCampaigns = allCampaigns.where((campaign) =>
          campaign.title.toLowerCase().contains(query.toLowerCase()) ||
          campaign.description.toLowerCase().contains(query.toLowerCase())
      ).toList();

      print('✅ Found ${filteredCampaigns.length} campaigns for query: $query');
      return filteredCampaigns;
    } catch (e) {
      print('❌ Error searching campaigns: $e');
      throw Exception('فشل في البحث في الحملات: $e');
    }
  }

  /// 🔥 NOUVEAU : Réparer les données de campagne corrompues
  Future<void> repairCampaignData(String campaignId) async {
    try {
      print('🔧 Repairing campaign data: $campaignId');
      
      final campaign = await getCampaignById(campaignId);
      if (campaign != null) {
        // Recréer la campagne avec des données propres
        await _campaignsCollection.doc(campaignId).set(campaign.toMap(), SetOptions(merge: true));
        print('✅ Campaign data repaired: $campaignId');
      }
    } catch (e) {
      print('❌ Error repairing campaign data: $e');
      throw Exception('فشل في إصلاح بيانات الحملة: $e');
    }
  }

  /// 🔥 NOUVEAU : Obtenir les campagnes d'un annonceur
  Future<List<CampaignModel>> getAdvertiserCampaigns(String advertiserId) async {
  try {
    print('🔄 Loading campaigns for advertiser: $advertiserId');

    // 🔹 Charger sans orderBy (aucun index requis)
    final snapshot = await _campaignsCollection
        .where('advertiserId', isEqualTo: advertiserId)
        .get();

    // 🔹 Convertir puis trier localement côté client
    final campaigns = snapshot.docs
        .map((doc) => CampaignModel.fromMap({
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            }))
        .toList()
      ..sort((a, b) {
        final aDate = a.createdAt ?? DateTime(0);
        final bDate = b.createdAt ?? DateTime(0);
        return bDate.compareTo(aDate); // plus récent d'abord
      });

    print('✅ Loaded ${campaigns.length} campaigns for advertiser: $advertiserId');
    return campaigns;
  } catch (e) {
    print('❌ Error loading advertiser campaigns: $e');
    throw Exception('فشل في جلب حملات المعلن: $e');
  }
}

}