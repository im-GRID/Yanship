import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureTokenService {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  // Storage keys
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _tokenExpiryKey = 'token_expiry';
  static const String _userKey = 'current_user';

  // Check if secure storage is available (mobile platforms)
  static bool get _isSecureStorageAvailable {
    return Platform.isIOS || Platform.isAndroid || Platform.isMacOS;
  }

  // Fallback to SharedPreferences for Windows/Linux/Web
  static Future<void> _writeSecure(String key, String value) async {
    if (_isSecureStorageAvailable) {
      try {
        await _secureStorage.write(key: key, value: value);
      } catch (e) {
        // Fallback to SharedPreferences if secure storage fails
        await _writeSharedPrefs(key, value);
      }
    } else {
      await _writeSharedPrefs(key, value);
    }
  }

  static Future<String?> _readSecure(String key) async {
    if (_isSecureStorageAvailable) {
      try {
        return await _secureStorage.read(key: key);
      } catch (e) {
        // Fallback to SharedPreferences if secure storage fails
        return await _readSharedPrefs(key);
      }
    } else {
      return await _readSharedPrefs(key);
    }
  }

  static Future<void> _deleteSecure(String key) async {
    if (_isSecureStorageAvailable) {
      try {
        await _secureStorage.delete(key: key);
      } catch (e) {
        // Fallback to SharedPreferences if secure storage fails
        await _deleteSharedPrefs(key);
      }
    } else {
      await _deleteSharedPrefs(key);
    }
  }

  // SharedPreferences fallback methods
  static Future<void> _writeSharedPrefs(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  static Future<String?> _readSharedPrefs(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  static Future<void> _deleteSharedPrefs(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  // Token Management
  static Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
    int? expiresInSeconds,
  }) async {
    await _writeSecure(_tokenKey, accessToken);
    
    if (refreshToken != null) {
      await _writeSecure(_refreshTokenKey, refreshToken);
    }
    
    if (expiresInSeconds != null) {
      final expiryTime = DateTime.now().add(Duration(seconds: expiresInSeconds));
      await _writeSecure(_tokenExpiryKey, expiryTime.toIso8601String());
    }
  }

  static Future<String?> getAccessToken() async {
    return await _readSecure(_tokenKey);
  }

  static Future<String?> getRefreshToken() async {
    return await _readSecure(_refreshTokenKey);
  }

  static Future<DateTime?> getTokenExpiry() async {
    final expiryStr = await _readSecure(_tokenExpiryKey);
    if (expiryStr != null) {
      return DateTime.parse(expiryStr);
    }
    return null;
  }

  static Future<bool> isTokenExpired() async {
    final expiry = await getTokenExpiry();
    if (expiry == null) return false;
    
    // Consider token expired 5 minutes before actual expiry for safety
    final safeExpiry = expiry.subtract(const Duration(minutes: 5));
    return DateTime.now().isAfter(safeExpiry);
  }

  static Future<bool> hasValidToken() async {
    final token = await getAccessToken();
    if (token == null) return false;
    
    final isExpired = await isTokenExpired();
    return !isExpired;
  }

  // User Data Management
  static Future<void> saveUser(Map<String, dynamic> user) async {
    await _writeSecure(_userKey, json.encode(user));
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final userJson = await _readSecure(_userKey);
    if (userJson != null) {
      return json.decode(userJson);
    }
    return null;
  }

  // Clear all stored data (logout) - updated to include user level
  static Future<void> clearAll() async {
    await _deleteSecure(_tokenKey);
    await _deleteSecure(_refreshTokenKey);
    await _deleteSecure(_tokenExpiryKey);
    await _deleteSecure(_userKey);
    await _deleteSecure(_userLevelKey);
  }

  // Migration helper: Move from SharedPreferences to Secure Storage
  static Future<void> migrateFromSharedPreferences() async {
    try {
      // This would be called once to migrate existing tokens
      // Implementation depends on whether you want to support migration
    } catch (e) {
      // Migration failed, user will need to login again
      print('Token migration failed: $e');
    }
  }

  // User level management - using secure storage for consistency
  static const String _userLevelKey = 'user_level';
  
  static Future<void> saveUserLevel(int userLevel) async {
    await _writeSecure(_userLevelKey, userLevel.toString());
  }

  static Future<int?> getUserLevel() async {
    final userLevelStr = await _readSecure(_userLevelKey);
    if (userLevelStr != null) {
      return int.tryParse(userLevelStr);
    }
    return null;
  }

}
