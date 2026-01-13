import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/notification_model.dart';
import '../config/app_config.dart';
import 'auth_service.dart';

class NotificationService {
  static String get baseUrl => AppConfig.apiUrl;
  
  // Get headers with authorization using the secure auth service
  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Get all notifications
  static Future<NotificationResponse> getNotifications({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/notifications?limit=$limit&offset=$offset'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return NotificationResponse.fromJson(jsonData);
      } else {
        return NotificationResponse(
          success: false,
          notifications: [],
          unreadCount: 0,
          pagination: {},
          message: 'Failed to load notifications',
        );
      }
    } catch (e) {
      return NotificationResponse(
        success: false,
        notifications: [],
        unreadCount: 0,
        pagination: {},
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  // Get unread notification count
  static Future<int> getUnreadCount() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/notifications/unread-count'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return jsonData['data']['unread_count'] ?? 0;
      } else {
        return 0;
      }
    } catch (e) {
      return 0;
    }
  }

  // Mark notification as read
  static Future<bool> markAsRead(int notificationId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/notifications/$notificationId/read'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return jsonData['success'] ?? false;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // Mark all notifications as read
  static Future<bool> markAllAsRead() async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/notifications/read-all'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return jsonData['success'] ?? false;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // Delete notification
  static Future<bool> deleteNotification(int notificationId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/notifications/$notificationId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return jsonData['success'] ?? false;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
}}
