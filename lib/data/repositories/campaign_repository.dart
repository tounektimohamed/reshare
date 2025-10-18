// === lib/data/repositories/campaign_repository.dart ===

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reshare/data/models/user_model.dart';
import '../models/campaign_model.dart';

class CampaignRepository {
  final FirebaseFirestore _firestore;

  CampaignRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _campaignsCollection =>
      _firestore.collection('campaigns');

  // 🔥 CORRECTION : Méthode pour obtenir les campagnes disponibles avec filtre campaignType
  Future<List<CampaignModel>> getAvailableCampaigns({
    required String userId,
    required LocationPreference locationPreference,
    CampaignType? campaignType,
    String?
    campaignTypeFilter, // 🔥 NOUVEAU : Pour filtrer par 'ads' ou 'marketplace'
  }) async {
    try {
      print('🔄 Loading available campaigns for user: $userId');
      print('📍 User location preference: ${locationPreference.name}');
      if (campaignTypeFilter != null) {
        print('🎯 Filtering by campaign type: $campaignTypeFilter');
      }

      Query query = _campaignsCollection
          .where('isActive', isEqualTo: true)
          .where('status', isEqualTo: CampaignStatus.active.index);

      // 🔥 CORRECTION : Filtrer par type de campagne (ads/marketplace)
      if (campaignTypeFilter != null) {
        query = query.where('campaignType', isEqualTo: campaignTypeFilter);
        print('🔍 Applied campaignType filter: $campaignTypeFilter');
      }

      // Filtrer par type de campagne (open/regional/precise)
      if (campaignType != null) {
        query = query.where('type', isEqualTo: campaignType.index);
        print('🔍 Applied campaign type filter: ${campaignType.index}');
      }

      final snapshot = await query.get();

      print('📊 Found ${snapshot.docs.length} active campaigns in database');

      // 🔥 DEBUG: Afficher toutes les campagnes trouvées avec leurs types
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final campaignTypeValue = data['campaignType'] ?? 'not_set';
        print(
          '🔍 Campaign: ${data['title']} - campaignType: $campaignTypeValue - status: ${data['status']}',
        );
      }

      final campaigns = snapshot.docs
          .map((doc) {
            try {
              final data = doc.data() as Map<String, dynamic>;
              return CampaignModel.fromMap({...data, 'id': doc.id});
            } catch (e) {
              print('❌ Error processing campaign ${doc.id}: $e');
              return null;
            }
          })
          .where((campaign) => campaign != null)
          .cast<CampaignModel>()
          .toList();

      print('✅ Successfully loaded ${campaigns.length} campaigns for user');

      // 🔥 DEBUG: Afficher le décompte par type
      final marketplaceCount = campaigns
          .where((c) => c.campaignType == 'marketplace')
          .length;
      final adsCount = campaigns.where((c) => c.campaignType == 'ads').length;
      final notSetCount = campaigns
          .where(
            (c) => c.campaignType == 'ads' || c.campaignType != 'marketplace',
          )
          .length;

      print('📊 Campaigns breakdown:');
      print('   🛒 Marketplace: $marketplaceCount');
      print('   📢 Ads: $adsCount');
      print('   ❓ Not set: $notSetCount');

      return campaigns;
    } catch (e) {
      print('❌ Error loading available campaigns: $e');
      throw Exception('فشل في جلب الحملات المتاحة: $e');
    }
  }

  // 🔥 NOUVELLE MÉTHODE : Obtenir uniquement les campagnes marketplace
// Dans CampaignRepository - version corrigée avec statut numérique
Future<List<CampaignModel>> getMarketplaceCampaigns({
  required String userId,
  required LocationPreference locationPreference,
}) async {
  try {
    print('🛒 Loading MARKETPLACE campaigns for user: $userId');

    // 🔥 CORRECTION: Utiliser le statut numérique (2 = CampaignStatus.active.index)
    Query query = _campaignsCollection
        .where('isActive', isEqualTo: true)
        .where('status', isEqualTo: 2) // 🔥 2 au lieu de 'active'
        .where('campaignType', isEqualTo: 'marketplace');

    final snapshot = await query.get();

    print('📊 Found ${snapshot.docs.length} marketplace campaigns in database');

    // Afficher le détail de chaque campagne marketplace trouvée
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      print('''
🛒 MARKETPLACE Campaign Found:
   📝 Title: ${data['title']}
   🔑 ID: ${doc.id}
   🏷️ campaignType: ${data['campaignType']}
   📊 Status: ${data['status']}
   ✅ Active: ${data['isActive']}
   💰 Budget: ${data['budget']}
      ''');
    }

    final marketplaceCampaigns = snapshot.docs
        .map((doc) {
          try {
            final data = doc.data() as Map<String, dynamic>;
            return CampaignModel.fromMap({...data, 'id': doc.id});
          } catch (e) {
            print('❌ Error processing marketplace campaign ${doc.id}: $e');
            return null;
          }
        })
        .where((campaign) => campaign != null)
        .cast<CampaignModel>()
        .toList();

    print('✅ Successfully loaded ${marketplaceCampaigns.length} MARKETPLACE campaigns');
    return marketplaceCampaigns;
  } catch (e) {
    print('❌ Error loading marketplace campaigns: $e');

    // 🔥 FALLBACK: Retourner une liste vide en cas d'erreur
    return [];
  }
}
  // 🔥 NOUVELLE MÉTHODE : Obtenir uniquement les campagnes ads
  Future<List<CampaignModel>> getAdsCampaigns({
    required String userId,
    required LocationPreference locationPreference,
  }) async {
    try {
      print('📢 Loading ADS campaigns for user: $userId');

      Query query = _campaignsCollection
          .where('isActive', isEqualTo: true)
          .where('status', isEqualTo: 'active')
          .where('campaignType', isEqualTo: 'ads'); // 🔥 Filtre spécifique

      final snapshot = await query.get();

      print('📊 Found ${snapshot.docs.length} ads campaigns in database');

      final campaigns = snapshot.docs
          .map((doc) {
            try {
              final data = doc.data() as Map<String, dynamic>;
              return CampaignModel.fromMap({...data, 'id': doc.id});
            } catch (e) {
              print('❌ Error processing ads campaign ${doc.id}: $e');
              return null;
            }
          })
          .where((campaign) => campaign != null)
          .cast<CampaignModel>()
          .toList();

      print('✅ Successfully loaded ${campaigns.length} ADS campaigns');
      return campaigns;
    } catch (e) {
      print('❌ Error loading ads campaigns: $e');
      throw Exception('فشل في جلب حملات الإعلانات: $e');
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
          .where('status', isEqualTo: 'active')
          .get();

      return snapshot.docs
          .map(
            (doc) => CampaignModel.fromMap({
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            }),
          )
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
        final campaignType = data['campaignType'] ?? 'not_set';
        print(
          '📊 Campaign data: ${data['title']} - campaignType: $campaignType',
        );

        return CampaignModel.fromMap({...data, 'id': doc.id});
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
    required String location,
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
          .where('status', isEqualTo: 'active')
          .limit(limit);

      final snapshot = await query.get();

      var campaigns = snapshot.docs
          .map(
            (doc) => CampaignModel.fromMap({
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            }),
          )
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
          .where('status', isEqualTo: 'active')
          .get();

      final allCampaigns = snapshot.docs
          .map(
            (doc) => CampaignModel.fromMap({
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            }),
          )
          .toList();

      final filteredCampaigns = allCampaigns
          .where(
            (campaign) =>
                campaign.title.toLowerCase().contains(query.toLowerCase()) ||
                campaign.description.toLowerCase().contains(
                  query.toLowerCase(),
                ),
          )
          .toList();

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
        await _campaignsCollection
            .doc(campaignId)
            .set(campaign.toMap(), SetOptions(merge: true));
        print('✅ Campaign data repaired: $campaignId');
      }
    } catch (e) {
      print('❌ Error repairing campaign data: $e');
      throw Exception('فشل في إصلاح بيانات الحملة: $e');
    }
  }

  // Dans CampaignRepository - méthode pour corriger les campagnes sans campaignType
  Future<void> fixMissingCampaignTypes() async {
    try {
      print('🔧 Correction des campagnes sans campaignType...');

      final snapshot = await _campaignsCollection
          .where('isActive', isEqualTo: true)
          .get();

      int fixedCount = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final id = doc.id;

        // Vérifier si campaignType est manquant
        if (!data.containsKey('campaignType') || data['campaignType'] == null) {
          // Déterminer le type basé sur d'autres champs ou utiliser 'ads' par défaut
          final campaignType = 'ads'; // Par défaut, considérer comme ads

          await _campaignsCollection.doc(id).update({
            'campaignType': campaignType,
            'updatedAt': DateTime.now().toIso8601String(),
          });

          print('✅ Campagne corrigée: $id -> $campaignType');
          fixedCount++;
        }
      }

      print('🎯 Correction terminée: $fixedCount campagnes mises à jour');
    } catch (e) {
      print('❌ Erreur correction campaignType: $e');
    }
  }

  // Méthode pour convertir une campagne en marketplace
  Future<void> convertCampaignToMarketplace(String campaignId) async {
    try {
      await _campaignsCollection.doc(campaignId).update({
        'campaignType': 'marketplace',
        'isFeatured': true, // Optionnel: mettre en vedette
        'updatedAt': DateTime.now().toIso8601String(),
      });

      print('✅ Campagne $campaignId convertie en marketplace');
    } catch (e) {
      print('❌ Erreur conversion marketplace: $e');
    }
  }

  /// 🔥 NOUVEAU : Obtenir les campagnes d'un annonceur
  Future<List<CampaignModel>> getAdvertiserCampaigns(
    String advertiserId,
  ) async {
    try {
      print('🔄 Loading campaigns for advertiser: $advertiserId');

      // 🔹 Charger sans orderBy (aucun index requis)
      final snapshot = await _campaignsCollection
          .where('advertiserId', isEqualTo: advertiserId)
          .get();

      // 🔹 Convertir puis trier localement côté client
      final campaigns =
          snapshot.docs
              .map(
                (doc) => CampaignModel.fromMap({
                  ...doc.data() as Map<String, dynamic>,
                  'id': doc.id,
                }),
              )
              .toList()
            ..sort((a, b) {
              final aDate = a.createdAt ?? DateTime(0);
              final bDate = b.createdAt ?? DateTime(0);
              return bDate.compareTo(aDate); // plus récent d'abord
            });

      print(
        '✅ Loaded ${campaigns.length} campaigns for advertiser: $advertiserId',
      );
      return campaigns;
    } catch (e) {
      print('❌ Error loading advertiser campaigns: $e');
      throw Exception('فشل في جلب حملات المعلن: $e');
    }
  }
}
