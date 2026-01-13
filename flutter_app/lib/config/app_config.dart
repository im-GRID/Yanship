import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {


  static final String baseUrl = dotenv.env['BASE_URL2'] ?? 'http://localhost:3001';

  static final String apiUrl = '$baseUrl/api';
  

  
  // API endpoints (automatically use the baseUrl above)
  static String authEndpoint = '$apiUrl/auth';
  static String ordersEndpoint = '$apiUrl/orders';
  static String notificationsEndpoint = '$apiUrl/notifications';
  static String homeEndpoint = '$apiUrl/home';
  

  //static const String websocketUrl = 'ws://192.168.1.56:3001';
  static final String websocketUrl = dotenv.env['WS_URL'] ?? 'ws://localhost:3001';


  static  String notificationPollingEndpoint = '$apiUrl/notifications/poll';
  
  // Local Notification Settings
  static const String notificationChannelId = 'yanship_notifications';
  static const String notificationChannelName = 'Yanship Notifications';
  static const String notificationChannelDescription = 'Notifications for order updates and system alerts';
  
  // Polling interval for checking new notifications (in seconds)
  static const int notificationPollingInterval = 30;
  
  // Helper methods for handling images and assets
  static String getImageUrl(String imagePath) {
    if (imagePath.isEmpty) return '';
    return imagePath.startsWith('http') ? imagePath : '$baseUrl$imagePath';
  }
  
  static String getAvatarUrl(String? avatarPath) {
    if (avatarPath == null || avatarPath.isEmpty) return '';
    return avatarPath.startsWith('http') ? avatarPath : '$baseUrl$avatarPath';
  }
}
