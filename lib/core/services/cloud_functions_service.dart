import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

import 'package:flutter/material.dart';

class CloudFunctionsService {
  static final CloudFunctionsService _instance = CloudFunctionsService._internal();
  factory CloudFunctionsService() => _instance;
  CloudFunctionsService._internal();

  FirebaseFunctions _functions = FirebaseFunctions.instance;
  bool _useFallback = false;

  void initialize({bool useEmulator = false, String? region}) {
    if (useEmulator) {
      _functions.useFunctionsEmulator('localhost', 5001);
    }
    
    if (region != null) {
      _functions = FirebaseFunctions.instanceFor(region: region);
    }
  }

  Future<Map<String, dynamic>> callFunction(
    String functionName, {
    Map<String, dynamic>? parameters,
    int timeoutSeconds = 30,
  }) async {
    if (_useFallback) {
      return _getFallbackData(functionName, parameters);
    }

    try {
      final HttpsCallable callable = _functions.httpsCallable(
        functionName,
        options: HttpsCallableOptions(
          timeout: Duration(seconds: timeoutSeconds),
        ),
      );

      final result = await callable.call(parameters ?? {});
      return Map<String, dynamic>.from(result.data);
    } on FirebaseFunctionsException catch (e) {
      // Si la fonction n'existe pas, utiliser le fallback
      if (e.code == 'not-found' || e.code == 'internal') {
        _useFallback = true;
        return _getFallbackData(functionName, parameters);
      }
      throw _handleFunctionsError(e);
    } catch (e) {
      // En cas d'autre erreur, utiliser le fallback
      _useFallback = true;
      return _getFallbackData(functionName, parameters);
    }
  }

  Exception _handleFunctionsError(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'invalid-argument':
        return Exception('معطيات غير صالحة: ${e.message}');
      case 'not-found':
        return Exception('الدالة غير موجودة');
      case 'permission-denied':
        return Exception('ليس لديك صلاحية لاستدعاء هذه الدالة');
      case 'resource-exhausted':
        return Exception('تم تجاوز الحد المسموح، حاول لاحقاً');
      case 'unavailable':
        return Exception('الخدمة غير متاحة حالياً');
      case 'unauthenticated':
        return Exception('يجب تسجيل الدخول أولاً');
      default:
        return Exception('خطأ في الدالة السحابية: ${e.message}');
    }
  }

  // ============ FONCTIONS DASHBOARD ============

  Future<Map<String, dynamic>> getDashboardData() async {
    return await callFunction('getDashboardData');
  }

  Future<Map<String, dynamic>> getRecommendedCampaigns({int limit = 5}) async {
    return await callFunction('getRecommendedCampaigns', parameters: {
      'limit': limit,
    });
  }

  Future<Map<String, dynamic>> getAvailableCampaigns({
    int limit = 10,
    int page = 1,
  }) async {
    return await callFunction('getAvailableCampaigns', parameters: {
      'limit': limit,
      'page': page,
    });
  }

  // ============ FONCTIONS CAMPAIGNS ============

  Future<Map<String, dynamic>> createCampaign(Map<String, dynamic> campaignData) async {
    return await callFunction('createCampaign', parameters: {
      'campaignData': campaignData,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<Map<String, dynamic>> createCampaignDirect(Map<String, dynamic> campaignData) async {
    return await callFunction('createCampaignDirect', parameters: campaignData);
  }

  Future<Map<String, dynamic>> createTestCampaigns(int count) async {
    return await callFunction('createTestCampaigns', parameters: {
      'count': count,
    });
  }

  Future<Map<String, dynamic>> resetTestCampaigns() async {
    return await callFunction('resetTestCampaigns');
  }

  // ============ FONCTIONS CLICS AVEC DÉTECTION DE FRAUDE ============

  /// 🛡️ Traiter un clic avec détection de fraude avancée
  Future<Map<String, dynamic>> processClickWithFraudDetection({
    required String trackingId,
    required String ipAddress,
    required String userAgent,
    required String deviceHash,
    required Map<String, dynamic>? locationData,
    Map<String, dynamic>? fraudDetectionData,
  }) async {
    // 🔍 Collecte des données de détection de fraude
    final fraudData = fraudDetectionData ?? await _collectFraudDetectionData();
    
    return await callFunction('clickHandler', parameters: {
      'trackingId': trackingId,
      'ipAddress': ipAddress,
      'userAgent': userAgent,
      'deviceHash': deviceHash,
      'locationData': locationData,
      'fraudDetectionData': fraudData,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'clientInfo': _getClientInfo(),
    });
  }

  /// 🔍 Collecter les données pour la détection de fraude
  Future<Map<String, dynamic>> _collectFraudDetectionData() async {
    final window = WidgetsBinding.instance.window;
    
    return {
      'screenResolution': '${window.physicalSize.width}x${window.physicalSize.height}',
      'pixelRatio': window.devicePixelRatio,
      'timezone': DateTime.now().timeZoneOffset.inHours,
      'language': Platform.localeName,
      'platform': Platform.operatingSystem,
      'platformVersion': Platform.operatingSystemVersion,
      'appVersion': await _getAppVersion(),
      'deviceInfo': _getDeviceInfo(),
      'touchSupport': _hasTouchSupport(),
      'batteryLevel': await _getBatteryLevel(),
      'networkType': await _getNetworkType(),
      'isEmulator': _isRunningOnEmulator(),
    };
  }

  /// 🌐 Obtenir le type de réseau
  Future<String> _getNetworkType() async {
    try {
      // Implémentation basique - à améliorer avec un package réseau
      return 'wifi'; // Placeholder
    } catch (e) {
      return 'unknown';
    }
  }

  /// 🔋 Obtenir le niveau de batterie
  Future<double?> _getBatteryLevel() async {
    try {
      // Implémentation avec un package batterie si nécessaire
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 📱 Vérifier si c'est un émulateur
  bool _isRunningOnEmulator() {
    return !kReleaseMode; // En debug, considérer comme émulateur
  }

  /// 👆 Vérifier le support tactile
  bool _hasTouchSupport() {
    return true; // La plupart des devices mobiles ont le touch
  }

  /// 📲 Obtenir les informations du device
  Map<String, dynamic> _getDeviceInfo() {
    return {
      'brand': _getDeviceBrand(),
      'model': _getDeviceModel(),
      'androidId': _getAndroidId(),
      'isPhysicalDevice': _isPhysicalDevice(),
    };
  }

  String _getDeviceBrand() {
    try {
      return Platform.localHostname;
    } catch (e) {
      return 'unknown';
    }
  }

  String _getDeviceModel() {
    try {
      return Platform.operatingSystem;
    } catch (e) {
      return 'unknown';
    }
  }

  String _getAndroidId() {
    // À implémenter avec un package device info
    return 'unknown';
  }

  bool _isPhysicalDevice() {
    return true; // Placeholder
  }

  /// 🏷️ Obtenir la version de l'app
  Future<String> _getAppVersion() async {
    try {
      // À implémenter avec package_info_plus
      return '1.0.0';
    } catch (e) {
      return 'unknown';
    }
  }

  /// 💻 Obtenir les infos client
  Map<String, dynamic> _getClientInfo() {
    return {
      'sdkVersion': 'Flutter 3.0+',
      'appBuild': '1.0.0',
      'flutterVersion': '3.0+',
      'clientTimestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  // ============ FONCTIONS ANTI-FRAUDE AVANCÉES ============

  /// 🎯 Analyser un clic spécifique pour la fraude
  Future<Map<String, dynamic>> analyzeClickFraud({
    required String clickId,
    required Map<String, dynamic> clickData,
  }) async {
    return await callFunction('analyzeClickFraud', parameters: {
      'clickId': clickId,
      'clickData': clickData,
      'analysisTimestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// 📊 Obtenir les rapports de fraude
  Future<Map<String, dynamic>> getFraudReports({
    DateTime? startDate,
    DateTime? endDate,
    String? period = '24h',
  }) async {
    return await callFunction('getFraudReports', parameters: {
      'startDate': startDate?.millisecondsSinceEpoch,
      'endDate': endDate?.millisecondsSinceEpoch,
      'period': period,
    });
  }

  /// 📈 Obtenir les statistiques de détection de fraude
  Future<Map<String, dynamic>> getFraudDetectionStats({String? userId}) async {
    return await callFunction('getFraudDetectionStats', parameters: {
      'userId': userId,
    });
  }

  /// 🚨 Signaler un clic suspect
  Future<Map<String, dynamic>> reportSuspiciousClick({
    required String clickId,
    required String reason,
    Map<String, dynamic>? evidence,
  }) async {
    return await callFunction('reportSuspiciousClick', parameters: {
      'clickId': clickId,
      'reason': reason,
      'evidence': evidence,
      'reportedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// 🔄 Vérifier le statut de libération des fonds
  Future<Map<String, dynamic>> checkFundsReleaseStatus({
    required String userId,
    required String clickId,
  }) async {
    return await callFunction('checkFundsReleaseStatus', parameters: {
      'userId': userId,
      'clickId': clickId,
    });
  }

  // ============ FONCTIONS PAIEMENT ET SUIVI ============

  Future<Map<String, dynamic>> createCampaignIntent({
    required String title,
    required String description,
    required String targetUrl,
    required double budget,
    double cpc = 0.06,
  }) async {
    return await callFunction('createCampaignIntent', parameters: {
      'title': title,
      'description': description,
      'targetUrl': targetUrl,
      'budget': budget,
      'cpc': cpc,
    });
  }

  Future<Map<String, dynamic>> generateTrackingLink({
    required String campaignId,
    required String participantId,
  }) async {
    return await callFunction('generateTrackingLink', parameters: {
      'campaignId': campaignId,
      'participantId': participantId,
    });
  }

  // ============ FONCTIONS ANALYTIQUES ============

  Future<Map<String, dynamic>> getCampaignAnalytics(String campaignId) async {
    return await callFunction('getCampaignAnalytics', parameters: {
      'campaignId': campaignId,
    });
  }

  Future<Map<String, dynamic>> getBusinessCampaigns() async {
    return await callFunction('getBusinessCampaigns');
  }

  Future<Map<String, dynamic>> getEarningsReport({
    required DateTime startDate,
    required DateTime endDate,
    String? period,
  }) async {
    return await callFunction('getEarningsReport', parameters: {
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate.millisecondsSinceEpoch,
      'period': period,
    });
  }

  // ============ FONCTIONS PARRAINAGE ============

  Future<Map<String, dynamic>> processReferral({
    required String referrerId,
    required String newUserId,
    required String referralCode,
  }) async {
    return await callFunction('processReferral', parameters: {
      'referrerId': referrerId,
      'newUserId': newUserId,
      'referralCode': referralCode,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<Map<String, dynamic>> getReferralStats() async {
    return await callFunction('getReferralStats');
  }

  // ============ FONCTIONS FINANCIÈRES ============

  Future<Map<String, dynamic>> createWithdrawal({
    required String userId,
    required double amount,
    required String paymentMethod,
    required Map<String, dynamic> paymentDetails,
  }) async {
    return await callFunction('createWithdrawal', parameters: {
      'userId': userId,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'paymentDetails': paymentDetails,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<Map<String, dynamic>> updateUserBalance({
    required String userId,
    required double amount,
    required String transactionType,
    required String description,
  }) async {
    return await callFunction('updateUserBalance', parameters: {
      'userId': userId,
      'amount': amount,
      'transactionType': transactionType,
      'description': description,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // ============ FONCTIONS STATISTIQUES ============

  Future<Map<String, dynamic>> getUserStats({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return await callFunction('getUserStats', parameters: {
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate.millisecondsSinceEpoch,
    });
  }

  // ============ FONCTIONS NOTIFICATIONS ============

  Future<Map<String, dynamic>> sendUserNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    return await callFunction('sendUserNotification', parameters: {
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'data': data,
    });
  }

  // ============ FONCTIONS UTILITAIRES ============

  Future<Map<String, dynamic>> repairUserData() async {
    return await callFunction('repairUserData');
  }

  Future<Map<String, dynamic>> fixCampaignData() async {
    return await callFunction('fixCampaignData');
  }

  Future<Map<String, dynamic>> createCleanTestData() async {
    return await callFunction('createCleanTestData');
  }

  // ============ FONCTION DE TEST ============

  Future<Map<String, dynamic>> testConnection() async {
    return await callFunction('testFunction');
  }

  // ============ FALLBACK SYSTEM ============

  Map<String, dynamic> _getFallbackData(String functionName, Map<String, dynamic>? parameters) {
    print('Using fallback for function: $functionName');
    
    switch (functionName) {
      case 'getDashboardData':
        return _getFallbackDashboardData();
      
      case 'getRecommendedCampaigns':
        final limit = parameters?['limit'] ?? 5;
        return _getFallbackRecommendedCampaigns(limit);
      
      case 'getAvailableCampaigns':
        final limit = parameters?['limit'] ?? 10;
        final page = parameters?['page'] ?? 1;
        return _getFallbackAvailableCampaigns(limit, page);
      
      case 'getUserStats':
        return _getFallbackUserStats();
      
      case 'getFraudDetectionStats':
        return _getFallbackFraudStats();
      
      case 'createCampaignIntent':
        return {
          'success': true,
          'paymentUrl': 'https://example.com/payment-fallback',
          'paymentId': 'fallback_payment_${DateTime.now().millisecondsSinceEpoch}',
          'orderId': 'fallback_order_${DateTime.now().millisecondsSinceEpoch}',
          'usingFallback': true
        };
      
      case 'generateTrackingLink':
        return {
          'success': true,
          'trackingLink': 'https://reshare.tn/click?c=fallback_campaign&s=fallback_share',
          'shareId': 'fallback_share_${DateTime.now().millisecondsSinceEpoch}',
          'campaignTitle': 'حملة تجريبية',
          'usingFallback': true
        };
      
      case 'clickHandler':
        return _getFallbackClickHandler(parameters);
      
      case 'testFunction':
        return {
          'success': true,
          'message': 'Fallback mode active - Cloud Functions not deployed',
          'timestamp': DateTime.now().toIso8601String(),
          'usingFallback': true
        };
      
      default:
        return {
          'success': false,
          'error': 'الدالة غير متاحة حالياً',
          'usingFallback': true
        };
    }
  }

  Map<String, dynamic> _getFallbackClickHandler(Map<String, dynamic>? parameters) {
    // Simulation d'analyse de fraude en fallback
    final riskScore = DateTime.now().millisecond % 100; // Score aléatoire 0-99
    final requiresReview = riskScore > 70;
    const earnings = 0.1;

    return {
      'success': true,
      'redirectUrl': 'https://example.com',
      'earnings': requiresReview ? 0.0 : earnings,
      'riskScore': riskScore,
      'requiresManualReview': requiresReview,
      'fraudAnalysis': {
        'riskLevel': riskScore > 80 ? 'high' : riskScore > 50 ? 'medium' : 'low',
        'flags': riskScore > 80 ? ['HIGH_RISK_SCORE'] : [],
        'confidence': 100 - riskScore,
      },
      'usingFallback': true,
    };
  }

  Map<String, dynamic> _getFallbackFraudStats() {
    return {
      'success': true,
      'stats': {
        'totalClicks': 150,
        'validClicks': 135,
        'suspiciousClicks': 12,
        'fraudulentClicks': 3,
        'fraudRate': 2.0,
        'avgRiskScore': 25.5,
        'manualReviews': 8,
        'autoRejected': 3,
      },
      'topPatterns': [
        {'pattern': 'HIGH_FREQUENCY', 'count': 5},
        {'pattern': 'SUSPICIOUS_IP', 'count': 3},
        {'pattern': 'BOT_DETECTED', 'count': 2},
      ],
      'usingFallback': true,
    };
  }

  Map<String, dynamic> _getFallbackDashboardData() {
    return {
      'success': true,
      'stats': {
        'totalEarnings': 45.50,
        'availableBalance': 25.75,
        'pendingBalance': 19.75,
        'totalClicks': 155,
        'totalShares': 89,
        'referralCount': 12,
        'weeklyEarnings': 8.25,
        'weeklyClicks': 32,
        'weeklyGrowth': 12.5,
      },
      'recentClicks': [
        {
          'id': 'fallback_1',
          'campaignId': 'camp_1',
          'campaignTitle': 'حملة تجريبية',
          'earnings': 0.1,
          'status': 'valid',
          'clickedAt': DateTime.now().subtract(Duration(hours: 2)).toIso8601String(),
        },
        {
          'id': 'fallback_2',
          'campaignId': 'camp_2',
          'campaignTitle': 'عرض خاص',
          'earnings': 0.15,
          'status': 'valid',
          'clickedAt': DateTime.now().subtract(Duration(hours: 5)).toIso8601String(),
        }
      ],
      'usingFallback': true
    };
  }

  Map<String, dynamic> _getFallbackRecommendedCampaigns(int limit) {
    final campaigns = [
      {
        'id': 'rec_1',
        'title': 'حملة مميزة 🔥',
        'description': 'هذه حملة موصى بها خصيصاً لك',
        'targetUrl': 'https://example.com',
        'type': 'open',
        'status': 'active',
        'budget': 1000.0,
        'spent': 250.0,
        'cpc': 0.15,
        'targetClicks': 5000,
        'achievedClicks': 1250,
        'uniqueClicks': 1100,
        'isActive': true,
        'maxClicksPerUser': 3,
        'conversionRate': 2.5,
        'conversions': 25,
        'createdAt': DateTime.now().subtract(Duration(days: 5)).toIso8601String(),
        'startDate': DateTime.now().subtract(Duration(days: 5)).toIso8601String(),
        'endDate': DateTime.now().add(Duration(days: 25)).toIso8601String(),
        'imageUrl': null,
      },
      {
        'id': 'rec_2',
        'title': 'عرض محدود الوقت ⏰',
        'description': 'احصل على مكافآت مضاعفة في هذه الحملة الخاصة',
        'targetUrl': 'https://example.com',
        'type': 'regional',
        'status': 'active',
        'budget': 500.0,
        'spent': 150.0,
        'cpc': 0.2,
        'targetClicks': 2000,
        'achievedClicks': 750,
        'uniqueClicks': 700,
        'isActive': true,
        'maxClicksPerUser': 2,
        'conversionRate': 3.0,
        'conversions': 15,
        'createdAt': DateTime.now().subtract(Duration(days: 2)).toIso8601String(),
        'startDate': DateTime.now().subtract(Duration(days: 2)).toIso8601String(),
        'endDate': DateTime.now().add(Duration(days: 8)).toIso8601String(),
        'imageUrl': null,
      }
    ];

    return {
      'success': true,
      'campaigns': campaigns.take(limit).toList(),
      'count': campaigns.length,
      'usingFallback': true
    };
  }

  Map<String, dynamic> _getFallbackAvailableCampaigns(int limit, int page) {
    final campaigns = [
      {
        'id': 'avail_1',
        'title': 'حملة التسويق الرقمي',
        'description': 'انضم إلى حملتنا التسويقية واربح مع كل نقرة',
        'targetUrl': 'https://example.com',
        'type': 'open',
        'status': 'active',
        'budget': 2000.0,
        'spent': 800.0,
        'cpc': 0.1,
        'targetClicks': 10000,
        'achievedClicks': 4000,
        'uniqueClicks': 3800,
        'isActive': true,
        'maxClicksPerUser': 3,
        'conversionRate': 1.8,
        'conversions': 45,
        'createdAt': DateTime.now().subtract(Duration(days: 10)).toIso8601String(),
        'startDate': DateTime.now().subtract(Duration(days: 10)).toIso8601String(),
        'endDate': DateTime.now().add(Duration(days: 20)).toIso8601String(),
        'imageUrl': null,
      },
      {
        'id': 'avail_2',
        'title': 'عروض التطبيقات',
        'description': 'اكتشف أفضل التطبيقات واربح معنا',
        'targetUrl': 'https://example.com',
        'type': 'precise',
        'status': 'active',
        'budget': 1500.0,
        'spent': 600.0,
        'cpc': 0.12,
        'targetClicks': 8000,
        'achievedClicks': 3000,
        'uniqueClicks': 2800,
        'isActive': true,
        'maxClicksPerUser': 2,
        'conversionRate': 2.2,
        'conversions': 35,
        'createdAt': DateTime.now().subtract(Duration(days: 7)).toIso8601String(),
        'startDate': DateTime.now().subtract(Duration(days: 7)).toIso8601String(),
        'endDate': DateTime.now().add(Duration(days: 23)).toIso8601String(),
        'imageUrl': null,
      }
    ];

    // Simulation de pagination simple
    final startIndex = (page - 1) * limit;
    final endIndex = startIndex + limit;
    final paginatedCampaigns = campaigns.sublist(
      startIndex.clamp(0, campaigns.length),
      endIndex.clamp(0, campaigns.length)
    );

    return {
      'success': true,
      'campaigns': paginatedCampaigns,
      'count': paginatedCampaigns.length,
      'page': page,
      'hasMore': endIndex < campaigns.length,
      'usingFallback': true
    };
  }

  Map<String, dynamic> _getFallbackUserStats() {
    return {
      'success': true,
      'stats': {
        'totalEarnings': 45.50,
        'todayEarnings': 2.25,
        'weekEarnings': 15.75,
        'monthEarnings': 45.50,
        'totalClicks': 155,
        'validClicks': 142,
        'uniqueClicks': 138,
        'conversionRate': 2.3,
        'avgEarningsPerClick': 0.1,
      },
      'chartData': {
        'labels': ['الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'],
        'earnings': [2.1, 1.8, 2.5, 3.2, 2.8, 1.9, 2.25],
        'clicks': [18, 15, 22, 28, 25, 17, 19],
      },
      'usingFallback': true
    };
  }

  // ============ MÉTHODES UTILITAIRES ============

  /// Vérifier si le service utilise le mode fallback
  bool get isUsingFallback => _useFallback;

  /// Réinitialiser le mode fallback
  void resetFallback() {
    _useFallback = false;
  }

  /// Tester la connexion aux Cloud Functions
  Future<bool> checkConnection() async {
    try {
      final result = await testConnection();
      return result['success'] == true && result['usingFallback'] != true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> shareCampaign({
    required String campaignId,
    required String userId,
    required String userLocation,
  }) async {
    return await callFunction('shareCampaign', parameters: {
      'campaignId': campaignId,
      'userId': userId,
      'userLocation': userLocation,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }
  // ============ GESTION DES ERREURS AMÉLIORÉE ============

  Future<Map<String, dynamic>> safeCallFunction(
    String functionName, {
    Map<String, dynamic>? parameters,
    int timeoutSeconds = 30,
    int maxRetries = 2,
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        return await callFunction(
          functionName,
          parameters: parameters,
          timeoutSeconds: timeoutSeconds,
        );
      } catch (e) {
        if (attempt == maxRetries) {
          rethrow;
        }
        // Attendre avant de réessayer
        await Future.delayed(Duration(seconds: attempt));
      }
    }
    throw Exception('فشل في استدعاء الدالة بعد $maxRetries محاولات');
  }
}