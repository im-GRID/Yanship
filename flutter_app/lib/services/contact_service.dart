import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class ContactService {
  static String get baseUrl => AppConfig.baseUrl;

  static Future<Map<String, dynamic>> submitContactMessage({
    required String name,
    required String email,
    required String phone,
    required String message,
  }) async {
    try {
      print('🔄 Attempting to submit contact message to: $baseUrl/api/contact');
      print('📝 Data: name=$name, email=$email, phone=$phone');
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/contact'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': name,
          'email': email,
          'phone': phone,
          'message': message,
        }),
      );

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      final data = json.decode(response.body);

      if (response.statusCode == 201 && data['success']) {
        print('✅ Contact message submitted successfully');
        return {
          'success': true,
          'message': data['message'] ?? 'Message sent successfully!',
        };
      } else {
        print('❌ Contact submission failed: ${data['message']}');
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to send message. Please try again.',
        };
      }
    } catch (e) {
      print('💥 Network error in contact submission: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }
}