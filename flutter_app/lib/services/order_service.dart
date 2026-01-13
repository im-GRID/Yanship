// lib/services/order_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class OrderService {
  // Use centralized config for base URL
  static String get baseUrl => AppConfig.apiUrl;

  // Get auth token from storage
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Get headers with authorization
  static Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      // For testing: use a mock token or bypass auth
      'Authorization': token != null ? 'Bearer $token' : 'Bearer mock-test-token',
    };
  }

  // Create new order
  static Future<Map<String, dynamic>> createOrder({
    required String receiver_name,
    required String phone,
    required String address,
    required String city,
    required double price,
    required bool open_product,
    String? sender_address_id,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = {
        'receiver_name': receiver_name,
        'phone': phone,
        'address': address,
        'city': city,
        'price': price,
        'open_product': open_product,
      };
      
      // Add sender_address_id if provided
      if (sender_address_id != null && sender_address_id.isNotEmpty) {
        body['sender_address_id'] = sender_address_id;
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: headers,
        body: json.encode(body),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 201 && data['success']) {
        return {
          'success': true,
          'order': data['data']['order'],
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to create order',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get recent orders for home page
  static Future<Map<String, dynamic>> getRecentOrders() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/orders/recent'),
        headers: headers,
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        return {
          'success': true,
          'orders': data['data']['recentOrders'] ?? [],
          'totalCount': data['data']['totalCount'] ?? 0,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to get recent orders',
          'orders': [],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'orders': [],
      };
    }
  }

  // Get recent orders with history
  static Future<Map<String, dynamic>> getRecentOrdersWithHistory() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/orders/recent/history'),
        headers: headers,
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        return {
          'success': true,
          'orders': data['data']['recentOrders'] ?? [],
          'totalCount': data['data']['totalCount'] ?? 0,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to get recent orders with history',
          'orders': [],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'orders': [],
      };
    }
  }

  // Get user dashboard stats
  static Future<Map<String, dynamic>> getUserDashboard() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/orders/dashboard'),
        headers: headers,
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        return {
          'success': true,
          'stats': data['data']['stats'],
          'recentOrders': data['data']['recentOrders'] ?? [],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to get dashboard data',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get all user orders
  static Future<Map<String, dynamic>> getUserOrders({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/orders?page=$page&limit=$limit'),
        headers: headers,
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        return {
          'success': true,
          'orders': data['data']['orders'] ?? [],
          'pagination': data['data']['pagination'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to get orders',
          'orders': [],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'orders': [],
      };
    }
  }

  // Get all user orders with history
  static Future<Map<String, dynamic>> getUserOrdersWithHistory({
    int page = 1,
    int limit = 100, // Increased default limit for History page
  }) async {
    try {
      final headers = await _getHeaders();
      final offset = (page - 1) * limit; // Convert page to offset
      final response = await http.get(
        Uri.parse('$baseUrl/orders/history?limit=$limit&offset=$offset'),
        headers: headers,
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        return {
          'success': true,
          'orders': data['data']['orders'] ?? [],
          'pagination': data['data']['pagination'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to get orders with history',
          'orders': [],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'orders': [],
      };
    }
  }

  // Get order by ID
  static Future<Map<String, dynamic>> getOrderById(int orderId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/orders/$orderId'),
        headers: headers,
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        return {
          'success': true,
          'order': data['data']['order'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to get order',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Update order
  static Future<Map<String, dynamic>> updateOrder({
    required int orderId,
    String? recipientName,
    String? recipientPhone,
    String? deliveryAddress,
    String? city,
    String? pickupPoint,
    double? price,
    bool? authorizeToOpenBox,
    String? description,
    String? weight,
    String? dimensions,
  }) async {
    try {
      final headers = await _getHeaders();
      
      // Remove null values
      final Map<String, dynamic> body = {};
      if (recipientName != null) body['recipientName'] = recipientName;
      if (recipientPhone != null) body['recipientPhone'] = recipientPhone;
      if (deliveryAddress != null) body['deliveryAddress'] = deliveryAddress;
      if (city != null) body['city'] = city;
      if (pickupPoint != null) body['pickupPoint'] = pickupPoint;
      if (price != null) body['price'] = price;
      if (authorizeToOpenBox != null) body['authorizeToOpenBox'] = authorizeToOpenBox;
      if (description != null) body['description'] = description;
      if (weight != null) body['weight'] = weight;
      if (dimensions != null) body['dimensions'] = dimensions;

      final url = '$baseUrl/orders/$orderId';
      print('OrderService - Making PUT request to: $url');
      print('OrderService - Headers: $headers');
      print('OrderService - Request body: ${json.encode(body)}');

      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: json.encode(body),
      );

      print('OrderService - Response status: ${response.statusCode}');
      print('OrderService - Response body: ${response.body}');

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        return {
          'success': true,
          'order': data['data']['order'],
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update order',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Delete order
  static Future<Map<String, dynamic>> deleteOrder(int orderId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/orders/$orderId'),
        headers: headers,
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
          'message': data['message'] ?? 'Failed to delete order',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Bulk pickup all confirmed orders
  static Future<Map<String, dynamic>> bulkPickupOrders() async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/orders/bulk-pickup'),
        headers: headers,
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        return {
          'success': true,
          'message': data['message'],
          'updatedCount': data['updatedCount'] ?? 0,
          'orders': data['orders'] ?? [],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to pickup orders',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get order by tracking number
  static Future<Map<String, dynamic>> getOrderByTracking(String trackingNumber) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/orders/track/$trackingNumber'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        return {
          'success': true,
          'order': data['data']['order'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Order not found',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Update order status (admin function)
  static Future<Map<String, dynamic>> updateOrderStatus({
    required int orderId,
    required String status,
    String? note,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/orders/$orderId/status'),
        headers: headers,
        body: json.encode({
          'status': status,
          'note': note,
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
          'message': data['message'] ?? 'Failed to update order status',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get order history
  static Future<Map<String, dynamic>> getOrderHistory(int orderId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/orders/$orderId/history'),
        headers: headers,
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        return {
          'success': true,
          'history': data['data']['history'] ?? [],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to get order history',
          'history': [],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'history': [],
      };
    }
  }
}
