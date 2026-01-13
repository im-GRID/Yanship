// lib/services/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  // Translation maps for notifications
  static const Map<String, Map<String, String>> _translations = {
    'en': {
      'order_status_update': 'Order Status Update',
      'order_accepted': 'Order has been accepted',
      'order_picked_up': 'Order has been picked up',
      'order_delivered': 'Order has been delivered',
      'order_cancelled': 'Order has been cancelled',
      'new_order_assigned': 'New order assigned to you',
    },
    'fr': {
      'order_status_update': 'Mise à jour du Statut',
      'order_accepted': 'Commande acceptée',
      'order_picked_up': 'Commande récupérée',
      'order_delivered': 'Commande livrée',
      'order_cancelled': 'Commande annulée',
      'new_order_assigned': 'Nouvelle commande assignée',
    },
    'ar': {
      'order_status_update': 'تحديث حالة الطلب',
      'order_accepted': 'تم قبول الطلب',
      'order_picked_up': 'تم استلام الطلب',
      'order_delivered': 'تم تسليم الطلب',
      'order_cancelled': 'تم إلغاء الطلب',
      'new_order_assigned': 'تم تعيين طلب جديد لك',
    },
  };

  Future<void> initialize() async {
    try {
      tz.initializeTimeZones();
      
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      const settings = InitializationSettings(
        android: androidSettings, 
        iOS: iosSettings
      );
      
      final initialized = await _notifications.initialize(
        settings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          // Handle notification tap
          print('Notification tapped: ${response.payload}');
        },
      );
      
      _isInitialized = initialized ?? false;
      print('Notification service initialized: $_isInitialized');
    } catch (e) {
      print('Error initializing notifications: $e');
      _isInitialized = false;
    }
  }

  Future<bool> areNotificationsEnabled() async {
    if (!_isInitialized) return false;
    
    final bool? enabled = await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.areNotificationsEnabled();
    
    return enabled ?? false;
  }

  Future<String> _getCurrentLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('language_code') ?? 'en';
  }

  String _getTranslation(String key, String languageCode) {
    return _translations[languageCode]?[key] ?? 
           _translations['en']?[key] ?? 
           key;
  }

  Future<void> showOrderStatusNotification({
    required String orderId,
    required String status,
    String? customMessage,
  }) async {
    if (!_isInitialized) {
      print('NotificationService not initialized');
      return;
    }

    try {
      final languageCode = await _getCurrentLanguage();
      
      // Get translated title
      final title = _getTranslation('order_status_update', languageCode);
      
      // Get translated message based on status
      String message;
      if (customMessage != null) {
        message = customMessage;
      } else {
        switch (status.toLowerCase()) {
          case 'accepted':
            message = _getTranslation('order_accepted', languageCode);
            break;
          case 'picked_up':
            message = _getTranslation('order_picked_up', languageCode);
            break;
          case 'delivered':
            message = _getTranslation('order_delivered', languageCode);
            break;
          case 'cancelled':
            message = _getTranslation('order_cancelled', languageCode);
            break;
          default:
            message = _getTranslation('order_status_update', languageCode);
        }
      }

      const androidDetails = AndroidNotificationDetails(
        'order_status_channel',
        'Order Status Updates',
        channelDescription: 'Notifications for order status changes',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        showWhen: true,
      );
      
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Generate a unique notification ID using order ID hash
      final notificationId = orderId.hashCode.abs();

      await _notifications.show(
        notificationId,
        title,
        message,
        details,
        payload: 'order_$orderId',
      );
      
      print('Notification sent for order: $orderId in language: $languageCode');
    } catch (e) {
      print('Error showing notification: $e');
    }
  }

  Future<void> showNewOrderNotification({
    required String orderId,
    String? customMessage,
  }) async {
    if (!_isInitialized) {
      print('NotificationService not initialized');
      return;
    }

    try {
      final languageCode = await _getCurrentLanguage();
      
      final title = _getTranslation('order_status_update', languageCode);
      final message = customMessage ?? _getTranslation('new_order_assigned', languageCode);

      const androidDetails = AndroidNotificationDetails(
        'new_order_channel',
        'New Orders',
        channelDescription: 'Notifications for new order assignments',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        showWhen: true,
        sound: RawResourceAndroidNotificationSound('notification_sound'),
      );
      
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'notification_sound.wav',
      );
      
      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final notificationId = orderId.hashCode.abs();

      await _notifications.show(
        notificationId,
        title,
        message,
        details,
        payload: 'new_order_$orderId',
      );
      
      print('New order notification sent: $orderId in language: $languageCode');
    } catch (e) {
      print('Error showing new order notification: $e');
    }
  }

  Future<void> cancelNotification(String orderId) async {
    if (!_isInitialized) return;
    
    try {
      final notificationId = orderId.hashCode.abs();
      await _notifications.cancel(notificationId);
    } catch (e) {
      print('Error canceling notification: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    if (!_isInitialized) return;
    
    try {
      await _notifications.cancelAll();
    } catch (e) {
      print('Error canceling all notifications: $e');
    }
  }
}