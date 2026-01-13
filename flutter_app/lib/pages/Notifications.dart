import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../providers/notification_provider.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  // Static constants for better performance
  static const Color _primaryRed = Color(0xFFE53E3E);
  static const Color _primaryBlue = Color(0xFF3182CE);
  
  Color get primaryRed => _primaryRed;
  Color get primaryBlue => _primaryBlue;

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final response = await NotificationService.getNotifications();
      
      if (response.success) {
        if (mounted) {
          setState(() {
            _notifications = response.notifications;
            _unreadCount = response.unreadCount;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = response.message ?? 'Failed to load notifications';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Network error: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markAllAsRead() async {
    final success = await NotificationService.markAllAsRead();
    
    if (success && mounted) {
      // Update global notification provider
      context.read<NotificationProvider>().clearUnreadCount();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('All notifications marked as read'),
          backgroundColor: primaryBlue,
        ),
      );
      _loadNotifications(); // Reload to update UI
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to mark notifications as read'),
          backgroundColor: primaryRed,
        ),
      );
    }
  }

  Future<void> _markAsRead(int notificationId, int index) async {
    final success = await NotificationService.markAsRead(notificationId);
    
    if (success && mounted) {
      setState(() {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        if (_unreadCount > 0) _unreadCount--;
      });
      
      // Update global notification provider
      context.read<NotificationProvider>().decrementUnreadCount();
    }
  }

  Future<void> _deleteNotification(int notificationId, int index) async {
    final success = await NotificationService.deleteNotification(notificationId);
    
    if (success && mounted) {
      final wasUnread = !_notifications[index].isRead;
      
      setState(() {
        if (wasUnread && _unreadCount > 0) {
          _unreadCount--;
        }
        _notifications.removeAt(index);
      });
      
      // Update global notification provider if deleted notification was unread
      if (wasUnread) {
        context.read<NotificationProvider>().decrementUnreadCount();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notification deleted'),
            backgroundColor: primaryBlue,
          ),
        );
      }
    }
  }

  // Helper method to get icon from string
  IconData _getIconFromString(String iconType) {
    switch (iconType.toLowerCase()) {
      case 'add_circle':
        return Icons.add_circle;
      case 'local_shipping':
        return Icons.local_shipping;
      case 'person':
        return Icons.person;
      case 'lock':
        return Icons.lock;
      case 'photo_camera':
        return Icons.photo_camera;
      case 'payment':
        return Icons.payment;
      case 'verified':
        return Icons.verified;
      case 'check_circle':
        return Icons.check_circle;
      default:
        return Icons.notifications;
    }
  }

  // Helper method to get color from string
  Color _getColorFromString(String colorType) {
    switch (colorType.toLowerCase()) {
      case 'orange':
        return Colors.orange;
      case 'blue':
        return primaryBlue;
      case 'purple':
        return Colors.purple;
      case 'red':
        return primaryRed;
      case 'green':
        return Colors.green;
      case 'teal':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 600;
    final isExtraLargeScreen = screenWidth > 1200;
    
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark 
          ? Color(0xFF0D1117) 
          : Colors.white,
      appBar: AppBar(
        backgroundColor: Theme.of(context).brightness == Brightness.dark 
            ? Color(0xFF0D1117) 
            : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: primaryRed),
          iconSize: isLargeScreen ? 28 : 24,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifications${_unreadCount > 0 ? ' ($_unreadCount)' : ''}',
          style: TextStyle(
            color: primaryRed,
            fontWeight: FontWeight.bold,
            fontSize: isLargeScreen ? 24 : 20,
          ),
        ),
        centerTitle: !isLargeScreen, // Left align on large screens
        actions: [
          IconButton(
            icon: Icon(Icons.mark_email_read, color: primaryBlue),
            iconSize: isLargeScreen ? 28 : 24,
            onPressed: _markAllAsRead,
            tooltip: 'Mark all as read',
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: primaryBlue),
            iconSize: isLargeScreen ? 28 : 24,
            onPressed: _loadNotifications,
            tooltip: 'Refresh notifications',
          ),
          if (isLargeScreen) SizedBox(width: 16),
        ],
      ),
      body: _buildResponsiveBody(context, isLargeScreen, isExtraLargeScreen),
    );
  }

  Widget _buildResponsiveBody(BuildContext context, bool isLargeScreen, bool isExtraLargeScreen) {
    if (isExtraLargeScreen) {
      // Extra large screens: Center content with max width
      return Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: 1200),
          child: _buildBody(isLargeScreen),
        ),
      );
    } else if (isLargeScreen) {
      // Large screens: Add horizontal padding
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 48),
        child: _buildBody(isLargeScreen),
      );
    } else {
      // Mobile screens: Full width
      return _buildBody(isLargeScreen);
    }
  }

  Widget _buildBody([bool isLargeScreen = false]) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: primaryRed,
              size: isLargeScreen ? 80 : 64,
            ),
            SizedBox(height: isLargeScreen ? 20 : 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: primaryRed,
                fontSize: isLargeScreen ? 18 : 16,
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadNotifications,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
              ),
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.grey.shade400 
                : Colors.grey,
              size: isLargeScreen ? 80 : 64,
            ),
            SizedBox(height: isLargeScreen ? 20 : 16),
            Text(
              'No notifications yet',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.grey.shade300 
                  : Colors.grey,
                fontSize: isLargeScreen ? 22 : 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: isLargeScreen ? 10 : 8),
            Text(
              'You\'ll see your notifications here',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.grey.shade400 
                  : Colors.grey.shade600,
                fontSize: isLargeScreen ? 16 : 14,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      color: primaryBlue,
      child: ListView.separated(
        padding: EdgeInsets.all(isLargeScreen ? 24 : 16),
        itemCount: _notifications.length,
        separatorBuilder: (_, __) => SizedBox(height: isLargeScreen ? 16 : 12),
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          final isUnread = !notification.isRead;
          
          return Dismissible(
            key: Key(notification.notificationId.toString()),
            direction: DismissDirection.endToStart,
            background: Container(
              decoration: BoxDecoration(
                color: primaryRed,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.centerRight,
              padding: EdgeInsets.only(right: 20),
              child: Icon(
                Icons.delete,
                color: Colors.white,
                size: 24,
              ),
            ),
            onDismissed: (direction) {
              _deleteNotification(notification.notificationId, index);
            },
            child: GestureDetector(
              onTap: () {
                if (!notification.isRead) {
                  _markAsRead(notification.notificationId, index);
                }
              },
              child: Container(
                padding: EdgeInsets.all(isLargeScreen ? 20 : 16),
                decoration: BoxDecoration(
                  color: isUnread 
                    ? (Theme.of(context).brightness == Brightness.dark 
                        ? primaryBlue.withOpacity(0.15) 
                        : primaryBlue.withOpacity(0.05))
                    : (Theme.of(context).brightness == Brightness.dark 
                        ? const Color(0xFF161B22) 
                        : Colors.grey.shade50),
                  borderRadius: BorderRadius.circular(isLargeScreen ? 20 : 16),
                  border: Border.all(
                    color: isUnread 
                      ? primaryBlue.withOpacity(0.3) 
                      : (Theme.of(context).brightness == Brightness.dark 
                          ? const Color(0xFF30363D) 
                          : Colors.grey.shade200),
                    width: isLargeScreen ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        Container(
                          padding: EdgeInsets.all(isLargeScreen ? 16 : 12),
                          decoration: BoxDecoration(
                            color: _getColorFromString(notification.colorType).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getIconFromString(notification.iconType),
                            color: _getColorFromString(notification.colorType),
                            size: isLargeScreen ? 28 : 24,
                          ),
                        ),
                        if (isUnread)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: isLargeScreen ? 14 : 12,
                              height: isLargeScreen ? 14 : 12,
                              decoration: BoxDecoration(
                                color: primaryRed,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Theme.of(context).brightness == Brightness.dark 
                                    ? const Color(0xFF161B22) 
                                    : Colors.white, 
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(width: isLargeScreen ? 20 : 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  notification.title,
                                  style: TextStyle(
                                    fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                                    fontSize: isLargeScreen ? 18 : 16,
                                    color: Theme.of(context).brightness == Brightness.dark 
                                      ? Colors.white 
                                      : Colors.black87,
                                  ),
                                ),
                              ),
                              Text(
                                notification.timeAgo,
                                style: TextStyle(
                                  color: Theme.of(context).brightness == Brightness.dark 
                                    ? Colors.grey.shade400 
                                    : Colors.grey.shade600,
                                  fontSize: isLargeScreen ? 14 : 12,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isLargeScreen ? 6 : 4),
                          Text(
                            notification.notificationDescription,
                            style: TextStyle(
                              color: Theme.of(context).brightness == Brightness.dark 
                                ? Colors.grey.shade300 
                                : Colors.grey.shade700,
                              fontSize: isLargeScreen ? 16 : 14,
                              height: 1.3,
                            ),
                          ),
                          if (notification.trackingNumber != null) ...[
                            SizedBox(height: isLargeScreen ? 10 : 8),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isLargeScreen ? 12 : 8, 
                                vertical: isLargeScreen ? 6 : 4
                              ),
                              decoration: BoxDecoration(
                                color: primaryBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(isLargeScreen ? 16 : 12),
                              ),
                              child: Text(
                                'Order: ${notification.trackingNumber}',
                                style: TextStyle(
                                  color: primaryBlue,
                                  fontSize: isLargeScreen ? 14 : 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

}
