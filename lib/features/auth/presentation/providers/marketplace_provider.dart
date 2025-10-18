// === lib/features/marketplace/presentation/providers/marketplace_provider.dart ===

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reshare/data/models/campaign_model.dart';
import 'package:reshare/data/models/marketplace_campaign_model.dart';
import 'package:reshare/data/repositories/campaign_repository.dart';
import 'package:reshare/core/services/share_service.dart';
import 'package:reshare/features/auth/presentation/providers/auth_provider.dart';
import 'package:reshare/core/services/location_service.dart';
import 'package:reshare/core/services/cloud_functions_service.dart';

class MarketplaceProvider with ChangeNotifier {
  final CampaignRepository _campaignRepository = CampaignRepository();
  final ShareService _shareService = ShareService();
  final LocationService _locationService = LocationService();
  final CloudFunctionsService _cloudFunctions = CloudFunctionsService();

  AuthProvider? _authProvider;

  // État du provider
  List<MarketplaceCampaignModel> _availableCampaigns = [];
  List<MarketplaceCampaignModel> _filteredCampaigns = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<MarketplaceCampaignModel> get availableCampaigns => _filteredCampaigns;
  List<MarketplaceCampaignModel> get featuredCampaigns =>
      _availableCampaigns.where((c) => c.isFeatured).toList();
  List<MarketplaceCampaignModel> get trendingCampaigns =>
      _availableCampaigns.where((c) => c.isTrending).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Mettre à jour le provider d'authentification
  void updateAuth(AuthProvider authProvider) {
    _authProvider = authProvider;
    if (authProvider.isAuthenticated && authProvider.user != null) {
      loadMarketplaceCampaigns();
      _startRealTimeUpdates();
    }
  }

  /// Charger les campagnes de la marketplace
  // Dans MarketplaceProvider - méthode loadMarketplaceCampaigns()
  Future<void> loadMarketplaceCampaigns() async {
    if (_authProvider?.user == null) return;

    try {
      _setLoading(true);
      _clearError();

      final user = _authProvider!.user!;

      // 🔥 CORRECTION : Utiliser la nouvelle méthode spécifique marketplace
      final marketplaceCampaigns = await _campaignRepository
          .getMarketplaceCampaigns(
            userId: user.id,
            locationPreference: user.locationPreference,
          );

      print(
        '🛒 Campagnes marketplace chargées: ${marketplaceCampaigns.length}',
      );

      // Convertir en MarketplaceCampaignModel avec des données supplémentaires
      _availableCampaigns = await _enhanceCampaignsForMarketplace(
        marketplaceCampaigns,
      );
      _filteredCampaigns = _availableCampaigns;

      print(
        '🎉 Marketplace ready: ${_availableCampaigns.length} campagnes disponibles',
      );

      notifyListeners();
    } catch (e) {
      _setError('فشل في تحميل حملات السوق: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Améliorer les campagnes pour la marketplace
  Future<List<MarketplaceCampaignModel>> _enhanceCampaignsForMarketplace(
  List<CampaignModel> campaigns,
) async {
  final enhancedCampaigns = <MarketplaceCampaignModel>[];

  // ✅ Étape 1 : filtrer uniquement les campagnes de type marketplace
  final marketplaceOnly = campaigns.where((c) {
    final type = c.campaignType?.toLowerCase() ?? '';
    final isMarketplace = type == 'marketplace' || c.isMarketplaceCampaign == true;
    if (!isMarketplace) {
      print('❌ Campagne ignorée (type non marketplace): ${c.title} | type: $type');
    }
    return isMarketplace;
  }).toList();

  print('✅ Nombre de campagnes marketplace avant amélioration: ${marketplaceOnly.length}');

  // ✅ Étape 2 : améliorer uniquement ces campagnes
  for (final campaign in marketplaceOnly) {
    try {
      // Charger les données Firestore associées
      final campaignDoc = await FirebaseFirestore.instance
          .collection('campaigns')
          .doc(campaign.id)
          .get();

      final data = campaignDoc.data() as Map<String, dynamic>? ?? {};

      final campaignType = (data['campaignType'] ?? campaign.campaignType ?? '').toString();
      print('🛍️ Traitement campagne ${campaign.title} - type Firestore: $campaignType');

      // Si Firestore contient encore un mauvais type, on le skip par sécurité
      if (campaignType.toLowerCase() != 'marketplace') {
        print('⚠️ Ignorée (Firestore type != marketplace): ${campaign.title}');
        continue;
      }

      // Créer le modèle marketplace enrichi
      final marketplaceCampaign = MarketplaceCampaignModel(
        id: campaign.id,
        businessId: campaign.businessId,
        title: campaign.title,
        description: campaign.description,
        targetUrl: campaign.targetUrl,
        type: campaign.type,
        status: campaign.status,
        budget: campaign.budget,
        spent: campaign.spent,
        cpc: campaign.cpc,
        targetClicks: campaign.targetClicks,
        achievedClicks: campaign.achievedClicks,
        uniqueClicks: campaign.uniqueClicks,
        targetRegions: campaign.targetRegions,
        targetLocation: campaign.targetLocation,
        targetRadius: campaign.targetRadius,
        createdAt: campaign.createdAt,
        startDate: campaign.startDate,
        endDate: campaign.endDate,
        imageUrl: campaign.imageUrl,
        imageExtension: campaign.imageExtension,
        imagePath: campaign.imagePath,
        isActive: campaign.isActive,
        maxClicksPerUser: campaign.maxClicksPerUser,
        conversionRate: campaign.conversionRate,
        conversions: campaign.conversions,
        advertiserId: campaign.advertiserId,
        // Champs spécifiques marketplace
        isFeatured: data['isFeatured'] == true,
        rating: (data['rating'] ?? 0.0).toDouble(),
        totalShares: (data['totalShares'] ?? 0).toInt(),
        advertiserName: data['advertiserName']?.toString() ?? 'معلن',
        advertiserLogo: data['advertiserLogo']?.toString(),
        tags: data['tags'] != null ? List<String>.from(data['tags']) : [],
        featuredUntil: data['featuredUntil'] != null
            ? DateTime.tryParse(data['featuredUntil'])
            : null,
      );

      enhancedCampaigns.add(marketplaceCampaign);
      print('✅ Campagne marketplace ajoutée: ${campaign.title}');
    } catch (e) {
      print('❌ Erreur amélioration campagne ${campaign.title}: $e');

      // Fallback : création minimale si c’est bien une marketplace
      final marketplaceCampaign = MarketplaceCampaignModel(
        id: campaign.id,
        businessId: campaign.businessId,
        title: campaign.title,
        description: campaign.description,
        targetUrl: campaign.targetUrl,
        type: campaign.type,
        status: campaign.status,
        budget: campaign.budget,
        spent: campaign.spent,
        cpc: campaign.cpc,
        targetClicks: campaign.targetClicks,
        achievedClicks: campaign.achievedClicks,
        uniqueClicks: campaign.uniqueClicks,
        targetRegions: campaign.targetRegions,
        targetLocation: campaign.targetLocation,
        targetRadius: campaign.targetRadius,
        createdAt: campaign.createdAt,
        startDate: campaign.startDate,
        endDate: campaign.endDate,
        imageUrl: campaign.imageUrl,
        imageExtension: campaign.imageExtension,
        imagePath: campaign.imagePath,
        isActive: campaign.isActive,
        maxClicksPerUser: campaign.maxClicksPerUser,
        conversionRate: campaign.conversionRate,
        conversions: campaign.conversions,
        advertiserId: campaign.advertiserId,
        advertiserName: 'معلن',
        tags: [campaign.typeText],
      );
      enhancedCampaigns.add(marketplaceCampaign);
    }
  }

  print('🧩 Total campagnes marketplace finales: ${enhancedCampaigns.length}');
  return enhancedCampaigns;
}


  /// 🔥 NOUVELLE MÉTHODE : Charger uniquement les campagnes marketplace depuis Firestore
  Future<List<CampaignModel>> _loadMarketplaceCampaignsFromFirestore() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('campaigns')
          .where('campaignType', isEqualTo: 'marketplace')
          .where('isActive', isEqualTo: true)
          .where('status', isEqualTo: CampaignStatus.active.index)
          .get();

      final campaigns = snapshot.docs.map((doc) {
        final data = doc.data();
        return CampaignModel.fromMap({...data, 'id': doc.id});
      }).toList();

      print('🔥 Campagnes marketplace depuis Firestore: ${campaigns.length}');
      return campaigns;
    } catch (e) {
      print('❌ Erreur chargement marketplace depuis Firestore: $e');
      return [];
    }
  }

  /// Filtrer les campagnes
  void filterCampaigns(String filter) {
    switch (filter) {
      case 'featured':
        _filteredCampaigns = _availableCampaigns
            .where((c) => c.isFeatured)
            .toList();
        break;
      case 'trending':
        _filteredCampaigns = _availableCampaigns
            .where((c) => c.isTrending)
            .toList();
        break;
      case 'new':
        _filteredCampaigns = _availableCampaigns.where((c) => c.isNew).toList();
        break;
      case 'all':
      default:
        _filteredCampaigns = _availableCampaigns;
        break;
    }
    notifyListeners();
  }

  /// Trier les campagnes
  void sortCampaigns(String sortBy) {
    switch (sortBy) {
      case 'rating':
        _filteredCampaigns.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'shares':
        _filteredCampaigns.sort(
          (a, b) => b.totalShares.compareTo(a.totalShares),
        );
        break;
      case 'earnings':
        _filteredCampaigns.sort(
          (a, b) => b.participantEarnings.compareTo(a.participantEarnings),
        );
        break;
      case 'newest':
        _filteredCampaigns.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'featured':
      default:
        _filteredCampaigns.sort((a, b) {
          if (a.isFeatured && !b.isFeatured) return -1;
          if (!a.isFeatured && b.isFeatured) return 1;
          return b.createdAt.compareTo(a.createdAt);
        });
        break;
    }
    notifyListeners();
  }

  /// Rechercher dans les campagnes
  void searchMarketplaceCampaigns(String query) {
    if (query.isEmpty) {
      _filteredCampaigns = _availableCampaigns;
    } else {
      _filteredCampaigns = _availableCampaigns.where((campaign) {
        return campaign.title.toLowerCase().contains(query.toLowerCase()) ||
            campaign.description.toLowerCase().contains(query.toLowerCase()) ||
            campaign.advertiserName.toLowerCase().contains(
              query.toLowerCase(),
            ) ||
            campaign.tags.any(
              (tag) => tag.toLowerCase().contains(query.toLowerCase()),
            );
      }).toList();
    }
    notifyListeners();
  }

  /// Partager une campagne de la marketplace
  Future<void> shareMarketplaceCampaign(
    MarketplaceCampaignModel marketplaceCampaign,
  ) async {
    if (_authProvider?.user == null) return;

    try {
      _setLoading(true);
      _clearError();

      final user = _authProvider!.user!;

      // Convertir MarketplaceCampaignModel en CampaignModel pour la compatibilité
      final campaign = CampaignModel(
        id: marketplaceCampaign.id,
        businessId: marketplaceCampaign.businessId,
        title: marketplaceCampaign.title,
        description: marketplaceCampaign.description,
        targetUrl: marketplaceCampaign.targetUrl,
        type: marketplaceCampaign.type,
        status: marketplaceCampaign.status,
        budget: marketplaceCampaign.budget,
        spent: marketplaceCampaign.spent,
        cpc: marketplaceCampaign.cpc,
        targetClicks: marketplaceCampaign.targetClicks,
        achievedClicks: marketplaceCampaign.achievedClicks,
        uniqueClicks: marketplaceCampaign.uniqueClicks,
        targetRegions: marketplaceCampaign.targetRegions,
        targetLocation: marketplaceCampaign.targetLocation,
        targetRadius: marketplaceCampaign.targetRadius,
        createdAt: marketplaceCampaign.createdAt,
        startDate: marketplaceCampaign.startDate,
        endDate: marketplaceCampaign.endDate,
        imageUrl: marketplaceCampaign.imageUrl,
        imageExtension: marketplaceCampaign.imageExtension,
        imagePath: marketplaceCampaign.imagePath,
        isActive: marketplaceCampaign.isActive,
        maxClicksPerUser: marketplaceCampaign.maxClicksPerUser,
        conversionRate: marketplaceCampaign.conversionRate,
        conversions: marketplaceCampaign.conversions,
        advertiserId: marketplaceCampaign.advertiserId,
      );

      // Vérifier l'éligibilité de partage
      final canShare = await _canUserShareCampaign(user.id, campaign.id);
      if (!canShare) {
        _setError('لقد وصلت إلى الحد الأقصى للمشاركات في هذه الحملة');
        return;
      }

      // Obtenir la localisation de l'utilisateur
      final location = await _locationService.getCurrentLocation();
      final locationString = location != null
          ? '${location.latitude},${location.longitude}'
          : 'unknown';

      // Appeler Cloud Function pour partager la campagne
      final result = await _cloudFunctions.callFunction(
        'generateTrackingLink',
        parameters: {
          'campaignId': campaign.id,
          'participantId': user.id,
          'location': locationString,
        },
      );

      if (result['success'] == true) {
        final shareLink = result['trackingLink'];
        final shareId = result['shareId'];

        // Enregistrer le partage dans la base de données
        await _campaignRepository.recordCampaignShare(
          userId: user.id,
          campaignId: campaign.id,
          shareLink: shareLink,
          location: locationString,
        );

        // Partager le lien avec le message personnalisé pour la marketplace
        final shared = await _shareService.shareCampaign(
          campaign: campaign,
          shareLink: shareLink,
          customMessage:
              '''
🚀 حملة رائعة في سوق ReShare!

${marketplaceCampaign.title}

${marketplaceCampaign.description}

🎯 شارك الآن واربح ${marketplaceCampaign.participantEarnings.toStringAsFixed(3)} دينار لكل نقرة!

⭐ التقييم: ${marketplaceCampaign.ratingText}
📤 المشاركات: ${marketplaceCampaign.shareCountText}

🔗 ${_shortenUrl(shareLink)}

#ReShare #سوق_الحملات #${marketplaceCampaign.advertiserName}
''',
        );

        if (shared) {
          // Envoyer une notification de succès
          await _cloudFunctions.callFunction(
            'sendUserNotification',
            parameters: {
              'userId': user.id,
              'title': 'تمت المشاركة بنجاح! 🎯',
              'body': 'حملة "${campaign.title}" جاهزة للمشاركة',
              'type': 'campaign_shared',
              'data': {'campaignId': campaign.id, 'shareId': shareId},
            },
          );

          // Incrémenter le compteur de partages dans Firestore
          await _incrementShareCount(campaign.id);

          // Actualiser les données pour mettre à jour les statistiques
          await loadMarketplaceCampaigns();

          // Afficher un message de succès
          _showSuccessMessage('تم مشاركة الحملة بنجاح!');
        }
      } else {
        throw Exception(result['error'] ?? 'فشل في مشاركة الحملة');
      }
    } catch (e) {
      _setError('فشل في مشاركة الحملة: $e');
      _showErrorMessage('فشل في مشاركة الحملة: $e');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Vérifier si l'utilisateur peut partager la campagne
  Future<bool> _canUserShareCampaign(String userId, String campaignId) async {
    try {
      final sharesSnapshot = await FirebaseFirestore.instance
          .collection('campaignShares')
          .where('userId', isEqualTo: userId)
          .where('campaignId', isEqualTo: campaignId)
          .get();

      // Vérifier aussi les limites de la campagne
      final campaignDoc = await FirebaseFirestore.instance
          .collection('campaigns')
          .doc(campaignId)
          .get();

      final campaignData = campaignDoc.data() as Map<String, dynamic>? ?? {};
      final maxSharesPerUser = campaignData['maxSharesPerUser'] ?? 10;

      return sharesSnapshot.docs.length < maxSharesPerUser;
    } catch (e) {
      print('Error checking share eligibility: $e');
      return true; // En cas d'erreur, permettre le partage
    }
  }

  /// Incrémenter le compteur de partages
  Future<void> _incrementShareCount(String campaignId) async {
    try {
      await FirebaseFirestore.instance
          .collection('campaigns')
          .doc(campaignId)
          .update({
            'totalShares': FieldValue.increment(1),
            'lastSharedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      print('Error incrementing share count: $e');
    }
  }

  /// Obtenir les détails d'une campagne spécifique
  Future<MarketplaceCampaignModel?> getCampaignDetails(
    String campaignId,
  ) async {
    try {
      final campaignDoc = await FirebaseFirestore.instance
          .collection('campaigns')
          .doc(campaignId)
          .get();

      if (!campaignDoc.exists) return null;

      final campaignData = campaignDoc.data() as Map<String, dynamic>;

      // 🔥 CORRECTION : Vérifier que c'est une campagne marketplace
      final campaignType = campaignData['campaignType'] ?? 'ads';
      if (campaignType != 'marketplace') {
        print('⚠️ Campagne non marketplace ignorée: $campaignId');
        return null;
      }

      final campaign = CampaignModel.fromMap(campaignData);

      // Convertir en MarketplaceCampaignModel
      return MarketplaceCampaignModel(
        id: campaign.id,
        businessId: campaign.businessId,
        title: campaign.title,
        description: campaign.description,
        targetUrl: campaign.targetUrl,
        type: campaign.type,
        status: campaign.status,
        budget: campaign.budget,
        spent: campaign.spent,
        cpc: campaign.cpc,
        targetClicks: campaign.targetClicks,
        achievedClicks: campaign.achievedClicks,
        uniqueClicks: campaign.uniqueClicks,
        targetRegions: campaign.targetRegions,
        targetLocation: campaign.targetLocation,
        targetRadius: campaign.targetRadius,
        createdAt: campaign.createdAt,
        startDate: campaign.startDate,
        endDate: campaign.endDate,
        imageUrl: campaign.imageUrl,
        imageExtension: campaign.imageExtension,
        imagePath: campaign.imagePath,
        isActive: campaign.isActive,
        maxClicksPerUser: campaign.maxClicksPerUser,
        conversionRate: campaign.conversionRate,
        conversions: campaign.conversions,
        advertiserId: campaign.advertiserId,
        isFeatured: campaignData['isFeatured'] == true,
        rating: (campaignData['rating'] ?? 0.0).toDouble(),
        totalShares: (campaignData['totalShares'] ?? 0).toInt(),
        advertiserName: campaignData['advertiserName']?.toString() ?? 'معلن',
        advertiserLogo: campaignData['advertiserLogo']?.toString(),
        tags: campaignData['tags'] != null
            ? List<String>.from(campaignData['tags'])
            : [],
        featuredUntil: campaignData['featuredUntil'] != null
            ? DateTime.parse(campaignData['featuredUntil'])
            : null,
      );
    } catch (e) {
      print('Error getting campaign details: $e');
      return null;
    }
  }

  /// Actualiser les campagnes
  Future<void> refreshMarketplaceCampaigns() async {
    await loadMarketplaceCampaigns();
  }

  /// Démarrer les mises à jour en temps réel
  void _startRealTimeUpdates() {
    final user = _authProvider!.user;
    if (user == null) return;

    // 🔥 CORRECTION : Filtrer uniquement les campagnes marketplace
    FirebaseFirestore.instance
        .collection('campaigns')
        .where('campaignType', isEqualTo: 'marketplace')
        .where('isActive', isEqualTo: true)
        .where('status', isEqualTo: CampaignStatus.active.index)
        .snapshots()
        .listen((snapshot) async {
          try {
            final campaigns = snapshot.docs
                .map(
                  (doc) =>
                      CampaignModel.fromMap(doc.data() as Map<String, dynamic>),
                )
                .toList();

            _availableCampaigns = await _enhanceCampaignsForMarketplace(
              campaigns,
            );
            _filteredCampaigns = _availableCampaigns;

            notifyListeners();
          } catch (e) {
            print('Error in real-time updates: $e');
          }
        });
  }

  /// Afficher un message de succès
  void _showSuccessMessage(String message) {
    // Cette méthode peut être utilisée pour afficher des SnackBars
    // Vous pouvez l'adapter selon votre système de notification
    print('Success: $message');
  }

  /// Afficher un message d'erreur
  void _showErrorMessage(String message) {
    // Cette méthode peut être utilisée pour afficher des SnackBars
    // Vous pouvez l'adapter selon votre système de notification
    print('Error: $message');
  }

  String _shortenUrl(String url) {
    // Implémenter le raccourcissement d'URL si nécessaire
    return url;
  }

  // Méthodes helpers pour la gestion de l'état
  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading) _clearError();
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  @override
  void dispose() {
    // Nettoyer les ressources si nécessaire
    super.dispose();
  }
}
