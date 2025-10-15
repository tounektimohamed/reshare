import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../data/models/referral_model.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/repositories/referral_repository.dart';
import '../../../../data/repositories/user_repository.dart';
import '../../../../core/services/cloud_functions_service.dart';
import '../../../../core/services/share_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ReferralProvider with ChangeNotifier {
  final ReferralRepository _referralRepository = ReferralRepository();
  final UserRepository _userRepository = UserRepository();
  final CloudFunctionsService _cloudFunctions = CloudFunctionsService();
  final ShareService _shareService = ShareService();

  AuthProvider? _authProvider;

  // État du provider
  List<ReferralModel> _referrals = [];
  List<ReferralModel> _activeReferrals = [];
  List<ReferralModel> _completedReferrals = [];
  ReferralStats _stats = ReferralStats();
  bool _isLoading = false;
  String? _error;
  String? _shareMessage;

  // Getters
  List<ReferralModel> get referrals => _referrals;
  List<ReferralModel> get activeReferrals => _activeReferrals;
  List<ReferralModel> get completedReferrals => _completedReferrals;
  ReferralStats get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get shareMessage => _shareMessage;

  /// Mettre à jour le provider d'authentification
  void updateAuth(AuthProvider authProvider) {
    _authProvider = authProvider;
    if (authProvider.isAuthenticated && authProvider.user != null) {
      loadReferralData();
      _startRealTimeUpdates();
    }
  }
int get invalidReferralsCount {
    return _referrals.where((referral) => 
      referral.status == ReferralStatus.expired || 
      referral.status == ReferralStatus.cancelled
    ).length;
  }

  /// Obtenir le nombre de parrainages en attente de validation
  int get pendingValidationCount {
    return _referrals.where((referral) => 
      referral.status == ReferralStatus.pending
    ).length;
  }

  /// Obtenir les statistiques détaillées des parrainages
  Map<String, int> get referralStatusCounts {
    return {
      'total': _referrals.length,
      'completed': _referrals.where((r) => 
        r.status == ReferralStatus.completed || r.status == ReferralStatus.paid
      ).length,
      'pending': pendingValidationCount,
      'invalid': invalidReferralsCount,
    };
  }
Future<void> _syncReferralCount() async {
    if (_authProvider?.user == null) return;

    try {
      final user = _authProvider!.user!;
      final totalReferrals = _referrals.length;
      
      // Mettre à jour le count dans Firestore seulement si différent
      if (user.referralCount != totalReferrals) {
        await _userRepository.updateUserReferralCount(
          userId: user.id, 
          newCount: totalReferrals
        );
        
        // Mettre à jour le user local dans AuthProvider
        _authProvider!.refreshUserData();
      }
    } catch (e) {
      print('Erreur synchronisation referral count: $e');
    }
  }

  /// Charger les données de parrainage
  Future<void> loadReferralData() async {
    if (_authProvider?.user == null) return;

    try {
      _setLoading(true);
      _clearError();

      await Future.wait([
        _loadReferrals(),
        _loadReferralStats(),
      ]);

      _categorizeReferrals();

    } catch (e) {
      _setError('فشل في تحميل بيانات الإحالة: $e');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Charger la liste des parrainages
  Future<void> _loadReferrals() async {
    try {
      final user = _authProvider!.user!;
      _referrals = await _referralRepository.getUserReferrals(user.id);
    } catch (e) {
      throw Exception('فشل في تحميل الإحالات: $e');
    }
  }

  /// Charger les statistiques de parrainage
   Future<void> _loadReferralStats() async {
    try {
      final user = _authProvider!.user!;
      
      final completedReferrals = _referrals.where((r) => 
        r.status == ReferralStatus.completed || r.status == ReferralStatus.paid
      ).length;

      final pendingReferrals = _referrals.where((r) => 
        r.status == ReferralStatus.pending
      ).length;

      final totalEarnings = _referrals.where((r) => 
        r.status == ReferralStatus.paid
      ).fold(0.0, (sum, r) => sum + r.rewardAmount);

      // Synchroniser le count
      await _syncReferralCount();

      // Obtenir le count actualisé depuis l'utilisateur
      final updatedUser = _authProvider!.user!;
      
      _stats = ReferralStats(
        totalReferrals: updatedUser.referralCount, // Utiliser le count synchronisé
        completedReferrals: completedReferrals,
        pendingReferrals: pendingReferrals,
        totalEarnings: totalEarnings,
        potentialEarnings: 0.0, // À calculer selon votre logique
        referralCode: user.referralCode ?? '',
        successRate: updatedUser.referralCount > 0 ? 
            (completedReferrals / updatedUser.referralCount) * 100 : 0.0,
        totalShares: 0, // À implémenter
        invitationsSent: 0, // À implémenter
      );

    } catch (e) {
      throw Exception('فشل في تحميل إحصائيات الإحالة: $e');
    }
  }

  /// Catégoriser les parrainages
  void _categorizeReferrals() {
    _activeReferrals = _referrals.where((referral) => 
      referral.status == ReferralStatus.pending
    ).toList();

    _completedReferrals = _referrals.where((referral) => 
      referral.status == ReferralStatus.completed || referral.status == ReferralStatus.paid
    ).toList();
  }

  /// Partager le lien de parrainage
  Future<void> shareReferralLink() async {
    if (_authProvider?.user == null) return;

    try {
      _setLoading(true);
      _clearError();

      final user = _authProvider!.user!;
      final referralCode = user.referralCode;

      if (referralCode == null || referralCode.isEmpty) {
        _setError('كود الإحالة غير متوفر');
        return;
      }

      // Générer le lien de parrainage
      final referralLink = 'https://reshare.tn/register?ref=$referralCode';

      // Partager le lien
      final shared = await _shareService.shareReferralLink(
        referralLink: referralLink,
        referralCode: referralCode,
      );

      if (shared) {
        // Enregistrer le partage du lien de parrainage
        await _referralRepository.recordReferralShare(
          userId: user.id,
          referralCode: referralCode,
        );

        // Recharger les statistiques pour mettre à jour le compteur
        await _loadReferralStats();

        // Définir le message de partage
        _shareMessage = 'تم مشاركة رابط الإحالة بنجاح! 🎉';

        // Envoyer une notification de succès
        await _cloudFunctions.sendUserNotification(
          userId: user.id,
          title: 'تمت المشاركة بنجاح! 📤',
          body: 'رابط الإحالة جاهز للمشاركة مع الأصدقاء',
          type: 'referral_shared',
        );
      }

    } catch (e) {
      _setError('فشل في مشاركة رابط الإحالة: $e');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Copier le lien de parrainage
  Future<void> copyReferralLink() async {
    if (_authProvider?.user == null) return;

    try {
      final user = _authProvider!.user!;
      final referralCode = user.referralCode;

      if (referralCode == null || referralCode.isEmpty) {
        _setError('كود الإحالة غير متوفر');
        return;
      }

      final referralLink = 'https://reshare.tn/register?ref=$referralCode';
      
      // Copier dans le presse-papiers
      // await Clipboard.setData(ClipboardData(text: referralLink));

      _shareMessage = 'تم نسخ رابط الإحالة إلى الحافظة! 📋';
      notifyListeners();

      // Effacer le message après 3 secondes
      Future.delayed(const Duration(seconds: 3), () {
        _shareMessage = null;
        notifyListeners();
      });

    } catch (e) {
      _setError('فشل في نسخ رابط الإحالة: $e');
    }
  }

  /// Envoyer une invitation de parrainage via les médias sociaux
  Future<void> sendReferralInvitation({
    required String platform,
    required String contactInfo,
  }) async {
    if (_authProvider?.user == null) return;

    try {
      _setLoading(true);
      _clearError();

      final user = _authProvider!.user!;
      final referralCode = user.referralCode;

      if (referralCode == null || referralCode.isEmpty) {
        _setError('كود الإحالة غير متوفر');
        return;
      }

      // Envoyer l'invitation via la plateforme spécifiée
      final sent = await _shareService.sendInvitation(
        platform: platform,
        contactInfo: contactInfo,
        referralCode: referralCode,
      );

      if (sent) {
        // Enregistrer l'envoi de l'invitation
        await _referralRepository.recordInvitationSent(
          userId: user.id,
          platform: platform,
          contactInfo: contactInfo,
        );

        // Recharger les statistiques pour mettre à jour le compteur
        await _loadReferralStats();

        _shareMessage = 'تم إرسال الدعوة بنجاح إلى $contactInfo! ✅';
      }

    } catch (e) {
      _setError('فشل في إرسال الدعوة: $e');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Obtenir les détails d'un parrainage spécifique
  Future<ReferralDetails> getReferralDetails(String referralId) async {
    try {
      final referral = _referrals.firstWhere((r) => r.id == referralId);
      final referredUser = await _userRepository.getUserById(referral.newUserId);

      // Obtenir les statistiques du utilisateur référé via Cloud Functions
      final result = await _cloudFunctions.callFunction('getReferredUserStats',
        parameters: {'userId': referral.newUserId}
      );

      int referredUserClicks = 0;
      double referredUserEarnings = 0.0;

      if (result['success'] == true) {
        final statsData = result['stats'];
        referredUserClicks = statsData['totalClicks'] ?? 0;
        referredUserEarnings = (statsData['totalEarnings'] ?? 0).toDouble();
      }

      return ReferralDetails(
        referral: referral,
        referredUser: referredUser,
        referredUserClicks: referredUserClicks,
        referredUserEarnings: referredUserEarnings,
      );
    } catch (e) {
      throw Exception('فشل في الحصول على تفاصيل الإحالة: $e');
    }
  }

  /// Traiter un nouveau parrainage
  Future<void> processNewReferral({
    required String newUserId,
    required String referralCode,
  }) async {
    if (_authProvider?.user == null) return;

    try {
      final user = _authProvider!.user!;

      // Appeler Cloud Function pour traiter le parrainage
      final result = await _cloudFunctions.processReferral(
        referrerId: user.id,
        newUserId: newUserId,
        referralCode: referralCode,
      );

      if (result['success'] == true) {
        // Recharger les données de parrainage
        await loadReferralData();

        // Envoyer une notification de bienvenue au parrain
        await _cloudFunctions.sendUserNotification(
          userId: user.id,
          title: 'إحالة جديدة! 🎊',
          body: 'لقد انضم صديق جديد عبر رابط الإحالة الخاص بك',
          type: 'new_referral',
        );
      }

    } catch (e) {
      print('فشل في معالجة الإحالة الجديدة: $e');
    }
  }

  /// Calculer les gains potentiels
  double calculatePotentialEarnings(int numberOfFriends) {
    const double baseReward = 0.6; // 0.6 دينار للمستوى الأول
    const double tier2Reward = 0.8; // 0.8 دينار للمستوى الثاني
    const double tier3Reward = 1.0; // 1.0 دينار للمستوى الثالث
    
    if (numberOfFriends <= 10) {
      return numberOfFriends * baseReward;
    } else if (numberOfFriends <= 20) {
      return (10 * baseReward) + ((numberOfFriends - 10) * tier2Reward);
    } else {
      return (10 * baseReward) + (10 * tier2Reward) + ((numberOfFriends - 20) * tier3Reward);
    }
  }

  /// Obtenir les récompenses de niveau
  List<ReferralTier> getReferralTiers() {
    return [
      ReferralTier(
        level: 1,
        name: 'المستوى الأول',
        friendsRequired: 0,
        rewardPerFriend: 0.6,
        description: '0.6 دينار لكل صديق حتى 10 أصدقاء',
      ),
      ReferralTier(
        level: 2,
        name: 'المستوى الثاني',
        friendsRequired: 10,
        rewardPerFriend: 0.8,
        description: '0.8 دينار لكل صديق من 11 إلى 20 صديق',
      ),
      ReferralTier(
        level: 3,
        name: 'المستوى الثالث',
        friendsRequired: 20,
        rewardPerFriend: 1.0,
        description: '1.0 دينار لكل صديق بعد 20 صديق',
      ),
    ];
  }

  /// Obtenir le niveau actuel de l'utilisateur
  ReferralTier getCurrentTier() {
    final completedCount = _stats.completedReferrals;
    final tiers = getReferralTiers();

    for (int i = tiers.length - 1; i >= 0; i--) {
      if (completedCount >= tiers[i].friendsRequired) {
        return tiers[i];
      }
    }

    return tiers.first;
  }

  /// Obtenir la progression vers le niveau suivant
  TierProgress getTierProgress() {
    final currentTier = getCurrentTier();
    final nextTierIndex = currentTier.level;
    final tiers = getReferralTiers();

    if (nextTierIndex >= tiers.length) {
      return TierProgress(
        currentTier: currentTier,
        nextTier: null,
        progress: 100.0,
        friendsNeeded: 0,
      );
    }

    final nextTier = tiers[nextTierIndex];
    final completedCount = _stats.completedReferrals;
    final friendsNeeded = nextTier.friendsRequired - completedCount;
    final progress = ((completedCount - currentTier.friendsRequired) / 
        (nextTier.friendsRequired - currentTier.friendsRequired)) * 100;

    return TierProgress(
      currentTier: currentTier,
      nextTier: nextTier,
      progress: progress.clamp(0.0, 100.0),
      friendsNeeded: friendsNeeded,
    );
  }

  /// Démarrer les mises à jour en temps réel
 void _startRealTimeUpdates() {
  final user = _authProvider!.user;
  if (user == null) return;

  // 🔹 Écouter les nouvelles références de l'utilisateur
  FirebaseFirestore.instance
      .collection('referrals')
      .where('referrerId', isEqualTo: user.id)
      .snapshots()
      .listen((snapshot) {
    _referrals = snapshot.docs
        .map((doc) => ReferralModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();

    // Tri local par date (plus récentes d'abord)
    _referrals.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Mise à jour des catégories et statistiques
    _categorizeReferrals();
    _loadReferralStats();

    notifyListeners();
  });
}


  /// Actualiser les données de parrainage
  Future<void> refreshReferrals() async {
    await loadReferralData();
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

/// Statistiques de parrainage
class ReferralStats {
  final int totalReferrals;
  final int completedReferrals;
  final int pendingReferrals;
  final double totalEarnings;
  final double potentialEarnings;
  final String referralCode;
  final double successRate;
  final int totalShares;
  final int invitationsSent;

  ReferralStats({
    this.totalReferrals = 0,
    this.completedReferrals = 0,
    this.pendingReferrals = 0,
    this.totalEarnings = 0.0,
    this.potentialEarnings = 0.0,
    this.referralCode = '',
    this.successRate = 0.0,
    this.totalShares = 0,
    this.invitationsSent = 0,
  });

  /// Gains moyens par parrainage
  double get averageEarningsPerReferral {
    if (completedReferrals == 0) return 0.0;
    return totalEarnings / completedReferrals;
  }

  /// Taux de conversion
  double get conversionRate {
    if (totalReferrals == 0) return 0.0;
    return (completedReferrals / totalReferrals) * 100;
  }

  /// Créer une copie avec des valeurs mises à jour
  ReferralStats copyWith({
    int? totalReferrals,
    int? completedReferrals,
    int? pendingReferrals,
    double? totalEarnings,
    double? potentialEarnings,
    String? referralCode,
    double? successRate,
    int? totalShares,
    int? invitationsSent,
  }) {
    return ReferralStats(
      totalReferrals: totalReferrals ?? this.totalReferrals,
      completedReferrals: completedReferrals ?? this.completedReferrals,
      pendingReferrals: pendingReferrals ?? this.pendingReferrals,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      potentialEarnings: potentialEarnings ?? this.potentialEarnings,
      referralCode: referralCode ?? this.referralCode,
      successRate: successRate ?? this.successRate,
      totalShares: totalShares ?? this.totalShares,
      invitationsSent: invitationsSent ?? this.invitationsSent,
    );
  }
}

/// Détails du parrainage
class ReferralDetails {
  final ReferralModel referral;
  final UserModel? referredUser;
  final int referredUserClicks;
  final double referredUserEarnings;

  ReferralDetails({
    required this.referral,
    this.referredUser,
    this.referredUserClicks = 0,
    this.referredUserEarnings = 0.0,
  });

  /// Obtenir le statut du parrainage sous forme de texte
  String get statusText {
    switch (referral.status) {
      case ReferralStatus.pending:
        return 'قيد الانتظار (${referral.remainingClicks} نقرات متبقية)';
      case ReferralStatus.completed:
        return 'مكتمل - في انتظار الدفع';
      case ReferralStatus.paid:
        return 'تم الدفع';
      case ReferralStatus.expired:
        return 'منتهي الصلاحية';
      case ReferralStatus.cancelled:
        return 'ملغى';
    }
  }
}

/// Niveau de parrainage
class ReferralTier {
  final int level;
  final String name;
  final int friendsRequired;
  final double rewardPerFriend;
  final String description;

  ReferralTier({
    required this.level,
    required this.name,
    required this.friendsRequired,
    required this.rewardPerFriend,
    required this.description,
  });
}

/// Progression vers le niveau suivant
class TierProgress {
  final ReferralTier currentTier;
  final ReferralTier? nextTier;
  final double progress;
  final int friendsNeeded;

  TierProgress({
    required this.currentTier,
    this.nextTier,
    required this.progress,
    required this.friendsNeeded,
  });
}