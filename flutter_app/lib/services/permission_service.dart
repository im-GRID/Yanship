// lib/services/permission_service.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'push_notification_service.dart';

class PermissionService {
  // Show permission dialog for camera access
  static Future<bool> requestCameraPermission(BuildContext context) async {
    bool permissionGranted = false;
    
    // Show explanation dialog first
    bool shouldRequest = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 0.0),
          title: const Row(
            children: [
              Icon(Icons.camera_alt, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Allow Camera Access?',
                  style: TextStyle(fontSize: 18),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Camera access helps you:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                const Text(
                  '• Set profile pictures\n'
                  '• Document packages\n'
                  '• Verify deliveries',
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Deny', style: TextStyle(fontSize: 14)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('Allow', style: TextStyle(fontSize: 14)),
            ),
          ],
        );
      },
    );

    if (shouldRequest) {
      try {
        // Try to use the camera to test permission
        final ImagePicker picker = ImagePicker();
        final XFile? testImage = await picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 1,
        ).catchError((error) {
          // Permission was denied
          return null;
        });
        
        permissionGranted = testImage != null;
        
        // If we got an image, we don't need it for the test
        if (testImage != null) {
          try {
            await File(testImage.path).delete();
          } catch (e) {
            // Ignore cleanup errors
          }
        }
      } catch (e) {
        permissionGranted = false;
      }
      
      // Show result dialog
      if (!permissionGranted && context.mounted) {
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              contentPadding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 0.0),
              title: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Camera Access Denied',
                      style: TextStyle(fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'You can enable camera access later in device settings.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK', style: TextStyle(fontSize: 14)),
                ),
              ],
            );
          },
        );
      }
    }
    
    return permissionGranted;
  }

  // Show permission dialog for notifications
  static Future<bool> requestNotificationPermission(BuildContext context) async {
    bool permissionGranted = false;
    
    // Show explanation dialog first
    bool shouldRequest = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 0.0),
          title: const Row(
            children: [
              Icon(Icons.notifications, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Allow Notifications?',
                  style: TextStyle(fontSize: 18),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Stay updated with:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                const Text(
                  '• Order status updates\n'
                  '• Delivery notifications\n'
                  '• Important messages',
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Not Now', style: TextStyle(fontSize: 14)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('Allow', style: TextStyle(fontSize: 14)),
            ),
          ],
        );
      },
    );

    if (shouldRequest) {
      // Mark that we've requested permission
      await markNotificationPermissionAsRequested();
      
      // Import the notification service and request permissions
      try {
        permissionGranted = await LocalNotificationService.requestPermissions();
      } catch (e) {
        permissionGranted = false;
      }
      
      // Show result for denied permissions
      if (!permissionGranted && context.mounted) {
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              contentPadding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 0.0),
              title: const Row(
                children: [
                  Icon(Icons.info, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Notifications Disabled',
                      style: TextStyle(fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'You can enable notifications later in device settings.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK', style: TextStyle(fontSize: 14)),
                ),
              ],
            );
          },
        );
      } else if (permissionGranted && context.mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('✅ Notifications enabled successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
    
    return permissionGranted;
  }

  // Request both permissions during onboarding
  static Future<Map<String, bool>> requestAllPermissions(BuildContext context) async {
    Map<String, bool> results = {};
    
    // Request notification permission first
    results['notifications'] = await requestNotificationPermission(context);
    
    // Small delay between requests
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Request camera permission
    results['camera'] = await requestCameraPermission(context);
    
    return results;
  }

  // Check if we should show permission requests (first time users)
  static bool shouldRequestPermissions() {
    // Add logic here to check if permissions were already requested
    // For now, always request on first app launch
    return true;
  }

  // Check notification permission status
  static Future<bool> hasNotificationPermission() async {
    try {
      // Check if notifications are enabled
      bool enabled = await LocalNotificationService.areNotificationsEnabled();
      
      // On Android, local notifications don't require explicit permission
      // but we should still check if they're enabled in system settings
      if (Platform.isAndroid) {
        // For Android, also check if the notification channel is enabled
        // This is a more reliable way to check on Android
        return enabled;
      } else {
        // For iOS, this checks the actual permission status
        return enabled;
      }
    } catch (e) {
      print('Error checking notification permission: $e');
      // On error, assume permission is needed (safer approach)
      return false;
    }
  }

  // Check if notification permission was previously requested and denied
  static Future<bool> wasNotificationPermissionDenied() async {
    try {
      // Use SharedPreferences to track if permission was requested before
      final prefs = await SharedPreferences.getInstance();
      final wasRequested = prefs.getBool('notification_permission_requested') ?? false;
      final hasPermission = await hasNotificationPermission();
      
      // If it was requested but permission is not granted, it was likely denied
      return wasRequested && !hasPermission;
    } catch (e) {
      return false;
    }
  }

  // Mark notification permission as requested
  static Future<void> markNotificationPermissionAsRequested() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notification_permission_requested', true);
    } catch (e) {
      print('Error marking notification permission as requested: $e');
    }
  }

  // Reset notification permission request status (for settings/manual re-request)
  static Future<void> resetNotificationPermissionStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('notification_permission_requested');
      print('🔄 Notification permission status reset');
    } catch (e) {
      print('Error resetting notification permission status: $e');
    }
  }

  // Force request notification permission (for manual re-request from settings)
  static Future<bool> forceRequestNotificationPermission(BuildContext context) async {
    // Reset the status first so it can be requested again
    await resetNotificationPermissionStatus();
    // Then request permission normally
    return await requestNotificationPermission(context);
  }
}
