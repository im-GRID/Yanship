import 'package:flutter/foundation.dart';
import '../services/notification_service.dart';

class NotificationProvider with ChangeNotifier {
  int _unreadCount = 0;
  bool _isLoading = false;

  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  // Load unread notification count
  Future<void> loadUnreadCount() async {
    _isLoading = true;
    notifyListeners();

    try {
      final count = await NotificationService.getUnreadCount();
      _unreadCount = count;
    } catch (e) {
      print('Error loading unread count: $e');
      // Keep the previous count on error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Manually update unread count (e.g., when a notification is read)
  void updateUnreadCount(int newCount) {
    _unreadCount = newCount;
    notifyListeners();
  }

  // Decrease unread count by one (when a notification is marked as read)
  void decrementUnreadCount() {
    if (_unreadCount > 0) {
      _unreadCount--;
      notifyListeners();
    }
  }

  // Reset unread count to zero (when all notifications are marked as read)
  void clearUnreadCount() {
    _unreadCount = 0;
    notifyListeners();
  }

  // Refresh unread count from server
  Future<void> refresh() async {
    await loadUnreadCount();
  }
}
