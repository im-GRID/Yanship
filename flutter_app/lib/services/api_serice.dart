// // api_service.dart
// import 'dart:convert';
// import 'package:http/http.dart' as http;
//
// class ApiService {
//   final String baseUrl;
//
//   ApiService({required this.baseUrl});
//
//   Future<dynamic> get(String endpoint) async {
//     final response = await http.get(Uri.parse('$baseUrl$endpoint'));
//     final String fullUrl = '$baseUrl$endpoint';
//
//     print('Making GET request to: $fullUrl'); // Debug print
//
//     return _handleResponse(response);
//   }
//
//   Future<dynamic> post(String endpoint, {dynamic data}) async {
//     final response = await http.post(
//       Uri.parse('$baseUrl$endpoint'),
//       headers: {'Content-Type': 'application/json'},
//       body: json.encode(data),
//     );
//     return _handleResponse(response);
//   }
//
//   Future<dynamic> put(String endpoint, {dynamic data}) async {
//     final response = await http.put(
//       Uri.parse('$baseUrl$endpoint'),
//       headers: {'Content-Type': 'application/json'},
//       body: json.encode(data),
//     );
//     return _handleResponse(response);
//   }
//
//   Future<dynamic> delete(String endpoint) async {
//     final response = await http.delete(Uri.parse('$baseUrl$endpoint'));
//     return _handleResponse(response);
//   }
//
//   dynamic _handleResponse(http.Response response) {
//     if (response.statusCode >= 200 && response.statusCode < 300) {
//       return json.decode(response.body);
//     } else {
//       throw Exception('Erreur API: ${response.statusCode} - ${response.body}');
//     }
//   }
// }

// api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_app/services/auth_service.dart'; // Importez AuthService

class ApiService {
  final String baseUrl;

  ApiService({required this.baseUrl});

  // Méthode pour obtenir les headers avec JWT
  Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getToken();
    print("Tokkeeeee: "+token!);
    return {
      'Content-Type': 'application/json',
      'Authorization': token != null ? 'Bearer $token' : 'Bearer mock-test-token',
    };
  }

  Future<dynamic> get(String endpoint) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );

    final String fullUrl = '$baseUrl$endpoint';
    print('Making GET request to: $fullUrl'); // Debug print
    print('Headers: $headers'); // Debug headers

    return _handleResponse(response);
  }

  Future<dynamic> post(String endpoint, {dynamic data}) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: json.encode(data),
    );
    return _handleResponse(response);
  }

  Future<dynamic> put(String endpoint, {dynamic data}) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: json.encode(data),
    );
    return _handleResponse(response);
  }

  Future<dynamic> delete(String endpoint) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );
    return _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    print('Response status: ${response.statusCode}'); // Debug
    print('Response body: ${response.body}'); // Debug

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      throw Exception('Erreur API: ${response.statusCode} - ${response.body}');
    }
  }
}