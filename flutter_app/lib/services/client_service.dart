// Client Management Service for Flutter
// File: flutter_app/lib/services/client_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'secure_token_service.dart';

class Client {
  final int id;
  final String name;
  final String? phone;
  final String? companyName;
  final String? address;
  final int? city; // This is an int in the actual table
  final String? country;
  final bool isBlacklisted;
  final DateTime? blacklistedDate;
  final int? blacklistedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  // These fields come from analytics view or calculations
  final int totalOrders;
  final int successfulOrders;
  final int cancelledOrders;
  final double totalRevenue;
  final double? successRate;
  final DateTime? lastOrderDate;

  Client({
    required this.id,
    required this.name,
    this.phone,
    this.companyName,
    this.address,
    this.city,
    this.country,
    required this.isBlacklisted,
    this.blacklistedDate,
    this.blacklistedBy,
    required this.createdAt,
    required this.updatedAt,
    required this.totalOrders,
    required this.successfulOrders,
    required this.cancelledOrders,
    required this.totalRevenue,
    this.successRate,
    this.lastOrderDate,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      phone: json['phone'],
      companyName: json['company_name'],
      address: json['address'],
      city: json['city'] != null ? int.tryParse(json['city'].toString()) : null,
      country: json['country'],
      isBlacklisted: json['is_blacklisted'] == 1,
      blacklistedDate: json['blacklisted_date'] != null 
          ? DateTime.parse(json['blacklisted_date']) 
          : null,
      blacklistedBy: json['blacklisted_by'] != null 
          ? int.tryParse(json['blacklisted_by'].toString()) 
          : null,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
      totalOrders: int.tryParse(json['total_orders']?.toString() ?? '0') ?? 0,
      successfulOrders: int.tryParse(json['successful_orders']?.toString() ?? '0') ?? 0,
      cancelledOrders: int.tryParse(json['cancelled_orders']?.toString() ?? '0') ?? 0,
      totalRevenue: double.tryParse(json['total_revenue']?.toString() ?? '0') ?? 0.0,
      successRate: json['success_rate'] != null 
          ? double.tryParse(json['success_rate'].toString()) 
          : null,
      lastOrderDate: json['last_order_date'] != null 
          ? DateTime.parse(json['last_order_date']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'company_name': companyName,
      'address': address,
      'city': city,
      'country': country,
      'is_blacklisted': isBlacklisted,
      'blacklisted_date': blacklistedDate?.toIso8601String(),
      'blacklisted_by': blacklistedBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'total_orders': totalOrders,
      'successful_orders': successfulOrders,
      'cancelled_orders': cancelledOrders,
      'total_revenue': totalRevenue,
      'success_rate': successRate,
      'last_order_date': lastOrderDate?.toIso8601String(),
    };
  }
}

class ClientNote {
  final int id;
  final String note;
  final String? adminName;
  final DateTime createdAt;

  ClientNote({
    required this.id,
    required this.note,
    this.adminName,
    required this.createdAt,
  });

  factory ClientNote.fromJson(Map<String, dynamic> json) {
    return ClientNote(
      id: json['id'] ?? 0,
      note: json['note'] ?? '',
      adminName: json['admin_name'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class BlacklistHistory {
  final int id;
  final String action;
  final String? reason;
  final String? adminName;
  final DateTime actionDate;

  BlacklistHistory({
    required this.id,
    required this.action,
    this.reason,
    this.adminName,
    required this.actionDate,
  });

  factory BlacklistHistory.fromJson(Map<String, dynamic> json) {
    return BlacklistHistory(
      id: json['id'] ?? 0,
      action: json['action'] ?? '',
      reason: json['reason'],
      adminName: json['admin_name'],
      actionDate: DateTime.parse(json['action_date'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class ClientStats {
  final int totalClients;
  final int activeClients;
  final int blacklistedClients;
  final double avgRating;
  final double totalRevenue;
  final double avgSuccessRate;

  ClientStats({
    required this.totalClients,
    required this.activeClients,
    required this.blacklistedClients,
    required this.avgRating,
    required this.totalRevenue,
    required this.avgSuccessRate,
  });

  factory ClientStats.fromJson(Map<String, dynamic> json) {
    return ClientStats(
      totalClients: json['total_clients'] ?? 0,
      activeClients: json['active_clients'] ?? 0,
      blacklistedClients: json['blacklisted_clients'] ?? 0,
      avgRating: double.tryParse(json['avg_rating']?.toString() ?? '0') ?? 0.0,
      totalRevenue: double.tryParse(json['total_revenue']?.toString() ?? '0') ?? 0.0,
      avgSuccessRate: double.tryParse(json['avg_success_rate']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class ClientService {

  /// Checks if a phone number belongs to a blacklisted client
  static Future<bool> isPhoneBlacklisted(String phone) async {
    if (phone.isEmpty) return false;
    try {
      final result = await getClients(search: phone, status: 'all', limit: 10);
      List<Client> clients = [];
      if (result['clients'] is List<Client>) {
        clients = result['clients'] as List<Client>;
      } else if (result['data'] is List) {
        clients = (result['data'] as List).map((e) => Client.fromJson(e)).toList();
      }
      for (final client in clients) {
        if (client.phone != null && client.phone!.trim() == phone.trim() && client.isBlacklisted) {
          return true;
        }
      }
    } catch (e) {
      print('Error checking if phone is blacklisted: $e');
    }
    return false;
  }
  static final String baseUrl = AppConfig.baseUrl;

  // Get all clients with pagination and filtering
  static Future<Map<String, dynamic>> getClients({
    int page = 1,
    int limit = 20,
    String search = '',
    String status = 'all',
    String sortBy = 'created_at',
    String sortOrder = 'DESC',
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        'search': search,
        'status': status,
        'sortBy': sortBy,
        'sortOrder': sortOrder,
      };

      final uri = Uri.parse('$baseUrl/api/clients').replace(queryParameters: queryParams);
      final token = await SecureTokenService.getAccessToken();
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      print('DEBUG: Raw HTTP response body from /clients:');
      print(response.body);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          final clients = (data['data'] as List)
              .map((clientJson) => Client.fromJson(clientJson))
              .toList();
          // Map backend statistics to ClientStats fields
          ClientStats? stats;
          if (data.containsKey('statistics') && data['statistics'] != null) {
            final s = data['statistics'];
            stats = ClientStats(
              totalClients: s['all'] ?? 0,
              activeClients: s['active'] ?? 0,
              blacklistedClients: s['blocked'] ?? 0,
              avgRating: 0.0,
              totalRevenue: 0.0,
              avgSuccessRate: 0.0,
            );
          } else if (data.containsKey('stats')) {
            stats = ClientStats.fromJson(data['stats']);
          }
          return {
            'success': true,
            'clients': clients,
            'pagination': data['pagination'],
            if (stats != null) 'stats': stats,
          };
        }
      }
      return {
        'success': false,
        'message': 'Failed to load clients',
      };
    } catch (e) {
      print('Error getting clients: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Get single client details
  static Future<Map<String, dynamic>> getClientDetails(int clientId) async {
    try {
      final token = await SecureTokenService.getAccessToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/clients/$clientId'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success']) {
          return {
            'success': true,
            'client': Client.fromJson(data['data']['client']),
            'notes': (data['data']['notes'] as List)
                .map((note) => ClientNote.fromJson(note))
                .toList(),
            'blacklistHistory': (data['data']['blacklistHistory'] as List)
                .map((history) => BlacklistHistory.fromJson(history))
                .toList(),
            'recentOrders': data['data']['recentOrders'],
          };
        }
      }

      return {
        'success': false,
        'message': 'Failed to load client details',
      };
    } catch (e) {
      print('Error getting client details: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Create new client
  static Future<Map<String, dynamic>> createClient({
    required String name,
    String? phone,
    String? companyName,
    String? address,
    int? city,
    String? country,
  }) async {
    try {
      final token = await SecureTokenService.getAccessToken();
      final response = await http.post(
        Uri.parse('$baseUrl/api/clients'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'name': name,
          'phone': phone,
          'company_name': companyName,
          'address': address,
          'city': city,
          'country': country,
        }),
      );

      final data = json.decode(response.body);
      return data;
    } catch (e) {
      print('Error creating client: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Update client
  static Future<Map<String, dynamic>> updateClient({
    required int clientId,
    required String name,
    String? phone,
    String? companyName,
    String? address,
    int? city,
    String? country,
  }) async {
    try {
      final token = await SecureTokenService.getAccessToken();
      final response = await http.put(
        Uri.parse('$baseUrl/api/clients/$clientId'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'name': name,
          'phone': phone,
          'company_name': companyName,
          'address': address,
          'city': city,
          'country': country,
        }),
      );

      final data = json.decode(response.body);
      return data;
    } catch (e) {
      print('Error updating client: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Blacklist or unblacklist client
  static Future<Map<String, dynamic>> toggleBlacklist({
    required int clientId,
    required String action, // 'blacklist' or 'unblacklist'
    required String reason,
    required int adminId,
  }) async {
    try {
      final token = await SecureTokenService.getAccessToken();
      final response = await http.post(
        Uri.parse('$baseUrl/api/clients/$clientId/blacklist'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'action': action,
          'reason': reason,
          'adminId': adminId,
        }),
      );

      final data = json.decode(response.body);
      return data;
    } catch (e) {
      print('Error toggling blacklist: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Add note to client
  static Future<Map<String, dynamic>> addNote({
    required int clientId,
    required String note,
    required int adminId,
  }) async {
    try {
      final token = await SecureTokenService.getAccessToken();
      final response = await http.post(
        Uri.parse('$baseUrl/api/clients/$clientId/notes'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'note': note,
          'adminId': adminId,
        }),
      );

      final data = json.decode(response.body);
      return data;
    } catch (e) {
      print('Error adding note: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Get client statistics
  static Future<Map<String, dynamic>> getClientStats() async {
    try {
      final token = await SecureTokenService.getAccessToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/clients/stats/overview'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success']) {
          return {
            'success': true,
            'stats': ClientStats.fromJson(data['data']),
          };
        }
      }

      return {
        'success': false,
        'message': 'Failed to load statistics',
      };
    } catch (e) {
      print('Error getting client stats: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Search clients
  static Future<List<Client>> searchClients(String searchTerm) async {
    try {
      final result = await getClients(
        search: searchTerm,
        limit: 10,
      );

      if (result['success']) {
        return result['clients'] as List<Client>;
      }

      return [];
    } catch (e) {
      print('Error searching clients: $e');
      return [];
    }
  }

  // Blacklist/Unblacklist client
  static Future<Map<String, dynamic>> updateClientBlacklistStatus({
    required int clientId,
    required String action, // 'blacklist' or 'unblacklist'
    String? reason,
    int? adminId,
  }) async {
    try {
      final token = await SecureTokenService.getAccessToken();
      final response = await http.post(
        Uri.parse('$baseUrl/api/clients/$clientId/blacklist'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'action': action,
          'reason': reason ?? '',
          'adminId': adminId ?? 1, // Default admin ID if not provided
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        return {
          'success': true,
          'message': data['message'],
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Failed to update client status',
      };
    } catch (e) {
      print('Error updating client blacklist status: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Add note to client
  static Future<Map<String, dynamic>> addClientNote({
    required int clientId,
    required String note,
    int? adminId,
  }) async {
    try {
      final token = await SecureTokenService.getAccessToken();
      final response = await http.post(
        Uri.parse('$baseUrl/api/clients/$clientId/notes'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'note': note,
          'adminId': adminId ?? 1, // Default admin ID if not provided
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        return {
          'success': true,
          'message': data['message'],
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Failed to add note',
      };
    } catch (e) {
      print('Error adding client note: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Delete client
  static Future<Map<String, dynamic>> deleteClient(int clientId) async {
    try {
      print('Attempting to delete client with ID: $clientId');
      final url = '$baseUrl/api/clients/$clientId?adminId=1&reason=Client deleted from app';
      print('DELETE URL: $url');
      
      final token = await SecureTokenService.getAccessToken();
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      print('Delete response status: ${response.statusCode}');
      print('Delete response body: ${response.body}');

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        return {
          'success': true,
          'message': data['message'] ?? 'Client deleted successfully',
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Failed to delete client',
      };
    } catch (e) {
      print('Error deleting client: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }
}
