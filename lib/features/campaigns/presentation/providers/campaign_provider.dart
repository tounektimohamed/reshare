import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reshare/data/models/user_model.dart';
import 'package:reshare/data/models/campaign_model.dart';
import 'package:reshare/data/models/click_model.dart';
import 'package:reshare/data/repositories/campaign_repository.dart';
import 'package:reshare/data/repositories/click_repository.dart';
import 'package:reshare/core/services/cloud_functions_service.dart';
import 'package:reshare/core/services/location_service.dart';
import 'package:reshare/core/services/share_service.dart';
import 'package:reshare/features/auth/presentation/providers/auth_provider.dart';

class CampaignProvider with ChangeNotifier {
  final CampaignRepository _campaignRepository = CampaignRepository();
  final ClickRepository _clickRepository = ClickRepository();
  final CloudFunctionsService _cloudFunctions = CloudFunctionsService();
  final LocationService _locationService = LocationService();
  final ShareService _shareService = ShareService();

  // 🔥 CORRECTION : Initialiser FirebaseFirestore correctement
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  AuthProvider? _authProvider;

  // État du provider
  List<CampaignModel> _campaigns = [];
  List<CampaignModel> _filteredCampaigns = [];
  CampaignModel? _selectedCampaign;
  List<ClickModel> _campaignClicks = [];
  List<CampaignModel> _userCampaigns = [];
  bool _isLoading = false;
  String? _error;
  CampaignFilter _filter = CampaignFilter();
  CampaignSort _sort = CampaignSort.newest;

  // Getters
  List<CampaignModel> get campaigns => _filteredCampaigns;
  List<CampaignModel> get userCampaigns => _userCampaigns;
  CampaignModel? get selectedCampaign => _selectedCampaign;
  List<ClickModel> get campaignClicks => _campaignClicks;
  bool get isLoading => _isLoading;
  String? get error => _error;
  CampaignFilter get filter => _filter;
  CampaignSort get sort => _sort;

  /// Mettre à jour le provider d'authentification
  void updateAuth(AuthProvider authProvider) {
    _authProvider = authProvider;
    if (authProvider.isAuthenticated) {
      loadCampaigns();
      _loadUserCampaigns();
    }
  }
/// 🔥 Charger uniquement les campagnes de type "ads"
Future<void> loadAdsCampaigns() async {
  if (_authProvider?.user == null) return;

  try {
    _setLoading(true);
    _clearError();

    // 🔹 Charger toutes les campagnes depuis Firestore
    final snapshot = await _firestore.collection('campaigns').get();

    _campaigns = snapshot.docs
        .map((doc) {
          final data = doc.data();
          final type = (data['campaignType'] ?? data['type'] ?? '')
              .toString()
              .toLowerCase()
              .trim();
          final status = data['status'];
          final isActive = data['isActive'] == true;

          // ✅ Garder uniquement les campagnes ADS actives
          if (type == 'ads' && isActive && (status == 2 || status == 'active')) {
            return CampaignModel.fromMap({...data, 'id': doc.id});
          }
          return null;
        })
        .whereType<CampaignModel>() // Supprimer les nulls
        .toList();

    print('✅ Campagnes ADS trouvées: ${_campaigns.length}');
    _applyFiltersAndSort();
  } catch (e) {
    _setError('فشل في تحميل حملات ADS: $e');
  } finally {
    _setLoading(false);
    notifyListeners();
  }
}

  /// Charger les campagnes disponibles
  Future<void> loadCampaigns({CampaignType? type}) async {
    if (_authProvider?.user == null) return;

    try {
      _setLoading(true);
      _clearError();

      final user = _authProvider!.user!;

      _campaigns = await _campaignRepository.getAvailableCampaigns(
        userId: user.id,
        locationPreference: user.locationPreference,
        campaignType: type,
      );

      _applyFiltersAndSort();
    } catch (e) {
      _setError('فشل في تحميل الحملات: $e');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Charger les campagnes de l'utilisateur
  Future<void> _loadUserCampaigns() async {
    try {
      final user = _authProvider!.user!;

      if (user.userType == UserType.business ||
          user.userType == UserType.admin) {
        // 🔥 CORRECTION : Utiliser _firestore au lieu de FirebaseFirestore.instance
        final snapshot = await _firestore
            .collection('campaigns')
            .where('advertiserId', isEqualTo: user.id)
            .get();

        _userCampaigns = snapshot.docs.map((doc) {
          final data = doc.data();
          return CampaignModel.fromMap({...data, 'id': doc.id});
        }).toList();

        // 🧠 Tri local côté client
        _userCampaigns.sort((a, b) {
          final aDate = a.createdAt ?? DateTime(0);
          final bDate = b.createdAt ?? DateTime(0);
          return bDate.compareTo(aDate); // Tri décroissant
        });
      }
    } catch (e) {
      print('فشل في تحميل حملات المستخدم: $e');
    }
  }

  /// 🔥 CORRECTION : Méthode pour créer une campagne avec le modèle complet
  Future<void> createCampaignWithModel(CampaignModel campaign) async {
    try {
      _setLoading(true);
      _clearError();

      final docRef = _firestore.collection('campaigns').doc(campaign.id);
      
      // Utiliser toCreateMap() qui inclut tous les champs requis
      await docRef.set(campaign.toCreateMap());
      
      print('✅ Campagne créée avec succès: ${campaign.id}');
      print('✅ Type de campagne: ${campaign.campaignType}');
      print('✅ Frais marketplace: ${campaign.marketplaceFee}');
      print('✅ Déduction totale: ${campaign.totalDeduction}');
      print('✅ Budget: ${campaign.budget}');
      print('✅ CPC: ${campaign.cpc}');
      print('✅ Clicks cibles: ${campaign.targetClicks}');
      
      // Mettre à jour le solde du business
      await _updateBusinessBalance({
        'businessId': campaign.businessId,
        'totalDeduction': campaign.totalDeduction,
        'campaignType': campaign.campaignType,
      });

      // Ajouter à la liste locale
      _userCampaigns.add(campaign);
      _userCampaigns.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    } catch (e) {
      print('❌ Erreur création campagne: $e');
      _setError('فشل في إنشاء الحملة: $e');
      throw Exception('Erreur création campagne: $e');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// 🔥 CORRECTION : Méthode pour mettre à jour le solde
  Future<void> _updateBusinessBalance(Map<String, dynamic> data) async {
    try {
      final businessId = data['businessId'];
      final totalDeduction = data['totalDeduction'] ?? 0.0;
      final campaignType = data['campaignType'] ?? 'ads';
      
      if (businessId == null || businessId.isEmpty) {
        print('⚠️ Business ID manquant pour la mise à jour du solde');
        return;
      }

      // Mettre à jour le solde du business dans Firestore
      await _firestore.collection('businesses').doc(businessId).update({
        'balance': FieldValue.increment(-totalDeduction),
        'lastCampaignDeduction': totalDeduction,
        'lastCampaignType': campaignType,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      
      print('💰 Solde mis à jour: -$totalDeduction pour $businessId');
      
    } catch (e) {
      print('❌ Erreur mise à jour solde: $e');
      // Ne pas throw pour ne pas bloquer la création de campagne
    }
  }

  /// Créer une campagne directement (sans paiement)
  Future<void> createCampaignDirect(Map<String, dynamic> campaignData) async {
    if (_authProvider?.user == null) {
      _setError('يجب تسجيل الدخول');
      return;
    }

    try {
      _setLoading(true);
      _clearError();

      final result = await _cloudFunctions.callFunction(
        'createCampaignDirect',
        parameters: campaignData,
      );

      if (result['success'] == true) {
        // Recharger les campagnes de l'utilisateur
        await _loadUserCampaigns();

        // Recharger les campagnes disponibles
        await loadCampaigns();

        // Envoyer une notification de succès
        await _cloudFunctions.callFunction(
          'sendUserNotification',
          parameters: {
            'userId': _authProvider!.user!.id,
            'title': 'تم إنشاء الحملة بنجاح! 🚀',
            'body': 'حملتك "${campaignData['title']}" مفعلة وجاهزة للمشاركة',
            'type': 'campaign_created',
          },
        );
      } else {
        throw Exception(result['error'] ?? 'فشل في إنشاء الحملة');
      }
    } catch (error) {
      _setError('فشل في إنشاء الحملة: $error');
      rethrow;
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Créer des campagnes de test
  Future<void> createTestCampaigns(int count) async {
    try {
      _setLoading(true);
      _clearError();

      final result = await _cloudFunctions.callFunction(
        'createTestCampaigns',
        parameters: {'count': count},
      );

      if (result['success'] == true) {
        await _loadUserCampaigns();
        await loadCampaigns();
      } else {
        throw Exception(result['error'] ?? 'فشل في إنشاء الحملات التجريبية');
      }
    } catch (error) {
      _setError('فشل في إنشاء الحملات التجريبية: $error');
      rethrow;
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Charger une campagne spécifique
  Future<void> loadCampaign(String campaignId) async {
    try {
      _setLoading(true);
      _clearError();

      _selectedCampaign = await _campaignRepository.getCampaignById(campaignId);

      if (_selectedCampaign != null) {
        await _loadCampaignClicks(campaignId);
        await _loadCampaignAnalytics(campaignId);
      }
    } catch (e) {
      _setError('فشل في تحميل الحملة: $e');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Charger les clics de la campagne
  Future<void> _loadCampaignClicks(String campaignId) async {
    try {
      _campaignClicks = await _clickRepository.getCampaignClicks(campaignId);
    } catch (e) {
      print('فشل في تحميل نقرات الحملة: $e');
    }
  }

  /// Charger les analyses de la campagne
  Future<void> _loadCampaignAnalytics(String campaignId) async {
    try {
      final result = await _cloudFunctions.callFunction(
        'getCampaignAnalytics',
        parameters: {'campaignId': campaignId},
      );

      if (result['success'] == true && _selectedCampaign != null) {
        final analytics = result['analytics'];
        // Mettre à jour les données de la campagne avec les analytics
        // Cette logique dépend de la structure de votre modèle
      }
    } catch (e) {
      print('فشل في تحميل تحليلات الحملة: $e');
    }
  }

  /// Partager une campagne
  Future<void> shareCampaign(CampaignModel campaign) async {
    if (_authProvider?.user == null) return;

    try {
      _setLoading(true);
      _clearError();

      final user = _authProvider!.user!;

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
        parameters: {'campaignId': campaign.id, 'participantId': user.id},
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

        // Partager le lien
        final shared = await _shareService.shareCampaign(
          campaign: campaign,
          shareLink: shareLink,
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
        }
      } else {
        throw Exception(result['error'] ?? 'فشل في مشاركة الحملة');
      }
    } catch (e) {
      _setError('فشل في مشاركة الحملة: $e');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Vérifier si l'utilisateur peut partager la campagne
  Future<bool> _canUserShareCampaign(String userId, String campaignId) async {
    try {
      final userClicks = await _clickRepository.getUserClicksForCampaign(
        userId: userId,
        campaignId: campaignId,
      );

      final campaign = _campaigns.firstWhere(
        (c) => c.id == campaignId,
        orElse: () => _selectedCampaign!,
      );

      return userClicks.length < campaign.maxClicksPerUser;
    } catch (e) {
      return false;
    }
  }

  /// Traiter un clic sur une campagne
  Future<void> processClick({
    required String trackingId,
    required String ipAddress,
    required String userAgent,
    required String deviceHash,
  }) async {
    try {
      final location = await _locationService.getCurrentLocation();
      final locationData = location?.toMap();

      // Appeler Cloud Function pour traiter le clic
      final result = await _cloudFunctions.callFunction(
        'clickHandler',
        parameters: {
          'trackingId': trackingId,
          'ipAddress': ipAddress,
          'userAgent': userAgent,
          'deviceHash': deviceHash,
          'locationData': locationData,
        },
      );

      if (result['success'] == true && _authProvider?.user != null) {
        final earnings = result['earnings'] ?? 0.0;

        if (earnings > 0) {
          // Mettre à jour le solde de l'utilisateur
          await _cloudFunctions.callFunction(
            'updateUserBalance',
            parameters: {
              'userId': _authProvider!.user!.id,
              'amount': earnings,
              'transactionType': 'click_earning',
              'description': 'أرباح من نقرة صالحة',
            },
          );

          // Envoyer une notification de gains
          await _cloudFunctions.callFunction(
            'sendUserNotification',
            parameters: {
              'userId': _authProvider!.user!.id,
              'title': 'أرباح جديدة! 💰',
              'body':
                  'لقد ربحت ${earnings.toStringAsFixed(3)} دينار من مشاركاتك',
              'type': 'earning_received',
            },
          );
        }
      }
    } catch (e) {
      print('فشل في معالجة النقرة: $e');
    }
  }

  /// Filtrer les campagnes
  Future<void> filterCampaigns(CampaignFilter newFilter) async {
    try {
      _setLoading(true);
      _filter = newFilter;
      _applyFiltersAndSort();
    } catch (e) {
      _setError('فشل في تصفية الحملات: $e');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Trier les campagnes
  Future<void> sortCampaigns(CampaignSort newSort) async {
    try {
      _setLoading(true);
      _sort = newSort;
      _applyFiltersAndSort();
    } catch (e) {
      _setError('فشل في ترتيب الحملات: $e');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Appliquer les filtres et le tri
  void _applyFiltersAndSort() {
    List<CampaignModel> filtered = List.from(_campaigns);

    // Appliquer les filtres
    if (_filter.type != null) {
      filtered = filtered
          .where((campaign) => campaign.type == _filter.type)
          .toList();
    }

    if (_filter.minEarnings != null) {
      filtered = filtered
          .where(
            (campaign) => campaign.participantEarnings >= _filter.minEarnings!,
          )
          .toList();
    }

    if (_filter.maxEarnings != null) {
      filtered = filtered
          .where(
            (campaign) => campaign.participantEarnings <= _filter.maxEarnings!,
          )
          .toList();
    }

    if (_filter.activeOnly) {
      filtered = filtered.where((campaign) => campaign.isActive).toList();
    }

    // Appliquer le tri
    switch (_sort) {
      case CampaignSort.newest:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case CampaignSort.earningsHigh:
        filtered.sort(
          (a, b) => b.participantEarnings.compareTo(a.participantEarnings),
        );
        break;
      case CampaignSort.earningsLow:
        filtered.sort(
          (a, b) => a.participantEarnings.compareTo(b.participantEarnings),
        );
        break;
      case CampaignSort.remainingHigh:
        filtered.sort((a, b) => b.remainingClicks.compareTo(a.remainingClicks));
        break;
    }

    _filteredCampaigns = filtered;
  }

  /// Rechercher dans les campagnes
  Future<void> searchCampaigns(String query) async {
    try {
      _setLoading(true);

      if (_authProvider?.user == null) return;

      final user = _authProvider!.user!;

      if (query.isEmpty) {
        await loadCampaigns();
      } else {
        _campaigns = await _campaignRepository.searchCampaigns(
          query: query,
          userId: user.id,
          locationPreference: user.locationPreference,
        );
        _applyFiltersAndSort();
      }
    } catch (e) {
      _setError('فشل في البحث في الحملات: $e');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Obtenir les campagnes recommandées
  Future<List<CampaignModel>> getRecommendedCampaigns() async {
    if (_authProvider?.user == null) return [];

    try {
      final user = _authProvider!.user!;

      return await _campaignRepository.getRecommendedCampaigns(
        userId: user.id,
        locationPreference: user.locationPreference,
        preferredCategories: user.preferredCategories,
      );
    } catch (e) {
      print('فشل في الحصول على الحملات الموصى بها: $e');
      return [];
    }
  }

  /// Créer une nouvelle campagne (méthode legacy avec paiement)
  Future<void> createCampaign(Map<String, dynamic> campaignData) async {
    if (_authProvider?.user == null ||
        (_authProvider!.user!.userType != UserType.business &&
            _authProvider!.user!.userType != UserType.admin)) {
      _setError('غير مصرح لك بإنشاء حملات');
      return;
    }

    try {
      _setLoading(true);
      _clearError();

      final user = _authProvider!.user!;

      // Utiliser advertiserId au lieu de businessId pour correspondre au modèle
      campaignData['advertiserId'] = user.id;

      final result = await _cloudFunctions.callFunction(
        'createCampaignIntent',
        parameters: campaignData,
      );

      if (result['success'] == true) {
        // Recharger les campagnes de l'utilisateur
        await _loadUserCampaigns();

        // Envoyer une notification de succès
        await _cloudFunctions.callFunction(
          'sendUserNotification',
          parameters: {
            'userId': user.id,
            'title': 'تم إنشاء الحملة بنجاح! 🚀',
            'body': 'حملتك "${campaignData['title']}" قيد المراجعة',
            'type': 'campaign_created',
          },
        );
      } else {
        throw Exception(result['error'] ?? 'فشل في إنشاء الحملة');
      }
    } catch (e) {
      _setError('فشل في إنشاء الحملة: $e');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Actualiser les campagnes
  Future<void> refreshCampaigns() async {
    await loadCampaigns();
  }

  /// Réinitialiser les campagnes de test
  Future<void> resetTestCampaigns() async {
    try {
      _setLoading(true);

      final result = await _cloudFunctions.callFunction('resetTestCampaigns');

      if (result['success'] == true) {
        await _loadUserCampaigns();
        await loadCampaigns();
      }
    } catch (error) {
      _setError('فشل في إعادة تعيين الحملات: $error');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
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
    notifyListeners();
  }

  /// Nettoyer les ressources
  void disposeProvider() {
    _campaigns.clear();
    _filteredCampaigns.clear();
    _userCampaigns.clear();
    _campaignClicks.clear();
    _selectedCampaign = null;
    _authProvider = null;
  }
}

/// Filtres de campagne - Version adaptée sans catégories
class CampaignFilter {
  final CampaignType? type;
  final double? minEarnings;
  final double? maxEarnings;
  final bool activeOnly;

  CampaignFilter({
    this.type,
    this.minEarnings,
    this.maxEarnings,
    this.activeOnly = true,
  });

  /// Vérifier s'il y a des filtres actifs
  bool get hasFilters {
    return type != null ||
        minEarnings != null ||
        maxEarnings != null ||
        !activeOnly;
  }

  /// Créer une copie avec des valeurs mises à jour
  CampaignFilter copyWith({
    CampaignType? type,
    double? minEarnings,
    double? maxEarnings,
    bool? activeOnly,
  }) {
    return CampaignFilter(
      type: type ?? this.type,
      minEarnings: minEarnings ?? this.minEarnings,
      maxEarnings: maxEarnings ?? this.maxEarnings,
      activeOnly: activeOnly ?? this.activeOnly,
    );
  }

  /// Effacer tous les filtres
  CampaignFilter clear() {
    return CampaignFilter();
  }
}

/// Types de tri des campagnes
enum CampaignSort {
  newest, // الأحدث
  earningsHigh, // الأعلى ربحاً
  earningsLow, // الأقل ربحاً
  remainingHigh, // الأكثر متبقي
}