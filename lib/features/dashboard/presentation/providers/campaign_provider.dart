import 'package:flutter/foundation.dart';

import '../../../../core/services/cloud_functions_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../data/models/campaign_model.dart';
import '../../../../data/repositories/campaign_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class CampaignProvider with ChangeNotifier {
  final CampaignRepository _campaignRepository = CampaignRepository();
  final CloudFunctionsService _cloudFunctions = CloudFunctionsService();
  final LocationService _locationService = LocationService();

  AuthProvider? _authProvider;

  List<CampaignModel> _campaigns = [];
  CampaignModel? _selectedCampaign;
  bool _isLoading = false;
  String? _error;

  List<CampaignModel> get campaigns => _campaigns;
  CampaignModel? get selectedCampaign => _selectedCampaign;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void updateAuth(AuthProvider authProvider) {
    _authProvider = authProvider;
  }

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

    } catch (e) {
      _setError('فشل في تحميل الحملات: $e');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<void> loadCampaign(String campaignId) async {
    try {
      _setLoading(true);
      _clearError();

      _selectedCampaign = await _campaignRepository.getCampaignById(campaignId);

    } catch (e) {
      _setError('فشل في تحميل الحملة: $e');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<void> shareCampaign(CampaignModel campaign) async {
    if (_authProvider?.user == null) return;

    try {
      _setLoading(true);
      _clearError();

      final user = _authProvider!.user!;

      // 1. Get user location
      final location = await _locationService.getCurrentLocation();
      final locationString = location != null 
          ? '${location.latitude},${location.longitude}'
          : 'unknown';

      // 2. Call Cloud Function to share campaign
      final result = await _cloudFunctions.shareCampaign(
        campaignId: campaign.id,
        userId: user.id,
        userLocation: locationString,
      );

      if (result['success'] == true) {
        final shareLink = result['shareLink'];
        
        // 3. Record the share in database
        await _campaignRepository.recordCampaignShare(
          userId: user.id,
          campaignId: campaign.id,
          shareLink: shareLink,
        );

        // 4. Send success notification
        await _cloudFunctions.sendUserNotification(
          userId: user.id,
          title: 'تمت المشاركة بنجاح! 🎯',
          body: 'حملة "${campaign.title}" جاهزة للمشاركة',
          type: 'campaign_shared',
        );
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

/// 🛡️ Traiter un clic avec détection de fraude avancée
Future<void> processClick({
  required String trackingId,
  required String ipAddress,
  required String userAgent,
  required String deviceHash,
}) async {
  try {
    final location = await _locationService.getCurrentLocation();
    final locationData = location?.toMap();

    // Appeler Cloud Function améliorée avec détection de fraude
    final result = await _cloudFunctions.processClickWithFraudDetection(
      trackingId: trackingId,
      ipAddress: ipAddress,
      userAgent: userAgent,
      deviceHash: deviceHash,
      locationData: locationData,
    );

    if (result['success'] == true && _authProvider?.user != null) {
      final earnings = result['earnings'] ?? 0.0;
      final riskScore = result['riskScore'] ?? 0;
      final requiresReview = result['requiresManualReview'] ?? false;
      final fraudAnalysis = result['fraudAnalysis'] ?? {};
      
      // Gérer différents cas basés sur l'analyse de fraude
      if (requiresReview) {
        await _handleManualReviewCase(riskScore, fraudAnalysis);
      }
      
      if (earnings > 0) {
        // Mettre à jour le solde de l'utilisateur
        await _cloudFunctions.updateUserBalance(
          userId: _authProvider!.user!.id,
          amount: earnings,
          transactionType: 'click_earning',
          description: 'أرباح من نقرة صالحة',
        );

        // Notification adaptée au risque
        await _sendRiskAwareNotification(earnings, riskScore, requiresReview);
      }
    } else if (result['flaggedAsFraud'] == true) {
      // Gérer le cas de fraude détectée
      await _handleFraudulentClick(result['fraudReason']);
    }
  } catch (e) {
    print('فشل في معالجة النقرة: $e');
  }
}

/// 🚨 Gérer le cas de vérification manuelle
Future<void> _handleManualReviewCase(int riskScore, Map<String, dynamic> fraudAnalysis) async {
  await _cloudFunctions.sendUserNotification(
    userId: _authProvider!.user!.id,
    title: 'نقرة قيد المراجعة ⚠️',
    body: 'نقرتك تحت المراجعة للأمان. سيتم تحويل الأرباح بعد التأكد.',
    type: 'click_under_review',
    data: {
      'riskScore': riskScore,
      'analysis': fraudAnalysis,
    },
  );
}

/// 💰 Envoyer une notification adaptée au risque
Future<void> _sendRiskAwareNotification(double earnings, int riskScore, bool requiresReview) async {
  final title = requiresReview ? 'أرباح قيد المراجعة ⚠️' : 'أرباح جديدة! 💰';
  final body = requiresReview 
      ? 'ربحت ${earnings.toStringAsFixed(3)} دينار. الأرباح قيد المراجعة للأمان.'
      : 'لقد ربحت ${earnings.toStringAsFixed(3)} دينار من مشاركاتك';

  await _cloudFunctions.sendUserNotification(
    userId: _authProvider!.user!.id,
    title: title,
    body: body,
    type: requiresReview ? 'earning_pending_review' : 'earning_received',
    data: {
      'earnings': earnings,
      'riskScore': riskScore,
      'requiresReview': requiresReview,
    },
  );
}

/// 🚫 Gérer un clic frauduleux
Future<void> _handleFraudulentClick(String reason) async {
  await _cloudFunctions.sendUserNotification(
    userId: _authProvider!.user!.id,
    title: 'نقرة غير صالحة 🚫',
    body: 'تم رفض النقرة بسبب: $reason',
    type: 'click_rejected',
    data: {'reason': reason},
  );
}

/// 📊 Obtenir les statistiques de fraude
Future<Map<String, dynamic>> getFraudDetectionStats() async {
  if (_authProvider?.user == null) return {};
  
  try {
    return await _cloudFunctions.getFraudDetectionStats(
      userId: _authProvider!.user!.id,
    );
  } catch (e) {
    print('فشل في الحصول على إحصائيات الكشف عن الاحتيال: $e');
    return {};
  }
}

  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading) _clearError();
  }

  void _setError(String error) {
    _error = error;
  }

  void _clearError() {
    _error = null;
  }
}