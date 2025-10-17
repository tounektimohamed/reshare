// lib/core/services/web_safe_storage.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WebSafeStorage {
  static final WebSafeStorage _instance = WebSafeStorage._internal();
  factory WebSafeStorage() => _instance;
  WebSafeStorage._internal();

  // Méthode unique qui fonctionne sur toutes les plateformes
  Future<bool> setString(String key, String value) async {
    try {
      if (kIsWeb) {
        // Solution Web: utiliser un simple Map en mémoire
        // En production, vous pourriez utiliser IndexedDB ou Hive
        _webStorage[key] = value;
        return true;
      } else {
        // Solution Mobile: SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        return prefs.setString(key, value);
      }
    } catch (e) {
      print('⚠️ Storage fallback to memory: $e');
      // Fallback en mémoire
      _webStorage[key] = value;
      return true;
    }
  }

  Future<String?> getString(String key) async {
    try {
      if (kIsWeb) {
        return _webStorage[key];
      } else {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getString(key);
      }
    } catch (e) {
      print('⚠️ Storage fallback to memory: $e');
      return _webStorage[key];
    }
  }

  Future<bool> setBool(String key, bool value) async {
    return setString(key, value.toString());
  }

  Future<bool?> getBool(String key) async {
    final value = await getString(key);
    if (value == 'true') return true;
    if (value == 'false') return false;
    return null;
  }

  Future<void> remove(String key) async {
    try {
      if (kIsWeb) {
        _webStorage.remove(key);
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(key);
      }
    } catch (e) {
      _webStorage.remove(key);
    }
  }

  // Stockage en mémoire pour le Web (persiste pendant la session)
  final Map<String, String> _webStorage = {};
}