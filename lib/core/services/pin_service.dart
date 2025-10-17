// lib/core/services/pin_service.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PinService {
  // Stockage en mémoire pour le Web
  final Map<String, dynamic> _webStorage = {};

  // Méthodes pour générer les clés par utilisateur
  String _getPinKey(String userId) => 'user_pin_$userId';
  String _getPinEnabledKey(String userId) => 'pin_enabled_$userId';
  String _getBiometricEnabledKey(String userId) => 'biometric_enabled_$userId';

  Future<bool> setPin(String userId, String pin) async {
    try {
      if (kIsWeb) {
        _webStorage[_getPinKey(userId)] = pin;
        print('💾 Web: PIN saved for user $userId');
        return true;
      } else {
        final prefs = await SharedPreferences.getInstance();
        return await prefs.setString(_getPinKey(userId), pin);
      }
    } catch (e) {
      print('❌ Error setting PIN for user $userId: $e');
      return false;
    }
  }

  Future<String?> getPin(String userId) async {
    try {
      if (kIsWeb) {
        return _webStorage[_getPinKey(userId)] as String?;
      } else {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getString(_getPinKey(userId));
      }
    } catch (e) {
      print('❌ Error getting PIN for user $userId: $e');
      return null;
    }
  }

  Future<bool> validatePin(String userId, String pin) async {
    final storedPin = await getPin(userId);
    return storedPin == pin;
  }

  Future<bool> isPinEnabled(String userId) async {
    try {
      if (kIsWeb) {
        return _webStorage[_getPinEnabledKey(userId)] == true;
      } else {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getBool(_getPinEnabledKey(userId)) ?? false;
      }
    } catch (e) {
      print('❌ Error checking PIN status for user $userId: $e');
      return false;
    }
  }

  Future<bool> enablePin(String userId) async {
    try {
      if (kIsWeb) {
        _webStorage[_getPinEnabledKey(userId)] = true;
        print('✅ Web: PIN enabled for user $userId');
        return true;
      } else {
        final prefs = await SharedPreferences.getInstance();
        final success = await prefs.setBool(_getPinEnabledKey(userId), true);
        if (success) {
          print('✅ PIN enabled for user $userId');
        }
        return success;
      }
    } catch (e) {
      print('❌ Error enabling PIN for user $userId: $e');
      return false;
    }
  }

  Future<bool> disablePin(String userId) async {
    try {
      if (kIsWeb) {
        _webStorage[_getPinEnabledKey(userId)] = false;
        print('✅ Web: PIN disabled for user $userId');
        return true;
      } else {
        final prefs = await SharedPreferences.getInstance();
        final success = await prefs.setBool(_getPinEnabledKey(userId), false);
        if (success) {
          print('✅ PIN disabled for user $userId');
        }
        return success;
      }
    } catch (e) {
      print('❌ Error disabling PIN for user $userId: $e');
      return false;
    }
  }

  Future<void> clearUserPin(String userId) async {
    try {
      if (kIsWeb) {
        _webStorage.remove(_getPinKey(userId));
        _webStorage.remove(_getPinEnabledKey(userId));
        _webStorage.remove(_getBiometricEnabledKey(userId));
        print('🧹 Web: PIN cleared for user $userId');
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_getPinKey(userId));
        await prefs.remove(_getPinEnabledKey(userId));
        await prefs.remove(_getBiometricEnabledKey(userId));
        print('🧹 PIN cleared for user $userId');
      }
    } catch (e) {
      print('❌ Error clearing PIN for user $userId: $e');
    }
  }

  // Méthodes pour la biométrie - Toujours false sur Web
  Future<bool> isBiometricEnabled(String userId) async {
    if (kIsWeb) return false;
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_getBiometricEnabledKey(userId)) ?? false;
    } catch (e) {
      print('❌ Error checking biometric status for user $userId: $e');
      return false;
    }
  }

  Future<bool> enableBiometric(String userId) async {
    if (kIsWeb) return false;
    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setBool(_getBiometricEnabledKey(userId), true);
      if (success) {
        print('✅ Biometric enabled for user $userId');
      }
      return success;
    } catch (e) {
      print('❌ Error enabling biometric for user $userId: $e');
      return false;
    }
  }

  Future<bool> disableBiometric(String userId) async {
    if (kIsWeb) return false;
    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setBool(_getBiometricEnabledKey(userId), false);
      if (success) {
        print('✅ Biometric disabled for user $userId');
      }
      return success;
    } catch (e) {
      print('❌ Error disabling biometric for user $userId: $e');
      return false;
    }
  }

  // Méthode de migration pour les anciens PIN sans userId
  Future<void> migrateOldPin(String userId) async {
    try {
      if (kIsWeb) {
        // Migration Web
        final oldPin = _webStorage['user_pin'] as String?;
        final oldEnabled = _webStorage['pin_enabled'] == true;
        
        if (oldPin != null) {
          _webStorage[_getPinKey(userId)] = oldPin;
          _webStorage[_getPinEnabledKey(userId)] = oldEnabled;
          
          // Supprimer les anciennes données
          _webStorage.remove('user_pin');
          _webStorage.remove('pin_enabled');
          _webStorage.remove('biometric_enabled');
          
          print('🔄 Migrated old PIN data to user $userId');
        }
      } else {
        // Migration Mobile
        final prefs = await SharedPreferences.getInstance();
        final oldPin = prefs.getString('user_pin');
        final oldEnabled = prefs.getBool('pin_enabled') ?? false;
        
        if (oldPin != null) {
          await prefs.setString(_getPinKey(userId), oldPin);
          await prefs.setBool(_getPinEnabledKey(userId), oldEnabled);
          
          // Supprimer les anciennes données
          await prefs.remove('user_pin');
          await prefs.remove('pin_enabled');
          await prefs.remove('biometric_enabled');
          
          print('🔄 Migrated old PIN data to user $userId');
        }
      }
    } catch (e) {
      print('❌ Error migrating PIN data: $e');
    }
  }

  // Méthode utilitaire pour nettoyer tous les PIN (développement seulement)
  Future<void> clearAllPins() async {
    try {
      if (kIsWeb) {
        _webStorage.clear();
        print('🧹 Web: All PIN data cleared');
      } else {
        final prefs = await SharedPreferences.getInstance();
        final keys = prefs.getKeys();
        
        for (final key in keys) {
          if (key.startsWith('user_pin_') || 
              key.startsWith('pin_enabled_') || 
              key.startsWith('biometric_enabled_') ||
              key == 'user_pin' || 
              key == 'pin_enabled' || 
              key == 'biometric_enabled') {
            await prefs.remove(key);
          }
        }
        print('🧹 All PIN data cleared');
      }
    } catch (e) {
      print('❌ Error clearing all PIN data: $e');
    }
  }
}