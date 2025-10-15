import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../data/models/transaction_model.dart';
import '../../../../data/models/click_model.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/repositories/transaction_repository.dart';
import '../../../../data/repositories/click_repository.dart';
import '../../../../data/repositories/user_repository.dart';
import '../../../../core/services/cloud_functions_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class EarningsProvider with ChangeNotifier {
  final TransactionRepository _transactionRepository = TransactionRepository();
  final ClickRepository _clickRepository = ClickRepository();
  final UserRepository _userRepository = UserRepository();
  final CloudFunctionsService _cloudFunctions = CloudFunctionsService();

  AuthProvider? _authProvider;

  // État du provider
  List<TransactionModel> _transactions = [];
  List<ClickModel> _earningClicks = [];
  EarningsStats _stats = EarningsStats();
  bool _isLoading = false;
  String? _error;
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );
  TransactionType? _filterType;

  // Getters
  List<TransactionModel> get transactions => _transactions;
  List<ClickModel> get earningClicks => _earningClicks;
  EarningsStats get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTimeRange get dateRange => _dateRange;
  TransactionType? get filterType => _filterType;

  /// Mettre à jour le provider d'authentification
  void updateAuth(AuthProvider authProvider) {
    _authProvider = authProvider;
    if (authProvider.isAuthenticated && authProvider.user != null) {
      loadEarningsData();
      _startRealTimeUpdates();
    }
  }

  /// Charger les données de gains
  Future<void> loadEarningsData() async {
    if (_authProvider?.user == null) return;

    try {
      _setLoading(true);
      _clearError();

      print('🔄 Loading earnings data...');

      await Future.wait([
        _loadTransactions(),
        _loadEarningClicks(),
        _loadEarningsStats(),
      ]);

      print('✅ Earnings data loaded successfully');

    } catch (e) {
      print('❌ Error loading earnings data: $e');
      _setError('فشل في تحميل بيانات الأرباح: $e');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Charger les transactions
  Future<void> _loadTransactions() async {
    try {
      final user = _authProvider!.user!;
      _transactions = await _transactionRepository.getUserTransactions(
        userId: user.id,
        limit: 50,
      );
      
      print('✅ Loaded ${_transactions.length} transactions');
    } catch (e) {
      print('❌ Error loading transactions: $e');
      throw Exception('فشل في تحميل المعاملات: $e');
    }
  }

  /// Charger les clics générateurs de revenus
  Future<void> _loadEarningClicks() async {
    try {
      final user = _authProvider!.user!;
      _earningClicks = await _clickRepository.getEarningClicks(
        userId: user.id,
        limit: 20,
      );
      
      print('✅ Loaded ${_earningClicks.length} earning clicks');
    } catch (e) {
      print('❌ Error loading earning clicks: $e');
      throw Exception('فشل في تحميل النقرات المربحة: $e');
    }
  }

  /// Charger les statistiques de gains - VERSION CORRIGÉE
  Future<void> _loadEarningsStats() async {
    try {
      final user = _authProvider!.user!;
      
      // 🔥 CORRECTION: Récupérer les données utilisateur fraîches depuis Firestore
      final freshUser = await _userRepository.getUserById(user.id);
      if (freshUser == null) {
        throw Exception('المستخدم غير موجود');
      }

      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final weekStart = now.subtract(const Duration(days: 7));

      // 🔥 CORRECTION: Utiliser les données utilisateur fraîches
      final userTotalEarnings = freshUser.totalEarnings;
      final userAvailableBalance = freshUser.availableBalance;
      final userPendingBalance = freshUser.pendingBalance;
      final userTotalClicks = freshUser.totalClicks;
      final userTotalShares = freshUser.totalShares;
      final userReferralCount = freshUser.referralCount;

      print('💰 User data - Earnings: $userTotalEarnings, Available: $userAvailableBalance, Pending: $userPendingBalance');

      // Calculer les statistiques hebdomadaires et mensuelles
      final monthlyStats = await _clickRepository.getUserStats(
        userId: user.id,
        startDate: monthStart,
        endDate: now,
      );

      final weeklyStats = await _clickRepository.getUserStats(
        userId: user.id,
        startDate: weekStart,
        endDate: now,
      );

      // Compter les retraits
      final withdrawalCount = _transactions
          .where((t) => t.type == TransactionType.withdrawal && t.status == TransactionStatus.completed)
          .length;

      final totalWithdrawn = _transactions
          .where((t) => t.type == TransactionType.withdrawal && t.status == TransactionStatus.completed)
          .fold(0.0, (sum, t) => sum + t.amount);

      _stats = EarningsStats(
        // 🔥 CORRECTION: Utiliser les vraies valeurs utilisateur
        totalEarnings: userTotalEarnings,
        availableBalance: userAvailableBalance,
        pendingBalance: userPendingBalance,
        totalClicks: userTotalClicks,
        totalShares: userTotalShares,
        referralCount: userReferralCount,
        monthlyEarnings: monthlyStats.totalEarnings,
        weeklyEarnings: weeklyStats.totalEarnings,
        monthlyClicks: monthlyStats.totalClicks,
        weeklyClicks: weeklyStats.totalClicks,
        conversionRate: monthlyStats.conversionRate,
        averageEarningsPerClick: monthlyStats.averageEarnings,
        withdrawalCount: withdrawalCount,
        totalWithdrawn: totalWithdrawn,
      );

      print('✅ Earnings stats loaded successfully');
      print('📊 Stats - Total: ${_stats.totalEarnings}, Available: ${_stats.availableBalance}, Pending: ${_stats.pendingBalance}');

    } catch (e) {
      print('❌ Error loading earnings stats: $e');
      
      // 🔥 FALLBACK: Utiliser les données de base en cas d'erreur
      final user = _authProvider!.user!;
      _stats = EarningsStats(
        totalEarnings: user.totalEarnings,
        availableBalance: user.availableBalance,
        pendingBalance: user.pendingBalance,
        totalClicks: user.totalClicks,
        totalShares: user.totalShares,
        referralCount: user.referralCount,
        monthlyEarnings: 0.0,
        weeklyEarnings: 0.0,
        monthlyClicks: 0,
        weeklyClicks: 0,
        conversionRate: 0.0,
        averageEarningsPerClick: 0.0,
        withdrawalCount: 0,
        totalWithdrawn: 0.0,
      );
    }
  }

  /// Demander un retrait
  Future<void> requestWithdrawal({
    required double amount,
    required String paymentMethod,
    required String accountNumber,
    String? bankName,
    String? recipientName,
  }) async {
    if (_authProvider?.user == null) return;

    try {
      _setLoading(true);
      _clearError();

      final user = _authProvider!.user!;

      // Vérifier le solde disponible
      if (user.availableBalance < amount) {
        _setError('الرصيد المتاح غير كافي للسحب');
        return;
      }

      // Vérifier le montant minimum de retrait
      if (amount < 10.0) { // 🔥 CORRECTION: 10 دينار حد أدنى
        _setError('الحد الأدنى للسحب هو 10 دينار');
        return;
      }

      // Préparer les détails de paiement
      final paymentDetails = {
        'accountNumber': accountNumber,
        'bankName': bankName,
        'recipientName': recipientName ?? user.displayName,
        'userId': user.id,
      };

      // Appeler Cloud Function pour créer le retrait
      final result = await _cloudFunctions.callFunction(
        'createWithdrawal',
        parameters: {
          'amount': amount,
          'paymentMethod': paymentMethod,
          'paymentDetails': paymentDetails,
        },
      );

      if (result['success'] == true) {
        // Recharger les données
        await loadEarningsData();

        // Envoyer une notification de succès
        await _cloudFunctions.callFunction('sendUserNotification', parameters: {
          'userId': user.id,
          'title': 'تم تقديم طلب السحب بنجاح! ✅',
          'body': 'جاري معالجة طلب سحب ${amount.toStringAsFixed(3)} دينار',
          'type': 'withdrawal_requested',
        });
      } else {
        throw Exception(result['error'] ?? 'فشل في طلب السحب');
      }

    } catch (e) {
      print('❌ Error requesting withdrawal: $e');
      _setError('فشل في طلب السحب: $e');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Filtrer les transactions par plage de dates
  Future<void> filterTransactionsByDate(DateTimeRange range) async {
    try {
      _setLoading(true);
      _dateRange = range;

      final user = _authProvider!.user!;
      _transactions = await _transactionRepository.getUserTransactionsByDate(
        userId: user.id,
        startDate: range.start,
        endDate: range.end,
      );

      print('✅ Filtered ${_transactions.length} transactions by date');

    } catch (e) {
      print('❌ Error filtering transactions by date: $e');
      _setError('فشل في تصفية المعاملات: $e');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Filtrer les transactions par type
  Future<void> filterTransactionsByType(TransactionType? type) async {
    try {
      _setLoading(true);
      _filterType = type;

      final user = _authProvider!.user!;
      
      if (type == null) {
        _transactions = await _transactionRepository.getUserTransactions(
          userId: user.id,
          limit: 50,
        );
      } else {
        _transactions = await _transactionRepository.getUserTransactionsByType(
          userId: user.id,
          type: type,
        );
      }

      print('✅ Filtered ${_transactions.length} transactions by type: $type');

    } catch (e) {
      print('❌ Error filtering transactions by type: $e');
      _setError('فشل في تصفية المعاملات: $e');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Obtenir le résumé des gains quotidiens
  Future<DailyEarningsSummary> getDailyEarningsSummary() async {
    if (_authProvider?.user == null) return DailyEarningsSummary();

    try {
      final user = _authProvider!.user!;
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));

      final todayStats = await _clickRepository.getUserStats(
        userId: user.id,
        startDate: DateTime(today.year, today.month, today.day),
        endDate: today,
      );

      final yesterdayStats = await _clickRepository.getUserStats(
        userId: user.id,
        startDate: DateTime(yesterday.year, yesterday.month, yesterday.day),
        endDate: yesterday,
      );

      final summary = DailyEarningsSummary(
        todayEarnings: todayStats.totalEarnings,
        yesterdayEarnings: yesterdayStats.totalEarnings,
        todayClicks: todayStats.totalClicks,
        yesterdayClicks: yesterdayStats.totalClicks,
      );

      print('✅ Daily earnings summary: Today ${summary.todayEarnings}, Yesterday ${summary.yesterdayEarnings}');

      return summary;

    } catch (e) {
      print('❌ Error getting daily earnings summary: $e');
      return DailyEarningsSummary();
    }
  }

  /// Obtenir l'historique des gains
  Future<List<RevenueHistory>> getRevenueHistory({int days = 30}) async {
    if (_authProvider?.user == null) return [];

    try {
      final result = await _cloudFunctions.callFunction('getRevenueHistory',
        parameters: {
          'userId': _authProvider!.user!.id,
          'days': days,
        }
      );

      if (result['success'] == true) {
        final historyData = List<Map<String, dynamic>>.from(result['history'] ?? []);
        final history = historyData.map((data) => RevenueHistory.fromMap(data)).toList();
        
        print('✅ Loaded ${history.length} days of revenue history');
        return history;
      }
      
      return [];
    } catch (e) {
      print('❌ Error getting revenue history: $e');
      return [];
    }
  }

  /// Calculer les frais de retrait
  double calculateWithdrawalFee(double amount) {
    // Frais fixes + pourcentage
    const double fixedFee = 1.0; // 1 دينار رسوم ثابتة
    const double percentageFee = 0.01; // 1% رسوم نسبية
    
    return fixedFee + (amount * percentageFee);
  }

  /// Vérifier l'éligibilité au retrait
  WithdrawalEligibility checkWithdrawalEligibility(double amount) {
    final user = _authProvider?.user;
    if (user == null) {
      return WithdrawalEligibility(
        isEligible: false,
        reason: 'يجب تسجيل الدخول أولاً',
      );
    }

    if (user.availableBalance < amount) {
      return WithdrawalEligibility(
        isEligible: false,
        reason: 'الرصيد المتاح غير كافي',
      );
    }

    if (amount < 10.0) { // 🔥 CORRECTION: 10 دينار حد أدنى
      return WithdrawalEligibility(
        isEligible: false,
        reason: 'الحد الأدنى للسحب هو 10 دينار',
      );
    }

    // Vérifier s'il y a des retraits en attente
    final pendingWithdrawals = _transactions
        .where((t) => t.type == TransactionType.withdrawal && 
              (t.status == TransactionStatus.pending || t.status == TransactionStatus.processing))
        .length;

    if (pendingWithdrawals > 0) {
      return WithdrawalEligibility(
        isEligible: false,
        reason: 'يوجد طلبات سحب قيد المعالجة',
      );
    }

    return WithdrawalEligibility(isEligible: true);
  }

  /// Démarrer les mises à jour en temps réel
void _startRealTimeUpdates() {
  final user = _authProvider!.user;
  if (user == null) return;

  print('🔔 Starting real-time earnings updates for user: ${user.id}');

  // 🔹 Écouter les nouvelles transactions (sans orderBy)
  FirebaseFirestore.instance
      .collection('transactions')
      .where('userId', isEqualTo: user.id)
      .snapshots()
      .listen((snapshot) {
    _transactions = snapshot.docs
        .map((doc) => TransactionModel.fromMap({
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            }))
        .toList()
      ..sort((a, b) {
        final aDate = a.createdAt ?? DateTime(0);
        final bDate = b.createdAt ?? DateTime(0);
        return bDate.compareTo(aDate);
      });

    // Limite locale (au lieu de Firestore)
    if (_transactions.length > 50) {
      _transactions = _transactions.take(50).toList();
    }

    print('🔄 Updated transactions: ${_transactions.length} items');
    notifyListeners();
  });

  // 🔹 Écouter les mises à jour du profil utilisateur
  FirebaseFirestore.instance
      .collection('users')
      .doc(user.id)
      .snapshots()
      .listen((snapshot) {
    if (snapshot.exists) {
      final userData = snapshot.data() as Map<String, dynamic>;

      _stats = _stats.copyWith(
        totalEarnings: (userData['totalEarnings'] ?? 0).toDouble(),
        availableBalance: (userData['availableBalance'] ?? 0).toDouble(),
        pendingBalance: (userData['pendingBalance'] ?? 0).toDouble(),
        totalClicks: (userData['totalClicks'] ?? 0).toInt(),
        totalShares: (userData['totalShares'] ?? 0).toInt(),
        referralCount: (userData['referralCount'] ?? 0).toInt(),
      );

      print(
          '🔄 Updated user stats - Available: ${_stats.availableBalance}, Pending: ${_stats.pendingBalance}');
      notifyListeners();
    }
  });

  // 🔹 Écouter les nouveaux clics (sans orderBy)
  FirebaseFirestore.instance
      .collection('clicks')
      .where('userId', isEqualTo: user.id)
      .where('earnings', isGreaterThan: 0)
      .snapshots()
      .listen((snapshot) {
    _earningClicks = snapshot.docs
        .map((doc) => ClickModel.fromMap({
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            }))
        .toList()
      ..sort((a, b) {
        final aDate = a.clickedAt ?? DateTime(0);
        final bDate = b.clickedAt ?? DateTime(0);
        return bDate.compareTo(aDate);
      });

    if (_earningClicks.length > 20) {
      _earningClicks = _earningClicks.take(20).toList();
    }

    print('🔄 Updated earning clicks: ${_earningClicks.length} items');
    notifyListeners();
  });
}


  /// Actualiser les données de gains
  Future<void> refreshEarnings() async {
    print('🔄 Manually refreshing earnings data...');
    await loadEarningsData();
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
}

/// Statistiques de gains
class EarningsStats {
  final double totalEarnings;
  final double availableBalance;
  final double pendingBalance;
  final int totalClicks;
  final int totalShares;
  final int referralCount;
  final double monthlyEarnings;
  final double weeklyEarnings;
  final int monthlyClicks;
  final int weeklyClicks;
  final double conversionRate;
  final double averageEarningsPerClick;
  final int withdrawalCount;
  final double totalWithdrawn;

  EarningsStats({
    this.totalEarnings = 0.0,
    this.availableBalance = 0.0,
    this.pendingBalance = 0.0,
    this.totalClicks = 0,
    this.totalShares = 0,
    this.referralCount = 0,
    this.monthlyEarnings = 0.0,
    this.weeklyEarnings = 0.0,
    this.monthlyClicks = 0,
    this.weeklyClicks = 0,
    this.conversionRate = 0.0,
    this.averageEarningsPerClick = 0.0,
    this.withdrawalCount = 0,
    this.totalWithdrawn = 0.0,
  });

  /// Méthode copyWith
  EarningsStats copyWith({
    double? totalEarnings,
    double? availableBalance,
    double? pendingBalance,
    int? totalClicks,
    int? totalShares,
    int? referralCount,
    double? monthlyEarnings,
    double? weeklyEarnings,
    int? monthlyClicks,
    int? weeklyClicks,
    double? conversionRate,
    double? averageEarningsPerClick,
    int? withdrawalCount,
    double? totalWithdrawn,
  }) {
    return EarningsStats(
      totalEarnings: totalEarnings ?? this.totalEarnings,
      availableBalance: availableBalance ?? this.availableBalance,
      pendingBalance: pendingBalance ?? this.pendingBalance,
      totalClicks: totalClicks ?? this.totalClicks,
      totalShares: totalShares ?? this.totalShares,
      referralCount: referralCount ?? this.referralCount,
      monthlyEarnings: monthlyEarnings ?? this.monthlyEarnings,
      weeklyEarnings: weeklyEarnings ?? this.weeklyEarnings,
      monthlyClicks: monthlyClicks ?? this.monthlyClicks,
      weeklyClicks: weeklyClicks ?? this.weeklyClicks,
      conversionRate: conversionRate ?? this.conversionRate,
      averageEarningsPerClick: averageEarningsPerClick ?? this.averageEarningsPerClick,
      withdrawalCount: withdrawalCount ?? this.withdrawalCount,
      totalWithdrawn: totalWithdrawn ?? this.totalWithdrawn,
    );
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

  /// Revenu quotidien moyen
  double get dailyAverageEarnings {
    return weeklyEarnings / 7;
  }

  /// Taux de clics quotidien moyen
  double get dailyAverageClicks {
    return weeklyClicks / 7;
  }

  /// Pourcentage du solde disponible
  double get availableBalancePercentage {
    if (totalEarnings == 0) return 0.0;
    return (availableBalance / totalEarnings) * 100;
  }

  /// Pourcentage du solde en attente
  double get pendingBalancePercentage {
    if (totalEarnings == 0) return 0.0;
    return (pendingBalance / totalEarnings) * 100;
  }
}

/// Résumé des gains quotidiens
class DailyEarningsSummary {
  final double todayEarnings;
  final double yesterdayEarnings;
  final int todayClicks;
  final int yesterdayClicks;

  DailyEarningsSummary({
    this.todayEarnings = 0.0,
    this.yesterdayEarnings = 0.0,
    this.todayClicks = 0,
    this.yesterdayClicks = 0,
  });

  /// Variation des gains
  double get earningsChange {
    if (yesterdayEarnings == 0) return todayEarnings > 0 ? 100.0 : 0.0;
    return ((todayEarnings - yesterdayEarnings) / yesterdayEarnings) * 100;
  }

  /// Variation des clics
  double get clicksChange {
    if (yesterdayClicks == 0) return todayClicks > 0 ? 100.0 : 0.0;
    return ((todayClicks - yesterdayClicks) / yesterdayClicks) * 100;
  }

  /// Indicateur de performance
  bool get isPositiveGrowth {
    return earningsChange >= 0 && clicksChange >= 0;
  }
}

/// Historique des revenus
class RevenueHistory {
  final DateTime date;
  final double earnings;
  final int clicks;
  final int validClicks;
  final int invalidClicks;

  RevenueHistory({
    required this.date,
    required this.earnings,
    required this.clicks,
    required this.validClicks,
    required this.invalidClicks,
  });

  factory RevenueHistory.fromMap(Map<String, dynamic> map) {
    return RevenueHistory(
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      earnings: (map['earnings'] ?? 0).toDouble(),
      clicks: map['clicks'] ?? 0,
      validClicks: map['validClicks'] ?? 0,
      invalidClicks: map['invalidClicks'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date.millisecondsSinceEpoch,
      'earnings': earnings,
      'clicks': clicks,
      'validClicks': validClicks,
      'invalidClicks': invalidClicks,
    };
  }

  /// Taux de conversion
  double get conversionRate {
    if (clicks == 0) return 0.0;
    return (validClicks / clicks) * 100;
  }

  /// Revenu moyen par clic
  double get averageEarningsPerClick {
    if (validClicks == 0) return 0.0;
    return earnings / validClicks;
  }
}

/// Éligibilité au retrait
class WithdrawalEligibility {
  final bool isEligible;
  final String? reason;

  WithdrawalEligibility({
    required this.isEligible,
    this.reason,
  });
}