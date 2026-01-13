// lib/services/auth_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'push_notification_service.dart';
import 'secure_token_service.dart';

class AuthService {
  // Use centralized config for base URL
  static String get baseUrl => AppConfig.apiUrl;

  // Auto-refresh mechanism
  static Future<String?> _getValidToken() async {
    // Check if we have a valid token
    if (await SecureTokenService.hasValidToken()) {
      return await SecureTokenService.getAccessToken();
    }

    // Try to refresh the token
    final refreshed = await _refreshTokenIfNeeded();
    if (refreshed) {
      return await SecureTokenService.getAccessToken();
    }

    return null;
  }

  static Future<bool> _refreshTokenIfNeeded() async {
    final refreshToken = await SecureTokenService.getRefreshToken();
    if (refreshToken == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh-token'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'refreshToken': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          await SecureTokenService.saveTokens(
            accessToken: data['data']['token'],
            refreshToken: data['data']['refreshToken'],
            expiresInSeconds: data['data']['expiresIn'],
          );
          return true;
        }
      }
    } catch (e) {
      print('Token refresh failed: $e');
    }

    return false;
  }

  // Register new user
  static Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    required String email,
    String? fname,
    String? lname,
    String? address,
    String? city,
    String? company,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'username': username,
          'password': password,
          'email': email,
          'fname': fname,
          'lname': lname,
          'address': address,
          'city': city,
          'company': company,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 201 && data['success']) {
        // Save tokens to secure storage
        await SecureTokenService.saveTokens(
          accessToken: data['data']['token'],
          refreshToken: data['data']['refreshToken'],
          expiresInSeconds: data['data']['expiresIn'],
        );
        await SecureTokenService.saveUser(data['data']['user']);
        return {
          'success': true,
          'user': data['data']['user'],
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'username': username,
          'password': password,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        // Save tokens to secure storage
        await SecureTokenService.saveTokens(
          accessToken: data['data']['token'],
          refreshToken: data['data']['refreshToken'],
          expiresInSeconds: data['data']['expiresIn'],
        );

        // Sauvegarder l'utilisateur avec son niveau
        await SecureTokenService.saveUser(data['data']['user']);

        // Sauvegarder le niveau d'utilisateur séparément pour un accès facile
        await SecureTokenService.saveUserLevel(data['data']['userLevel'] ?? data['data']['user']['userlevel']);

        return {
          'success': true,
          'user': data['data']['user'],
          'userLevel': data['data']['userLevel'] ?? data['data']['user']['userlevel'],
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Login failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

// Méthode pour récupérer le niveau d'utilisateur
  static Future<int?> getUserLevel() async {
    return await SecureTokenService.getUserLevel();
  }


  // Get user profile
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final token = await _getValidToken();
      
      if (token == null) {
        return {
          'success': false,
          'message': 'No authentication token found',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        await SecureTokenService.saveUser(data['data']['user']);
        return {
          'success': true,
          'user': data['data']['user'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to get profile',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Update user profile
  static Future<Map<String, dynamic>> updateProfile({
    String? fname,
    String? lname,
    String? ice,
    String? rib,
    String? cne,
    String? company,
    String? website,
  }) async {
    try {
      final token = await _getValidToken();
      
      if (token == null) {
        return {
          'success': false,
          'message': 'No authentication token found',
        };
      }

      // Remove null values
      final Map<String, dynamic> body = {};
      if (fname != null) body['fname'] = fname;
      if (lname != null) body['lname'] = lname;
      if (ice != null) body['ice'] = ice;
      if (rib != null) body['rib'] = rib;
      if (cne != null) body['cne'] = cne;
      if (company != null) body['company'] = company;
      if (website != null) body['website'] = website;

      final response = await http.put(
        Uri.parse('$baseUrl/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        await SecureTokenService.saveUser(data['data']['user']);
        return {
          'success': true,
          'user': data['data']['user'],
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update profile',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Change password
  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final token = await _getValidToken();
      
      if (token == null) {
        return {
          'success': false,
          'message': 'No authentication token found',
        };
      }

      final response = await http.put(
        Uri.parse('$baseUrl/auth/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        return {
          'success': true,
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to change password',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Logout user
  static Future<void> logout() async {
    // Stop notification service first
    await LocalNotificationService.stopService();
    
    // Clear all secure storage
    await SecureTokenService.clearAll();
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    return await SecureTokenService.hasValidToken();
  }

  // Get current user from secure storage
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    return await SecureTokenService.getUser();
  }

  // Public method to get token for other services
  static Future<String?> getToken() async {
    return await _getValidToken();
  }

  // Upload avatar
  static Future<Map<String, dynamic>> uploadAvatar(File imageFile) async {
    try {
      final token = await _getValidToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No authentication token found'
        };
      }

      print('=== FLUTTER UPLOAD DEBUG ===');
      print('Image file path: ${imageFile.path}');
      
      // Try to get file stats
      final fileStat = await imageFile.stat();
      print('File size: ${fileStat.size} bytes');
      print('File modified: ${fileStat.modified}');
      print('Upload URL: $baseUrl/auth/upload-avatar');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/auth/upload-avatar'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      // Create multipart file with debugging
      final multipartFile = await http.MultipartFile.fromPath('avatar', imageFile.path);
      print('Multipart file created:');
      print('  Content type: ${multipartFile.contentType}');
      print('  Field name: ${multipartFile.field}');
      print('  Filename: ${multipartFile.filename}');
      print('  Length: ${multipartFile.length}');

      request.files.add(multipartFile);

      print('Sending upload request...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      print('=== END FLUTTER UPLOAD DEBUG ===');

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        // Update local user data
        await SecureTokenService.saveUser(data['user']);
        return {
          'success': true,
          'message': data['message'],
          'user': data['user'],
          'avatarUrl': data['avatarUrl']
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to upload avatar'
        };
      }
    } catch (e) {
      print('Avatar upload error: $e');
      return {
        'success': false,
        'message': 'Failed to upload avatar: ${e.toString()}'
      };
    }
  }

  // Get user's push notification preferences
  static Future<Map<String, dynamic>> getPushPreferences() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/notifications/push-preferences'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);
      return data;
    } catch (e) {
      print('Get push preferences error: $e');
      return {
        'success': false,
        'message': 'Failed to get push preferences: ${e.toString()}'
      };
    }
  }

  // Update user's push notification preferences
  static Future<Map<String, dynamic>> updatePushPreferences({
    required bool pushEnabled,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await http.put(
        Uri.parse('$baseUrl/notifications/push-preferences'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'push_enabled': pushEnabled,
        }),
      );

      final data = json.decode(response.body);
      return data;
    } catch (e) {
      print('Update push preferences error: $e');
      return {
        'success': false,
        'message': 'Failed to update push preferences: ${e.toString()}'
      };
    }
  }

  // Get user addresses from multiple addresses table
  static Future<Map<String, dynamic>> getUserAddresses() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/auth/addresses'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200 && data['success']) {
        return {
          'success': true,
          'addresses': data['addresses'] ?? [],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to get addresses',
        };
      }
    } catch (e) {
      print('Get addresses error: $e');
      return {
        'success': false,
        'message': 'Failed to get addresses: ${e.toString()}'
      };
    }
  }

  // Get available cities
  static Future<Map<String, dynamic>> getCities() async {
    try {
      final token = await _getValidToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication required'
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/auth/cities'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200 && data['success']) {
        return {
          'success': true,
          'cities': data['cities'] ?? [],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to get cities',
        };
      }
    } catch (e) {
      print('Get cities error: $e');
      return {
        'success': false,
        'message': 'Failed to get cities: ${e.toString()}'
      };
    }
  }
}
