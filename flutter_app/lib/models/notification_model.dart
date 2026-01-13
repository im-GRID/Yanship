class NotificationModel {
  final int notificationId;
  final int userId;
  final int? orderId;
  final String title;
  final String notificationDescription;
  final String shippingType;
  final DateTime notificationDate;
  final bool isRead;
  final String? trackingNumber;
  final String? orderStatus;

  NotificationModel({
    required this.notificationId,
    required this.userId,
    this.orderId,
    required this.title,
    required this.notificationDescription,
    required this.shippingType,
    required this.notificationDate,
    required this.isRead,
    this.trackingNumber,
    this.orderStatus,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      notificationId: _parseToInt(json['notification_id']) ?? 0,
      userId: _parseToInt(json['user_id']) ?? 0,
      orderId: _parseToInt(json['order_id']),
      title: _parseToString(json['title']) ?? '',
      notificationDescription: _parseToString(json['notification_description']) ?? '',
      shippingType: _parseToString(json['shipping_type']) ?? 'general',
      notificationDate: DateTime.parse(json['notification_date'] ?? DateTime.now().toIso8601String()),
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      trackingNumber: _parseToString(json['tracking_number']),
      orderStatus: _parseToString(json['order_status']),
    );
  }

  // Helper method to safely parse to int
  static int? _parseToInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  // Helper method to safely parse to string
  static String? _parseToString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'notification_id': notificationId,
      'user_id': userId,
      'order_id': orderId,
      'title': title,
      'notification_description': notificationDescription,
      'shipping_type': shippingType,
      'notification_date': notificationDate.toIso8601String(),
      'is_read': isRead,
      'tracking_number': trackingNumber,
      'order_status': orderStatus,
    };
  }

  // Helper methods for UI
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(notificationDate);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  // Get icon based on notification type
  String get iconType {
    switch (shippingType.toLowerCase()) {
      case 'order_created':
      case 'order':
        return 'add_circle';
      case 'order_status':
      case 'delivery':
        return 'local_shipping';
      case 'profile':
      case 'profile_update':
        return 'person';
      case 'password_change':
        return 'lock';
      case 'avatar_update':
        return 'photo_camera';
      case 'payment':
        return 'payment';
      default:
        return 'notifications';
    }
  }

  // Get color based on notification type
  String get colorType {
    switch (shippingType.toLowerCase()) {
      case 'order_created':
      case 'order':
        return 'orange';
      case 'order_status':
      case 'delivery':
        return 'blue';
      case 'profile':
      case 'profile_update':
        return 'purple';
      case 'password_change':
        return 'red';
      case 'avatar_update':
        return 'green';
      case 'payment':
        return 'teal';
      default:
        return 'grey';
    }
  }

  NotificationModel copyWith({
    int? notificationId,
    int? userId,
    int? orderId,
    String? title,
    String? notificationDescription,
    String? shippingType,
    DateTime? notificationDate,
    bool? isRead,
    String? trackingNumber,
    String? orderStatus,
  }) {
    return NotificationModel(
      notificationId: notificationId ?? this.notificationId,
      userId: userId ?? this.userId,
      orderId: orderId ?? this.orderId,
      title: title ?? this.title,
      notificationDescription: notificationDescription ?? this.notificationDescription,
      shippingType: shippingType ?? this.shippingType,
      notificationDate: notificationDate ?? this.notificationDate,
      isRead: isRead ?? this.isRead,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      orderStatus: orderStatus ?? this.orderStatus,
    );
  }
}

class NotificationResponse {
  final bool success;
  final List<NotificationModel> notifications;
  final int unreadCount;
  final Map<String, dynamic> pagination;
  final String? message;

  NotificationResponse({
    required this.success,
    required this.notifications,
    required this.unreadCount,
    required this.pagination,
    this.message,
  });

  factory NotificationResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    final notificationsList = data['notifications'] as List<dynamic>? ?? [];
    
    return NotificationResponse(
      success: json['success'] ?? false,
      notifications: notificationsList
          .map((item) => NotificationModel.fromJson(item))
          .toList(),
      unreadCount: data['unread_count'] ?? 0,
      pagination: data['pagination'] ?? {},
      message: json['message'],
    );
  }
}
