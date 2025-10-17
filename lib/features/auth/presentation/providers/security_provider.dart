// lib/features/security/presentation/providers/security_provider.dart
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

import '../../../../core/services/pin_service.dart';

class SecurityProvider with ChangeNotifier {
  final PinService _pinService = PinService();
  final LocalAuthentication _localAuth = LocalAuthentication();

  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _error;
  bool _useBiometric = false;
  String? _currentUserId; // Stocker l'ID utilisateur actuel

  // Getters
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get error => _error;
  bool get useBiometric => _useBiometric;
  bool get isUnlocked => _isAuthenticated;

  /// Définir l'utilisateur courant
  void setCurrentUser(String userId) {
    _currentUserId = userId;
    print('👤 SecurityProvider: User set to $userId');
  }

  /// Vérifier si le PIN est activé pour l'utilisateur courant
  Future<bool> isPinEnabled() async {
    if (_currentUserId == null) {
      print('⚠️ SecurityProvider: No current user set');
      return false;
    }
    return await _pinService.isPinEnabled(_currentUserId!);
  }

  /// Activer/désactiver le PIN pour l'utilisateur courant
  Future<bool> togglePin({required String pin, required bool enable}) async {
    if (_currentUserId == null) {
      _setError('Utilisateur non défini');
      return false;
    }

    try {
      _setLoading(true);
      _clearError();

      if (enable) {
        // Activer le PIN
        if (pin.length != 4) {
          _setError('Le PIN doit contenir 4 chiffres');
          return false;
        }

        final success = await _pinService.setPin(_currentUserId!, pin);
        if (success) {
          await _pinService.enablePin(_currentUserId!);
          print('✅ PIN enabled successfully for user: $_currentUserId');
          return true;
        } else {
          _setError('Erreur lors de l\'activation du PIN');
          return false;
        }
      } else {
        // Désactiver le PIN
        await _pinService.disablePin(_currentUserId!);
        await _pinService.disableBiometric(_currentUserId!);
        _useBiometric = false;
        print('✅ PIN disabled successfully for user: $_currentUserId');
        return true;
      }
    } catch (e) {
      print('❌ Error toggling PIN: $e');
      _setError('Erreur: $e');
      return false;
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Valider le PIN pour l'utilisateur courant
  Future<bool> validatePin(String pin) async {
    if (_currentUserId == null) return false;
    
    try {
      _setLoading(true);
      _clearError();

      final isValid = await _pinService.validatePin(_currentUserId!, pin);
      
      if (isValid) {
        _isAuthenticated = true;
        print('✅ PIN validation successful for user: $_currentUserId');
      } else {
        _setError('PIN incorrect');
      }

      return isValid;
    } catch (e) {
      print('❌ Error validating PIN: $e');
      _setError('Erreur de validation: $e');
      return false;
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// 🔓 Déverrouiller avec PIN
  Future<bool> unlockWithPin(String pin) async {
    return await validatePin(pin);
  }

  /// Vérifier si la biométrie est disponible - FALSE sur Web
  Future<bool> isBiometricAvailable() async {
    if (kIsWeb) {
      print('🌐 Web: Biometric not available');
      return false;
    }
    
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      print('❌ Error checking biometric availability: $e');
      return false;
    }
  }

  /// Authentification biométrique - DÉSACTIVÉE sur Web
  Future<bool> authenticateWithBiometric() async {
    if (kIsWeb) {
      _setError('المصادقة البيومترية غير متاحة على المتصفح');
      return false;
    }

    try {
      _setLoading(true);
      _clearError();

      final canAuthenticate = await _localAuth.canCheckBiometrics;
      
      if (!canAuthenticate) {
        _setError('Biométrie non disponible');
        return false;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authentifiez-vous pour accéder à l\'application',
      );

      if (authenticated) {
        _isAuthenticated = true;
        _useBiometric = true;
        print('✅ Biometric authentication successful');
      } else {
        _setError('Authentification biométrique échouée');
      }

      return authenticated;
    } catch (e) {
      print('❌ Error with biometric authentication: $e');
      _setError('Erreur d\'authentification: $e');
      return false;
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// 🔓 Déverrouiller avec biométrie
  Future<bool> unlockWithBiometric() async {
    return await authenticateWithBiometric();
  }

  /// Déverrouiller l'application
  Future<bool> unlockApp() async {
    try {
      _clearError();

      // Vérifier si le PIN est activé pour l'utilisateur courant
      final pinEnabled = await isPinEnabled();
      
      if (!pinEnabled) {
        // Si le PIN n'est pas activé, l'accès est direct
        _isAuthenticated = true;
        return true;
      }

      // Sur Web, sauter la biométrie
      if (kIsWeb) {
        return false; // Afficher directement l'écran PIN
      }

      // Vérifier si la biométrie est activée et disponible (mobile seulement)
      final biometricEnabled = await isBiometricEnabled();
      final biometricAvailable = await isBiometricAvailable();

      if (biometricEnabled && biometricAvailable) {
        // Tenter d'abord la biométrie
        final biometricSuccess = await unlockWithBiometric();
        if (biometricSuccess) {
          return true;
        }
      }

      // Si la biométrie échoue ou n'est pas disponible, 
      // l'écran PIN sera affiché
      return false;
    } catch (e) {
      print('❌ Error unlocking app: $e');
      _setError('Erreur de déverrouillage: $e');
      return false;
    }
  }

  /// Réinitialiser l'authentification (après logout ou background)
  void resetAuthentication() {
    _isAuthenticated = false;
    _error = null;
    notifyListeners();
  }

  /// 🔓 Méthode publique pour définir l'authentification
  void setAuthenticated(bool authenticated) {
    _isAuthenticated = authenticated;
    if (authenticated) {
      _error = null;
    }
    notifyListeners();
  }

  /// Définir une erreur (méthode publique)
  void setError(String error) {
    _error = error;
    notifyListeners();
  }

  /// Méthodes pour la biométrie
  Future<bool> enableBiometric() async {
    if (kIsWeb) return false;
    try {
      final success = await _pinService.enableBiometric(_currentUserId ?? '');
      if (success) {
        _useBiometric = true;
        notifyListeners();
      }
      return success;
    } catch (e) {
      print('❌ Error enabling biometric: $e');
      return false;
    }
  }

  Future<bool> disableBiometric() async {
    if (kIsWeb) return false;
    try {
      final success = await _pinService.disableBiometric(_currentUserId ?? '');
      if (success) {
        _useBiometric = false;
        notifyListeners();
      }
      return success;
    } catch (e) {
      print('❌ Error disabling biometric: $e');
      return false;
    }
  }

  /// Vérifier si la biométrie est activée
  Future<bool> isBiometricEnabled() async {
    return await _pinService.isBiometricEnabled(_currentUserId ?? '');
  }

  /// Effacer toutes les données de sécurité pour l'utilisateur courant
  Future<void> clearAllSecurityData() async {
    if (_currentUserId != null) {
      await _pinService.clearUserPin(_currentUserId!);
    }
    _isAuthenticated = false;
    _useBiometric = false;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  /// Effacer les données de sécurité d'un utilisateur spécifique
  Future<void> clearUserSecurityData(String userId) async {
    await _pinService.clearUserPin(userId);
  }

  /// Méthodes utilitaires privées
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