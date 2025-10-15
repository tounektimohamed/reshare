import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../data/models/user_model.dart';
import '../../../../data/models/campaign_model.dart';
import '../../../../data/models/click_model.dart';
import '../../../../data/repositories/campaign_repository.dart';
import '../../../../data/repositories/click_repository.dart';
import '../../../../data/repositories/user_repository.dart';
import '../../../../core/services/cloud_functions_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class DashboardProvider with ChangeNotifier {
  final CampaignRepository _campaignRepository = CampaignRepository();
  final ClickRepository _clickRepository = ClickRepository();
  final UserRepository _userRepository = UserRepository();
  final CloudFunctionsService _cloudFunctions = CloudFunctionsService();

  AuthProvider? _authProvider;

  // État du provider
  List<CampaignModel> _availableCampaigns = [];
  List<CampaignModel> _recommendedCampaigns = [];
  List<ClickModel> _recentClicks = [];
  DashboardStats _stats = DashboardStats();
  bool _isLoading = false;
  String? _error;
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  // Getters
  List<CampaignModel> get availableCampaigns => _availableCampaigns;
  List<CampaignModel> get recommendedCampaigns => _recommendedCampaigns;
  List<ClickModel> get recentClicks => _recentClicks;
  DashboardStats get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTimeRange get dateRange => _dateRange;

  /// Mettre à jour le provider d'authentification
  void updateAuth(AuthProvider authProvider) {
    _authProvider = authProvider;
    if (authProvider.isAuthenticated && authProvider.user != null) {
      loadDashboardData();
      _startRealTimeUpdates();
    }
  }

  /// Charger les données du tableau de bord
  Future<void> loadDashboardData() async {
    if (_authProvider?.user == null) return;

    try {
      _setLoading(true);
      _clearError();

      print('🔄 Loading dashboard data...');

      await Future.wait([
        _loadAvailableCampaigns(),
        _loadRecommendedCampaigns(),
        _loadRecentClicks(),
        _loadDashboardStats(),
      ]);

      print('✅ Dashboard data loaded successfully');
    } catch (e) {
      print('❌ Error loading dashboard data: $e');
      _setError('فشل في تحميل بيانات لوحة التحكم: $e');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Charger les campagnes disponibles
  // Dans DashboardProvider - méthode _loadAvailableCampaigns
  Future<void> _loadAvailableCampaigns() async {
    try {
      final user = _authProvider!.user!;

      print('👤 Loading campaigns for user: ${user.id}');
      print('🎯 User type: ${user.userType.name}');

      _availableCampaigns = await _campaignRepository.getAvailableCampaigns(
        userId: user.id,
        locationPreference: user.locationPreference,
      );

      print('✅ Loaded ${_availableCampaigns.length} available campaigns');

      // 🔥 DEBUG: Afficher les campagnes chargées
      for (var campaign in _availableCampaigns) {
        print('📋 Campaign: ${campaign.title} - Type: ${campaign.type.name}');
      }
    } catch (e) {
      print('❌ Error loading available campaigns: $e');
      throw Exception('فشل في تحميل الحملات المتاحة: $e');
    }
  }

  /// Charger les campagnes recommandées
  Future<void> _loadRecommendedCampaigns() async {
    try {
      final user = _authProvider!.user!;

      // 🔥 CORRECTION : Utiliser directement le repository au lieu de Cloud Functions
      _recommendedCampaigns = await _campaignRepository.getRecommendedCampaigns(
        userId: user.id,
        locationPreference: user.locationPreference,
        preferredCategories: user.preferredCategories ?? [],
      );

      print('✅ Loaded ${_recommendedCampaigns.length} recommended campaigns');
    } catch (e) {
      print('❌ Error loading recommended campaigns: $e');
      // Fallback aux campagnes régulières
      _recommendedCampaigns = _availableCampaigns.take(3).toList();
    }
  }

  /// Charger les clics récents - VERSION CORRIGÉE
  Future<void> _loadRecentClicks() async {
    try {
      final user = _authProvider!.user!;
      print('🔄 Loading recent clicks for user: ${user.id}');

      _recentClicks = await _clickRepository.getUserClicks(
        userId: user.id,
        limit: 10,
      );

      print('✅ Successfully loaded ${_recentClicks.length} recent clicks');

      // Debug: Afficher les clics chargés
      for (var click in _recentClicks) {
        print(
          '📋 Click: ${click.campaignTitle} - ${click.clickedAt} - ${click.earnings} TND',
        );
      }
    } catch (e) {
      print('❌ Error loading recent clicks: $e');
      // Fallback sécurisé
      _recentClicks = [];
      // Ne pas throw pour éviter de bloquer tout le dashboard
    }
  }

  /// Charger les statistiques du tableau de bord
  /// Charger les statistiques du tableau de bord
  /// Charger les statistiques du tableau de bord - VERSION CORRIGÉE
  Future<void> _loadDashboardStats() async {
    try {
      final user = _authProvider!.user!;

      final now = DateTime.now();
      final weekStart = now.subtract(const Duration(days: 7));
      final monthStart = DateTime(now.year, now.month, 1);

      // 🔥 CORRECTION: Récupérer les stats depuis Firestore directement
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.id)
          .get();

      final userData = userDoc.data() as Map<String, dynamic>? ?? {};

      // 🔥 CORRECTION: Utiliser les valeurs réelles de l'utilisateur
      final userTotalEarnings = (userData['totalEarnings'] ?? 0).toDouble();
      final userAvailableBalance = (userData['availableBalance'] ?? 0)
          .toDouble();
      final userPendingBalance = (userData['pendingBalance'] ?? 0).toDouble();
      final userTotalClicks = (userData['totalClicks'] ?? 0).toInt();
      final userTotalShares = (userData['totalShares'] ?? 0).toInt();
      final userReferralCount = (userData['referralCount'] ?? 0).toInt();

      // Calculer les stats hebdomadaires et mensuelles
      final weeklyStats = await _clickRepository.getUserStats(
        userId: user.id,
        startDate: weekStart,
        endDate: now,
      );

      final monthlyStats = await _clickRepository.getUserStats(
        userId: user.id,
        startDate: monthStart,
        endDate: now,
      );

      _stats = DashboardStats(
        // 🔥 CORRECTION: Utiliser les vraies valeurs de l'utilisateur
        totalEarnings: userTotalEarnings,
        availableBalance: userAvailableBalance,
        pendingBalance: userPendingBalance,
        totalClicks: userTotalClicks,
        totalShares: userTotalShares,
        referralCount: userReferralCount,
        weeklyEarnings: weeklyStats.totalEarnings,
        weeklyClicks: weeklyStats.totalClicks,
        monthlyEarnings: monthlyStats.totalEarnings,
        monthlyClicks: monthlyStats.totalClicks,
        conversionRate: monthlyStats.conversionRate,
        activeCampaigns: _availableCampaigns.length,
      );

      print('✅ Dashboard stats loaded successfully');
      print('💰 Total Earnings: $userTotalEarnings');
      print('💳 Available Balance: $userAvailableBalance');
      print('⏳ Pending Balance: $userPendingBalance');
      print('👆 Total Clicks: $userTotalClicks');
    } catch (e) {
      print('❌ Error loading dashboard stats: $e');

      // 🔥 FALLBACK: Utiliser les valeurs par défaut en cas d'erreur
      _stats = DashboardStats(
        totalEarnings: 0.0,
        availableBalance: 0.0,
        pendingBalance: 0.0,
        totalClicks: 0,
        totalShares: 0,
        referralCount: 0,
        weeklyEarnings: 0.0,
        weeklyClicks: 0,
        monthlyEarnings: 0.0,
        monthlyClicks: 0,
        conversionRate: 0.0,
        activeCampaigns: _availableCampaigns.length,
      );
    }
  }

  /// Filtrer les campagnes par catégorie
  Future<void> filterCampaignsByCategory(String category) async {
    try {
      _setLoading(true);

      if (category.isEmpty) {
        await _loadAvailableCampaigns();
      } else {
        final user = _authProvider!.user!;
        _availableCampaigns = await _campaignRepository.getCampaignsByCategory(
          category: category,
          userId: user.id,
          locationPreference: user.locationPreference,
        );
      }
    } catch (e) {
      _setError('فشل في تصفية الحملات: $e');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Rechercher dans les campagnes
  Future<void> searchCampaigns(String query) async {
    try {
      _setLoading(true);

      if (query.isEmpty) {
        await _loadAvailableCampaigns();
      } else {
        final user = _authProvider!.user!;
        _availableCampaigns = await _campaignRepository.searchCampaigns(
          query: query,
          userId: user.id,
          locationPreference: user.locationPreference,
        );
      }
    } catch (e) {
      _setError('فشل في البحث في الحملات: $e');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Mettre à jour la plage de dates pour les statistiques
  Future<void> updateDateRange(DateTimeRange newRange) async {
    _dateRange = newRange;
    await _loadDashboardStats();
    notifyListeners();
  }

  /// Actualiser les données du tableau de bord
  Future<void> refreshDashboard() async {
    await loadDashboardData();
  }

  /// Obtenir les tendances des revenus
  Future<List<RevenueTrend>> getRevenueTrends() async {
    if (_authProvider?.user == null) return [];

    try {
      final result = await _cloudFunctions.callFunction(
        'getRevenueTrends',
        parameters: {'userId': _authProvider!.user!.id, 'days': 30},
      );

      if (result['success'] == true) {
        final trendsData = List<Map<String, dynamic>>.from(
          result['trends'] ?? [],
        );
        return trendsData.map((data) => RevenueTrend.fromMap(data)).toList();
      }

      return [];
    } catch (e) {
      print('فشل في الحصول على اتجاهات الإيرادات: $e');
      return [];
    }
  }

  /// Démarrer les mises à jour en temps réel
  void _startRealTimeUpdates() {
    final user = _authProvider!.user;
    if (user == null) return;

    // 🔹 Écouter les mises à jour des campagnes actives
    FirebaseFirestore.instance
        .collection('campaigns')
        .where('status', isEqualTo: CampaignStatus.active.index)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
          _availableCampaigns = snapshot.docs
              .map(
                (doc) =>
                    CampaignModel.fromMap(doc.data() as Map<String, dynamic>),
              )
              .toList();

          // Tri local (facultatif : du plus récent au plus ancien)
          _availableCampaigns.sort(
            (a, b) => b.createdAt.compareTo(a.createdAt),
          );

          notifyListeners();
        });

    // 🔹 Écouter les mises à jour des clics de l'utilisateur
    FirebaseFirestore.instance
        .collection('clicks')
        .where('userId', isEqualTo: user.id)
        .snapshots()
        .listen((snapshot) {
          _recentClicks = snapshot.docs
              .map(
                (doc) => ClickModel.fromMap(doc.data() as Map<String, dynamic>),
              )
              .toList();

          // Tri local (récents en premier)
          _recentClicks.sort((a, b) => b.clickedAt.compareTo(a.clickedAt));

          // Limiter à 10 résultats
          _recentClicks = _recentClicks.take(10).toList();

          notifyListeners();
        });
  }

  // Méthodes helpers pour la gestion de l'état
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

/// Statistiques du tableau de bord
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
}

/// Tendance des revenus
class RevenueTrend {
  final DateTime date;
  final double earnings;
  final int clicks;

  RevenueTrend({
    required this.date,
    required this.earnings,
    required this.clicks,
  });

  factory RevenueTrend.fromMap(Map<String, dynamic> map) {
    return RevenueTrend(
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      earnings: (map['earnings'] ?? 0).toDouble(),
      clicks: map['clicks'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date.millisecondsSinceEpoch,
      'earnings': earnings,
      'clicks': clicks,
    };
  }
}
