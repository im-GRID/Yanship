// services/api_helper.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_app/services/auth_service.dart';

class ApiHelper {
  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': token != null ? 'Bearer $token' : 'Bearer mock-test-token',
    };
  }

  static Future<Map<String, String>> _getMultipartHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Authorization': token != null ? 'Bearer $token' : 'Bearer mock-test-token',
    };
  }

  static Future<http.Response> get(String url) async {
    final headers = await _getHeaders();
    return await http.get(Uri.parse(url), headers: headers);
  }

  static Future<http.Response> post(String url, {dynamic data}) async {
    final headers = await _getHeaders();
    return await http.post(
      Uri.parse(url),
      headers: headers,
      body: json.encode(data),
    );
  }

  static Future<http.StreamedResponse> multipartPost(
      String url, {
        required Map<String, String> fields,
        List<http.MultipartFile>? files,
      }) async {
    final headers = await _getMultipartHeaders();
    final request = http.MultipartRequest('POST', Uri.parse(url));

    request.headers.addAll(headers);
    request.fields.addAll(fields);

    if (files != null) {
      request.files.addAll(files);
    }

    return await request.send();
  }

  static dynamic parseResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      throw Exception('API Error: ${response.statusCode} - ${response.body}');
    }
  }

  static dynamic parseStreamedResponse(http.StreamedResponse response) async {
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(responseBody);
    } else {
      throw Exception('API Error: ${response.statusCode} - $responseBody');
    }
  }
}