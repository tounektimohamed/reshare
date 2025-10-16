import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/services/cloud_functions_service.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/repositories/user_repository.dart';

class AuthProvider with ChangeNotifier {
 final FirebaseService _firebaseService = FirebaseService();
  final CloudFunctionsService _cloudFunctions = CloudFunctionsService();
  final UserRepository _userRepository = UserRepository();

  UserModel? _user;
  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _error;
  AuthStatus _authStatus = AuthStatus.checking;

  // Getters
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get error => _error;
  AuthStatus get authStatus => _authStatus;

  // Vérifier les permissions par rôle
  bool get isAdmin => _user?.userType == UserType.admin;
  bool get isBusiness => _user?.userType == UserType.business;
  bool get isParticipant => _user?.userType == UserType.participant;

  /// 🔥 VÉRIFIER L'ÉTAT D'AUTHENTIFICATION AU DÉMARRAGE
  Future<void> checkAuthStatus() async {
    try {
      _setLoading(true);
      _authStatus = AuthStatus.checking;
      _clearError();

      print('🔍 Checking authentication status...');

      final currentUser = _firebaseService.currentUser;
      
      if (currentUser != null) {
        print('✅ User is authenticated: ${currentUser.uid}');
        await _loadUserData(currentUser.uid);
        _isAuthenticated = true;
        _authStatus = AuthStatus.authenticated;
        
        // Mettre à jour la dernière connexion
        await _userRepository.updateLastLogin(currentUser.uid);
      } else {
        print('❌ No authenticated user found');
        _isAuthenticated = false;
        _authStatus = AuthStatus.unauthenticated;
      }
    } catch (e) {
      print('❌ Error checking auth status: $e');
      _setError('Échec de la vérification de l\'authentification: $e');
      _authStatus = AuthStatus.error;
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }
  /// 🔥 CONNEXION AVEC EMAIL ET MOT DE PASSE
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      print('🔐 Attempting login for: $email');

      final userCredential = await _firebaseService.auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (userCredential.user != null) {
        print('✅ Login successful: ${userCredential.user!.uid}');
        await _loadUserData(userCredential.user!.uid);
        _isAuthenticated = true;
        _authStatus = AuthStatus.authenticated;
        
        // Mettre à jour la dernière connexion
        await _userRepository.updateLastLogin(userCredential.user!.uid);
        
        return true;
      }
      
      return false;
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase auth error: ${e.code}');
      _handleAuthError(e);
      return false;
    } catch (e) {
      print('❌ Unexpected login error: $e');
      _setError('Erreur inattendue lors de la connexion: $e');
      return false;
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// 🔥 CRÉER UN NOUVEAU COMPTE
  Future<bool> register({
    required String email,
    required String password,
    required String displayName,
    String? phoneNumber,
    String? referralCode,
    UserType userType = UserType.participant,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      print('👤 Creating account for: $email');

      // 1. Créer l'utilisateur dans Firebase Auth
      final userCredential = await _firebaseService.auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (userCredential.user != null) {
        print('✅ Firebase auth user created: ${userCredential.user!.uid}');

        // 2. Créer le profil utilisateur dans Firestore
        final newUser = await _userRepository.createDefaultUserProfile(
          userId: userCredential.user!.uid,
          email: email.trim(),
          displayName: displayName.trim(),
          userType: userType,
        );

        // 3. Mettre à jour les données locales
        _user = newUser;
        _isAuthenticated = true;
        _authStatus = AuthStatus.authenticated;

        // 4. Traiter le code de parrainage si fourni
        if (referralCode != null && referralCode.isNotEmpty) {
          await _processReferral(referralCode, newUser.id);
        }

        // 5. Envoyer l'email de vérification
        await _firebaseService.sendEmailVerification();

        // 6. Envoyer une notification de bienvenue
        await _sendWelcomeNotification(userType, newUser.id, displayName);

        print('🎉 Account creation completed successfully');
        return true;
      }
      
      return false;
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase auth error during registration: ${e.code}');
      _handleAuthError(e);
      return false;
    } catch (e) {
      print('❌ Unexpected registration error: $e');
      _setError('Erreur inattendue lors de la création du compte: $e');
      return false;
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// 🔥 ENVOYER UN EMAIL DE RÉINITIALISATION DE MOT DE PASSE
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      _setLoading(true);
      _clearError();

      print('📧 Sending password reset email to: $email');

      // Vérifications de base
      if (email.isEmpty) {
        _setError('يرجى إدخال البريد الإلكتروني');
        return false;
      }

      if (!email.contains('@')) {
        _setError('يرجى إدخال بريد إلكتروني صحيح');
        return false;
      }

      // Envoyer l'email de réinitialisation
      await _firebaseService.resetPassword(email.trim());

      // Envoyer une notification de succès si l'utilisateur est connecté
      if (_user != null) {
        await _cloudFunctions.callFunction('sendUserNotification', parameters: {
          'userId': _user!.id,
          'title': 'تم إرسال رابط إعادة التعيين',
          'body': 'تحقق من بريدك الإلكتروني لإعادة تعيين كلمة المرور',
          'type': 'password_reset',
        });
      }

      print('✅ Password reset email sent successfully');
      return true;

    } on FirebaseAuthException catch (e) {
      print('❌ Firebase auth error during password reset: ${e.code}');
      _handleAuthError(e);
      return false;
    } catch (e) {
      print('❌ Unexpected password reset error: $e');
      _setError('حدث خطأ أثناء إرسال رابط إعادة التعيين: $e');
      return false;
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// 🔥 DÉCONNEXION
  Future<void> logout() async {
    try {
      _setLoading(true);
      _clearError();

      print('🚪 Logging out user...');

      await _firebaseService.signOut();
      
      // Réinitialiser l'état
      _user = null;
      _isAuthenticated = false;
      _authStatus = AuthStatus.unauthenticated;

      print('✅ Logout completed successfully');

    } catch (e) {
      print('❌ Error during logout: $e');
      _setError('Échec de la déconnexion: $e');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// 🔥 METTRE À JOUR LE PROFIL UTILISATEUR
  Future<bool> updateProfile({
    required String displayName,
    String? phoneNumber,
    String? companyName,
    String? taxNumber,
    LocationPreference? locationPreference,
    List<String>? preferredCategories,
  }) async {
    try {
      if (_user == null) {
        _setError('يجب تسجيل الدخول أولاً');
        return false;
      }

      _setLoading(true);
      _clearError();

      print('📝 Updating profile for: ${_user!.id}');

      // Créer une copie mise à jour de l'utilisateur
      final updatedUser = _user!.copyWith(
        displayName: displayName,
        phoneNumber: phoneNumber,
        companyName: companyName,
        taxNumber: taxNumber,
        locationPreference: locationPreference,
        preferredCategories: preferredCategories,
      );

      // Mettre à jour dans Firestore
      await _userRepository.updateUser(updatedUser);

      // Mettre à jour l'état local
      _user = updatedUser;

      // Envoyer une notification de succès
      await _cloudFunctions.callFunction('sendUserNotification', parameters: {
        'userId': _user!.id,
        'title': 'تم تحديث الملف الشخصي بنجاح! ✅',
        'body': 'تم حفظ التغييرات على ملفك الشخصي',
        'type': 'profile_updated',
      });

      print('✅ Profile updated successfully');
      return true;

    } catch (e) {
      print('❌ Error updating profile: $e');
      _setError('فشل في تحديث الملف الشخصي: $e');
      return false;
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// 🔥 METTRE À JOUR LE MOT DE PASSE
  Future<bool> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final user = _firebaseService.currentUser;
      if (user == null) {
        _setError('يجب تسجيل الدخول أولاً');
        return false;
      }

      print('🔒 Updating password for: ${user.uid}');

      // Réauthentifier l'utilisateur avec le mot de passe actuel
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      
      // Mettre à jour le mot de passe
      await user.updatePassword(newPassword);

      // Envoyer une notification de succès
      await _cloudFunctions.callFunction('sendUserNotification', parameters: {
        'userId': user.uid,
        'title': 'تم تحديث كلمة المرور بنجاح! 🔒',
        'body': 'تم تغيير كلمة المرور الخاصة بحسابك',
        'type': 'password_updated',
      });

      print('✅ Password updated successfully');
      return true;

    } on FirebaseAuthException catch (e) {
      print('❌ Firebase auth error during password update: ${e.code}');
      _handleAuthError(e);
      return false;
    } catch (e) {
      print('❌ Unexpected password update error: $e');
      _setError('فشل في تحديث كلمة المرور: $e');
      return false;
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// 🔥 VÉRIFIER L'EMAIL
  Future<bool> verifyEmail() async {
    try {
      _setLoading(true);
      _clearError();

      print('📧 Sending email verification...');

      await _firebaseService.sendEmailVerification();

      print('✅ Email verification sent successfully');
      return true;

    } catch (e) {
      print('❌ Error sending email verification: $e');
      _setError('فشل في إرسال رابط التحقق: $e');
      return false;
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// 🔥 METTRE À JOUR LE TYPE D'UTILISATEUR
  Future<bool> upgradeToBusiness({
    required String companyName,
    required String taxNumber,
    String? phoneNumber,
  }) async {
    try {
      if (_user == null) {
        _setError('يجب تسجيل الدخول أولاً');
        return false;
      }

      _setLoading(true);
      _clearError();

      print('🏢 Upgrading user to business: ${_user!.id}');

      // Mettre à jour le type d'utilisateur
      await _userRepository.updateUserType(
        userId: _user!.id,
        userType: UserType.business,
      );

      // Mettre à jour les informations d'entreprise
      final updatedUser = _user!.copyWith(
        userType: UserType.business,
        companyName: companyName,
        taxNumber: taxNumber,
        phoneNumber: phoneNumber ?? _user!.phoneNumber,
      );

      await _userRepository.updateUser(updatedUser);
      _user = updatedUser;

      // Envoyer une notification de succès
      await _cloudFunctions.callFunction('sendUserNotification', parameters: {
        'userId': _user!.id,
        'title': 'تم الترقية إلى حساب شركة! 🏢',
        'body': 'يمكنك الآن إنشاء حملات إعلانية',
        'type': 'account_upgraded',
      });

      print('✅ User upgraded to business successfully');
      return true;

    } catch (e) {
      print('❌ Error upgrading to business: $e');
      _setError('فشل في الترقية إلى حساب شركة: $e');
      return false;
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// 🔥 CHARGER LES DONNÉES UTILISATEUR
  Future<void> _loadUserData(String userId) async {
    try {
      print('🔄 Loading user data for: $userId');
      
      final userData = await _userRepository.getUserById(userId);
      
      if (userData != null) {
        print('✅ User data loaded successfully: ${userData.displayName}');
        _user = userData;
      } else {
        print('❌ User data not found, creating default profile...');
        // Créer un profil par défaut
        final currentUser = _firebaseService.currentUser;
        if (currentUser != null) {
          final defaultUser = await _userRepository.createDefaultUserProfile(
            userId: userId,
            email: currentUser.email ?? '',
            displayName: currentUser.displayName ?? 'مستخدم جديد',
          );
          _user = defaultUser;
        }
      }
    } catch (e) {
      print('❌ Error loading user data: $e');
      
      // Tenter de réparer les données corrompues
      try {
        await _userRepository.repairUserData(userId);
        await _loadUserData(userId); // Réessayer
      } catch (repairError) {
        throw Exception('فشل في جلب بيانات المستخدم : $e');
      }
    }
  }

  /// 🔥 TRAITER LE PARRAINAGE
  Future<void> _processReferral(String referralCode, String newUserId) async {
    try {
      print('🤝 Processing referral: $referralCode for new user: $newUserId');

      final referrer = await _userRepository.getUserByReferralCode(referralCode);
      if (referrer != null) {
        await _cloudFunctions.callFunction('processReferral', parameters: {
          'referrerId': referrer.id,
          'newUserId': newUserId,
          'referralCode': referralCode,
        });

        // Augmenter le compteur de références du parraineur
        await _userRepository.incrementUserReferrals(referrer.id);

        await _cloudFunctions.callFunction('sendUserNotification', parameters: {
          'userId': referrer.id,
          'title': 'Nouveau parrainage! 🎊',
          'body': 'Un nouvel ami a rejoint via votre lien de parrainage',
          'type': 'new_referral',
        });

        print('✅ Referral processed successfully');
      } else {
        print('⚠️ Referrer not found for code: $referralCode');
      }
    } catch (e) {
      print('❌ Error processing referral: $e');
      // Ne pas propager l'erreur pour ne pas bloquer l'inscription
    }
  }

  /// 🔥 ENVOYER UNE NOTIFICATION DE BIENVENUE
  Future<void> _sendWelcomeNotification(
    UserType userType, 
    String userId, 
    String displayName
  ) async {
    try {
      String welcomeTitle;
      String welcomeBody;

      switch (userType) {
        case UserType.business:
          welcomeTitle = 'Bienvenue entreprise! 🏢';
          welcomeBody = 'Créez et gérez vos campagnes publicitaires sur ReShare';
          break;
        case UserType.admin:
          welcomeTitle = 'Bienvenue administrateur! 🔧';
          welcomeBody = 'Gérez la plateforme ReShare';
          break;
        case UserType.participant:
        default:
          welcomeTitle = 'Bienvenue sur ReShare! 🎉';
          welcomeBody = 'Commencez à gagner de l\'argent en partageant des campagnes';
      }

      await _cloudFunctions.callFunction('sendUserNotification', parameters: {
        'userId': userId,
        'title': welcomeTitle,
        'body': welcomeBody,
        'type': 'welcome',
        'data': {
          'displayName': displayName,
          'userType': userType.name,
        },
      });

      print('✅ Welcome notification sent');
    } catch (e) {
      print('❌ Error sending welcome notification: $e');
      // Ne pas propager l'erreur
    }
  }

  /// 🔥 GÉRER LES ERREURS D'AUTHENTIFICATION
  void _handleAuthError(FirebaseAuthException e) {
    print('🔐 Auth error: ${e.code} - ${e.message}');
    
    switch (e.code) {
      case 'user-not-found':
        _setError('البريد الإلكتروني غير مسجل');
        break;
      case 'wrong-password':
        _setError('كلمة المرور غير صحيحة');
        break;
      case 'email-already-in-use':
        _setError('البريد الإلكتروني مستخدم بالفعل');
        break;
      case 'weak-password':
        _setError('كلمة المرور ضعيفة، يجب أن تكون 6 أحرف على الأقل');
        break;
      case 'invalid-email':
        _setError('بريد إلكتروني غير صحيح');
        break;
      case 'user-disabled':
        _setError('تم تعطيل هذا الحساب');
        break;
      case 'too-many-requests':
        _setError('محاولات تسجيل دخول كثيرة، حاول مرة أخرى لاحقاً');
        break;
      case 'network-request-failed':
        _setError('خطأ في الاتصال بالإنترنت');
        break;
      case 'requires-recent-login':
        _setError('يجب تسجيل الدخول مرة أخرى لإكمال هذه العملية');
        break;
      case 'invalid-credential':
        _setError('بيانات الاعتماد غير صالحة');
        break;
      case 'invalid-verification-code':
        _setError('رمز التحقق غير صالح');
        break;
      case 'invalid-verification-id':
        _setError('معرف التحقق غير صالح');
        break;
      default:
        _setError('حدث خطأ أثناء المصادقة: ${e.message}');
    }
  }

  /// ACTUALISER LES DONNÉES UTILISATEUR
  Future<void> refreshUserData() async {
    if (_user != null) {
      try {
        print('🔄 Refreshing user data...');
        await _loadUserData(_user!.id);
        notifyListeners();
        print('✅ User data refreshed successfully');
      } catch (e) {
        print('❌ Error refreshing user data: $e');
      }
    }
  }

  /// VÉRIFIER LES PERMISSIONS D'ACCÈS
  bool hasPermission(List<UserType> allowedTypes) {
    return _user != null && allowedTypes.contains(_user!.userType);
  }

  /// VÉRIFIER L'ACCÈS AUX FONCTIONNALITÉS ADMIN
  bool canAccessAdminFeatures() {
    return _user?.userType == UserType.admin;
  }

  /// VÉRIFIER L'ACCÈS AUX FONCTIONNALITÉS BUSINESS
  bool canAccessBusinessFeatures() {
    return _user?.userType == UserType.business || _user?.userType == UserType.admin;
  }

  /// MÉTHODES UTILITAIRES POUR LA GESTION D'ÉTAT
  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading) _clearError();
  }

  void _setError(String error) {
    _error = error;
    _authStatus = AuthStatus.error;
  }

  void _clearError() {
    _error = null;
  }

  /// NETTOYER LES RESSOURCES
  void disposeProvider() {
    _user = null;
    _isAuthenticated = false;
    _authStatus = AuthStatus.unauthenticated;
    _error = null;
  }
}

/// ÉTATS D'AUTHENTIFICATION
enum AuthStatus {
  checking,        // Vérification en cours
  authenticated,   // Connecté
  unauthenticated, // Non connecté
  error,           // Erreur
}