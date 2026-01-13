import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/app_config.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static WebSocketChannel? _websocketChannel;
  static Timer? _pollingTimer;
  static Timer? _heartbeatTimer;
  static Timer? _reconnectTimer;
  static String? _lastNotificationId;
  static bool _isInitialized = false;
  static bool _isConnecting = false;
  static bool _isConnected = false;
  static int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  
  // Initialize local notifications
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    print('🔔 Initializing Local Notifications...');
    
    // Initialize local notifications
    await initializeLocalNotifications();
    
    // Start real-time notification listener
    await startNotificationListener();
    
    _isInitialized = true;
    print('✅ Local Notifications initialized successfully');
  }

  // Start notification service with authentication (public method for external use)
  static Future<void> startService(String authToken) async {
    print('📱 Starting notification service with auth token');
    
    // Store the auth token if not already stored
    final prefs = await SharedPreferences.getInstance();
    final currentToken = prefs.getString('auth_token');
    if (currentToken != authToken) {
      await prefs.setString('auth_token', authToken);
      print('💾 New auth token stored');
    }
    
    // Reset reconnection attempts since we have a valid token now
    _reconnectAttempts = 0;
    
    // Initialize if not already initialized
    if (!_isInitialized) {
      await initialize();
    } else {
      // If already initialized, restart the listener with new token
      // First close any existing connections
      await _closeWebSocket();
      
      // Stop any existing polling
      _pollingTimer?.cancel();
      
      // Start fresh with new token
      await startNotificationListener();
    }
    
    print('✅ Notification service started successfully');
  }
  
  // Stop notification service (for logout)
  static Future<void> stopService() async {
    print('📱 Stopping notification service');
    
    // Close WebSocket connection
    await _closeWebSocket();
    
    // Stop polling
    _pollingTimer?.cancel();
    _pollingTimer = null;
    
    // Clear auth token
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    
    // Reset state
    _isConnected = false;
    _isConnecting = false;
    _reconnectAttempts = 0;
    
    print('✅ Notification service stopped');
  }
  
  // Initialize local notification plugin
  static Future<void> initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestSoundPermission: true,
          requestBadgePermission: true,
          requestAlertPermission: true,
        );
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onNotificationTapped,
    );
    
    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      AppConfig.notificationChannelId,
      AppConfig.notificationChannelName,
      description: AppConfig.notificationChannelDescription,
      importance: Importance.max,
    );
    
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    
    print('✅ Local notification plugin initialized');
  }
  
  // Start listening for new notifications
  static Future<void> startNotificationListener() async {
    // Try WebSocket connection first
    try {
      await connectWebSocket();
    } catch (e) {
      print('⚠️ WebSocket connection failed, falling back to polling: $e');
      startPolling();
    }
  }
  
  // Connect to WebSocket for real-time notifications
  static Future<void> connectWebSocket() async {
    // Prevent multiple simultaneous connections
    if (_isConnecting || _isConnected) {
      print('🔄 WebSocket connection already in progress or established');
      return;
    }
    
    _isConnecting = true;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('auth_token');
      
      if (authToken == null) {
        print('❌ No auth token found for WebSocket connection');
        _isConnecting = false;
        return;
      }

      // Close existing connection if any
      if (_websocketChannel != null) {
        print('🔌 Closing existing WebSocket connection');
        await _closeWebSocket();
      }

      print('🔌 Attempting WebSocket connection...');
      final wsUrl = Uri.parse(AppConfig.websocketUrl);
      _websocketChannel = WebSocketChannel.connect(wsUrl);
      
      // Send authentication message immediately after connection
      _websocketChannel!.sink.add(json.encode({
        'type': 'authenticate',
        'token': authToken,
      }));
      
      _websocketChannel!.stream.listen(
        (data) {
          print('📨 Received WebSocket message: $data');
          handleWebSocketMessage(data); // Fire and forget - don't await in stream listener
        },
        onError: (error) {
          print('❌ WebSocket error: $error');
          _handleWebSocketDisconnection();
        },
        onDone: () {
          print('🔌 WebSocket connection closed');
          _handleWebSocketDisconnection();
        },
      );
      
      print('🔌 WebSocket connection initiated');
    } catch (e) {
      print('❌ WebSocket connection failed: $e');
      _isConnecting = false;
      _scheduleReconnection();
      rethrow;
    }
  }

  // Handle WebSocket disconnection with exponential backoff
  static void _handleWebSocketDisconnection() {
    _isConnected = false;
    _isConnecting = false;
    
    // Cancel heartbeat if active
    _heartbeatTimer?.cancel();
    
    // Schedule reconnection with exponential backoff
    _scheduleReconnection();
  }

  // Close WebSocket connection cleanly
  static Future<void> _closeWebSocket() async {
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    
    if (_websocketChannel != null) {
      await _websocketChannel!.sink.close();
      _websocketChannel = null;
    }
    
    _isConnected = false;
    _isConnecting = false;
  }

  // Schedule reconnection with exponential backoff
  static void _scheduleReconnection() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      print('📵 Max reconnection attempts reached, falling back to polling');
      startPolling();
      return;
    }
    
    _reconnectTimer?.cancel();
    
    final delay = Duration(seconds: (2 * _reconnectAttempts + 1).clamp(1, 30));
    print('🔄 Scheduling WebSocket reconnection in ${delay.inSeconds} seconds (attempt ${_reconnectAttempts + 1})');
    
    _reconnectTimer = Timer(delay, () {
      _reconnectAttempts++;
      connectWebSocket();
    });
  }
  
  // Handle WebSocket messages (including auth responses and notifications)
  static Future<void> handleWebSocketMessage(dynamic data) async {
    try {
      final Map<String, dynamic> message = json.decode(data);
      
      if (message['type'] == 'auth_success') {
        print('✅ WebSocket authentication successful');
        _isConnected = true;
        _isConnecting = false;
        _reconnectAttempts = 0; // Reset reconnect attempts on successful connection
        // Start heartbeat after successful authentication
        _setupHeartbeat();
      } else if (message['type'] == 'auth_error') {
        print('❌ WebSocket authentication failed: ${message['message']}');
        _isConnected = false;
        _isConnecting = false;
        // Fallback to polling
        startPolling();
      } else if (message['type'] == 'notification') {
        // Handle actual notification
        final notificationData = message['data'];
        try {
          await showLocalNotification(
            title: notificationData['title'] ?? 'New Notification',
            body: notificationData['message'] ?? '',
            payload: json.encode(notificationData),
          );
        } catch (e) {
          print('❌ Error handling WebSocket notification: $e');
        }
      } else if (message['type'] == 'pong') {
        // Server responded to our ping
        print('💓 Received WebSocket pong from server');
      } else if (message['type'] == 'ping') {
        // Respond to server ping with pong
        if (_websocketChannel != null && _isConnected) {
          _websocketChannel!.sink.add(json.encode({
            'type': 'pong',
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          }));
        }
      } else {
        print('⚠️ Unknown WebSocket message type: ${message['type']}');
      }
    } catch (e) {
      print('❌ Error handling WebSocket message: $e');
    }
  }

  // Set up heartbeat to keep connection alive
  static void _setupHeartbeat() {
    _cancelHeartbeat(); // Cancel any existing heartbeat
    
    _heartbeatTimer = Timer.periodic(Duration(seconds: 25), (timer) {
      if (_websocketChannel != null && _websocketChannel!.closeCode == null) {
        _websocketChannel!.sink.add(json.encode({
          'type': 'ping',
          'timestamp': DateTime.now().toIso8601String(),
        }));
        print('💓 Sent WebSocket heartbeat');
      } else {
        timer.cancel();
      }
    });
  }

  // Cancel heartbeat timer
  static void _cancelHeartbeat() {
    if (_heartbeatTimer != null && _heartbeatTimer!.isActive) {
      _heartbeatTimer!.cancel();
      _heartbeatTimer = null;
    }
  }
  
  // Start polling for notifications (fallback method)
  static void startPolling() {
    if (_pollingTimer != null && _pollingTimer!.isActive) {
      _pollingTimer!.cancel();
    }
    
    _pollingTimer = Timer.periodic(
      Duration(seconds: AppConfig.notificationPollingInterval),
      (_) => checkForNewNotifications(),
    );
    
    print('� Started notification polling every ${AppConfig.notificationPollingInterval} seconds');
    
    // Check immediately
    checkForNewNotifications();
  }
  
  // Check for new notifications via API polling
  static Future<void> checkForNewNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('auth_token');
      
      if (authToken == null) {
        print('❌ No auth token found for polling');
        return;
      }
      
      final response = await http.get(
        Uri.parse('${AppConfig.notificationPollingEndpoint}?since=${_lastNotificationId ?? '0'}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] && data['data']['new_notifications'].isNotEmpty) {
          final notifications = data['data']['new_notifications'] as List;
          
          for (final notification in notifications) {
            await showLocalNotification(
              title: notification['title'] ?? 'New Notification',
              body: notification['notification_description'] ?? '',
              payload: json.encode(notification),
            );
            
            // Update last notification ID
            _lastNotificationId = notification['notification_id'].toString();
          }
          
          // Store last notification ID
          await prefs.setString('last_notification_id', _lastNotificationId ?? '0');
        }
      }
    } catch (e) {
      print('❌ Error polling for notifications: $e');
    }
  }
  
  // Show local notification with professional styling
  static Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    // Ensure the notification service is initialized
    if (!_isInitialized) {
      print('⚠️ Local notification service not initialized, initializing now...');
      await initialize();
    }

    // Parse payload to get notification type for custom styling
    String notificationType = 'default';
    String emoji = '🔔';
    
    if (payload != null) {
      try {
        final data = json.decode(payload);
        notificationType = data['type'] ?? 'default';
        emoji = data['emoji'] ?? '🔔';
      } catch (e) {
        print('Could not parse notification payload: $e');
      }
    }

    // Professional Android notification styling
    AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      AppConfig.notificationChannelId,
      AppConfig.notificationChannelName,
      channelDescription: AppConfig.notificationChannelDescription,
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      ledColor: _getNotificationColor(notificationType),
      ledOnMs: 1000,
      ledOffMs: 500,
      // Professional vibration pattern
      vibrationPattern: _getVibrationPattern(notificationType),
      // Professional styling
      styleInformation: BigTextStyleInformation(
        body,
        htmlFormatBigText: true,
        contentTitle: '$emoji $title',
        htmlFormatContentTitle: true,
        summaryText: 'Yanship Premium',
        htmlFormatSummaryText: true,
      ),
      // Action buttons for different notification types
      actions: _getNotificationActions(notificationType),
      category: AndroidNotificationCategory.message,
      visibility: NotificationVisibility.public,
      ticker: '$title - Yanship',
      // Add some personality with subText
      subText: _getNotificationSubText(notificationType),
      // Make it fullscreen for important notifications
      fullScreenIntent: notificationType.contains('order') ? true : false,
      // Group notifications by type
      groupKey: 'yanship_$notificationType',
      setAsGroupSummary: false,
      // Auto cancel after tap
      autoCancel: true,
      // Keep notification for important types
      ongoing: false,
      // Default system sound is better than custom
    );
    
    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          subtitle: 'Yanship',
          threadIdentifier: 'yanship_notifications',
        );
    
    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );
    
    try {
      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        '$emoji $title',
        body,
        platformChannelSpecifics,
        payload: payload,
      );
      
      print('📱 Professional notification shown: $title');
    } catch (e) {
      print('❌ Error showing local notification: $e');
      // Try to reinitialize and show again
      try {
        await initializeLocalNotifications();
        await _localNotifications.show(
          DateTime.now().millisecondsSinceEpoch.remainder(100000),
          '$emoji $title',
          body,
          platformChannelSpecifics,
          payload: payload,
        );
        print('✅ Notification shown after reinitializing');
      } catch (retryError) {
        print('❌ Failed to show notification even after retry: $retryError');
      }
    }
  }

  // Get vibration pattern based on type
  static Int64List _getVibrationPattern(String type) {
  // Only password change notification
  return Int64List.fromList([0, 200, 100, 200, 100, 200]); // Alert pattern
  }

  // Get notification subtext based on type
  static String _getNotificationSubText(String type) {
  // Only password change notification
  return 'Security Alert';
  }

  // Get notification color based on type
  static Color _getNotificationColor(String type) {
  // Only password change notification
  return const Color(0xFFFF5722); // Orange for security
  }

  // Get notification actions based on type
  static List<AndroidNotificationAction>? _getNotificationActions(String type) {
    // Only password change notification
    return [
      const AndroidNotificationAction(
        'open_app',
        '📱 Open Yanship',
        showsUserInterface: true,
      ),
    ];
  }
  
  // Handle notification tap
  static void onNotificationTapped(NotificationResponse response) {
    print('🎯 Notification tapped: ${response.payload}');
    
    if (response.payload != null) {
      try {
        final data = json.decode(response.payload!);
        handleNotificationNavigation(data);
      } catch (e) {
        print('❌ Error parsing notification payload: $e');
      }
    }
  }
  
  // Handle navigation based on notification type
  static void handleNotificationNavigation(Map<String, dynamic> data) {
    print('🧭 Handling notification navigation: ${data['type']}');
    
    // This would typically use a navigation service or global navigator
    // Only password change notification: navigate to home or security page
    print('🏠 Navigating to home (password changed)');
  }
  
  // Test local notification
  static Future<void> sendTestNotification() async {
    await showLocalNotification(
      title: 'Test Notification',
      body: 'This is a test notification from Yanship!',
      payload: json.encode({'type': 'test', 'timestamp': DateTime.now().toIso8601String()}),
    );
  }
  
  // Request notification permissions (for iOS mainly)
  static Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      return status.isGranted;
    } else if (Platform.isIOS) {
      final bool? result = await _localNotifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return result ?? true;
    } else {
      return true;
    }
  }

  // Check if notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      return status.isGranted;
    } else if (Platform.isIOS) {
      final settings = await _localNotifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.checkPermissions();
      return settings?.isEnabled ?? true;
    } else {
      return true;
    }
  }
  
  // Stop notification service
  static void stop() {
    _pollingTimer?.cancel();
    _websocketChannel?.sink.close();
    _isInitialized = false;
    print('🛑 Notification service stopped');
  }
  
  // Resume notification service
  static Future<void> resume() async {
    if (!_isInitialized) {
      await initialize();
    }
  }
}
