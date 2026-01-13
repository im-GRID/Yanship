
import { Notification as NotificationModel } from '../../models/Notifications.js';
import { sendNotificationToUser } from '../server.js';
import pool from '../config/database.js';

// Get all notifications for the authenticated user
export const getNotifications = async (req, res) => {
  try {
    const userId = req.user.id;
    const limit = parseInt(req.query.limit) || 20;
    const offset = parseInt(req.query.offset) || 0;

    const notifications = await NotificationModel.getByUserId(userId, limit, offset);
    const unreadCount = await NotificationModel.getUnreadCount(userId);

    res.json({
      success: true,
      data: {
        notifications,
        unread_count: unreadCount,
        pagination: {
          limit,
          offset,
          total: notifications.length
        }
      }
    });
  } catch (error) {
    console.error('Error fetching notifications:', error.message);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch notifications'
    });
  }
};

// Get unread notification count
export const getUnreadCount = async (req, res) => {
  try {
    const userId = req.user.id;
    const unreadCount = await NotificationModel.getUnreadCount(userId);

    res.json({
      success: true,
      data: {
        unread_count: unreadCount
      }
    });
  } catch (error) {
    console.error('Error fetching unread count:', error.message);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch unread count'
    });
  }
};

// Mark a notification as read
export const markAsRead = async (req, res) => {
  try {
    const userId = req.user.id;
    const { notification_id } = req.params;

    const success = await NotificationModel.markAsRead(notification_id, userId);

    if (success) {
      res.json({
        success: true,
        message: 'Notification marked as read'
      });
    } else {
      res.status(404).json({
        success: false,
        message: 'Notification not found or already read'
      });
    }
  } catch (error) {
    console.error('Error marking notification as read:', error.message);
    res.status(500).json({
      success: false,
      message: 'Failed to mark notification as read'
    });
  }
};

// Mark all notifications as read
export const markAllAsRead = async (req, res) => {
  try {
    const userId = req.user.id;

    const affectedRows = await NotificationModel.markAllAsRead(userId);

    res.json({
      success: true,
      message: `${affectedRows} notifications marked as read`,
      data: {
        affected_count: affectedRows
      }
    });
  } catch (error) {
    console.error('Error marking all notifications as read:', error.message);
    res.status(500).json({
      success: false,
      message: 'Failed to mark all notifications as read'
    });
  }
};

// Delete a notification
export const deleteNotification = async (req, res) => {
  try {
    const userId = req.user.id;
    const { notification_id } = req.params;

    // Delete the notification from database using direct SQL
    const [result] = await pool.execute(
      'DELETE FROM cdb_notifications WHERE notification_id = ? AND user_id = ?',
      [notification_id, userId]
    );

    if (result.affectedRows > 0) {
      res.json({
        success: true,
        message: 'Notification deleted successfully'
      });
    } else {
      res.status(404).json({
        success: false,
        message: 'Notification not found'
      });
    }
  } catch (error) {
    console.error('Error deleting notification:', error.message);
    res.status(500).json({
      success: false,
      message: 'Failed to delete notification'
    });
  }
};

// Helper function to trigger notifications (used by other controllers)
export const triggerNotification = async (userId, type, data = {}) => {
  try {
    console.log(`🔔 Triggering notification for user ${userId}, type: ${type}, data:`, JSON.stringify(data, null, 2));
    
    // Check if user has push notifications enabled
    const [userSettings] = await pool.execute(
      'SELECT push_enabled FROM cdb_users WHERE id = ? LIMIT 1',
      [userId]
    );

    const pushEnabled = userSettings.length > 0 ? userSettings[0].push_enabled === 1 : true;
    console.log(`📱 Push notifications enabled for user ${userId}:`, pushEnabled);

    let createdNotification = null;

    const notificationTypes = {
      'password_changed': () => NotificationModel.createProfileNotification(
        userId, NotificationModel.TYPES.PASSWORD_CHANGED
      ),
      'push_enabled': () => NotificationModel.create({
        user_id: userId,
        title: 'Notifications Enabled',
        notification_description: 'You will now receive updates about your orders and account activities.',
        shipping_type: 'system'
      })
    };

    if (notificationTypes[type]) {
      console.log(`✅ Creating notification of type: ${type}`);
      createdNotification = await notificationTypes[type]();
      console.log(`✅ Notification created successfully:`, createdNotification);
    } else {
      console.log(`⚠️ Unknown notification type: ${type}, skipping notification creation.`);
      return;
    }

    // Send WebSocket notification if user has push notifications enabled
    if (createdNotification && sendNotificationToUser && pushEnabled) {
      console.log(`📡 Sending WebSocket notification to user ${userId}`);
      const getStatusName = (statusCode) => {
        const statusMap = {
          '1': 'Created',
          '10': 'Confirmed', 
          '24': 'In Transit',
          '25': 'Picked Up',
          '26': 'Out for Delivery',
          '27': 'Attempted Delivery',
          '28': 'Delivered',
          '29': 'Returned',
          '3': 'Cancelled',
          '5': 'Rejected',
        
          1: 'Created',
          10: 'Confirmed', 
          24: 'In Transit',
          25: 'Picked Up',
          26: 'Out for Delivery',
          27: 'Attempted Delivery',
          28: 'Delivered',
          29: 'Returned',
          3: 'Cancelled',
          5: 'Rejected'
        };
        return statusMap[statusCode] || statusMap[statusCode?.toString()] || `Status ${statusCode}`;
      };

      // Only send password change and push enabled notifications
      if (type === 'password_changed') {
        sendNotificationToUser(userId, {
          id: createdNotification.id || createdNotification,
          title: 'Password Changed',
          message: 'Your password has been updated successfully.',
          type: type,
          timestamp: new Date().toISOString(),
          emoji: '�',
          data: {
            ...data,
            original_title: createdNotification.title,
            original_description: createdNotification.notification_description
          }
        });
        console.log(`✅ WebSocket notification sent successfully to user ${userId}`);
      } else if (type === 'push_enabled') {
        sendNotificationToUser(userId, {
          id: createdNotification.id || createdNotification,
          title: 'Notifications Enabled',
          message: 'You will now receive updates about your orders and account activities.',
          type: type,
          timestamp: new Date().toISOString(),
          emoji: '�',
          data: {
            ...data,
            original_title: createdNotification.title,
            original_description: createdNotification.notification_description
          }
        });
        console.log(`✅ WebSocket notification sent successfully to user ${userId}`);
      }
    } else {
      console.log(`❌ WebSocket notification NOT sent. Conditions: createdNotification=${!!createdNotification}, sendNotificationToUser=${!!sendNotificationToUser}, pushEnabled=${pushEnabled}`);
    }
  } catch (error) {
    console.error('❌ Error triggering notification:', error.message);
    console.error('Full error:', error);
    // Don't throw error - notifications shouldn't break main functionality
  }
};

// Poll for new notifications (for real-time updates without WebSocket)
export const pollNotifications = async (req, res) => {
  try {
    const userId = req.user.id;
    const since = req.query.since || '0';

    // Get notifications newer than the 'since' ID
    const [notifications] = await pool.execute(
      `SELECT 
         n.notification_id,
         n.user_id,
         n.order_id,
         n.title,
         n.notification_description,
         n.shipping_type,
         n.notification_date,
         n.is_read,
         o.order_no as tracking_number,
         o.status_courier as order_status
       FROM cdb_notifications n
       LEFT JOIN cdb_add_order o ON n.order_id = o.order_id
       WHERE n.user_id = ? AND n.notification_id > ?
       ORDER BY n.notification_date DESC
       LIMIT 10`,
      [userId, since]
    );

    res.json({
      success: true,
      data: {
        new_notifications: notifications,
        count: notifications.length
      }
    });
  } catch (error) {
    console.error('Error polling notifications:', error.message);
    res.status(500).json({
      success: false,
      message: 'Failed to poll notifications'
    });
  }
};

// Get user's push notification preferences
export const getPushPreferences = async (req, res) => {
  try {
    const userId = req.user.id;

    // Get user's push preference from cdb_users table
    const [preferences] = await pool.execute(
      'SELECT push_enabled FROM cdb_users WHERE id = ? LIMIT 1',
      [userId]
    );

    if (preferences.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }
    
    const pushEnabled = preferences[0].push_enabled === 1;

    res.json({
      success: true,
      data: {
        push_enabled: pushEnabled
      }
    });
  } catch (error) {
    console.error('Error getting push preferences:', error.message);
    res.status(500).json({
      success: false,
      message: 'Failed to get push preferences'
    });
  }
};

// Update user's push notification preferences
export const updatePushPreferences = async (req, res) => {
  try {
    const userId = req.user.id;
    const { push_enabled } = req.body;
    
    if (typeof push_enabled !== 'boolean') {
      return res.status(400).json({
        success: false,
        message: 'push_enabled must be a boolean value'
      });
    }

    // Update push preference in cdb_users table
    const [result] = await pool.execute(
      'UPDATE cdb_users SET push_enabled = ? WHERE id = ?',
      [push_enabled ? 1 : 0, userId]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Send confirmation notification if enabled
    if (push_enabled) {
      // Use setTimeout to ensure the database update is committed before sending notification
      setTimeout(async () => {
        await triggerNotification(userId, 'push_enabled', {
          message: 'You will be receiving notifications from now on!'
        });
      }, 100);
    }

    res.json({
      success: true,
      message: push_enabled ? 
        '🔔 Push notifications enabled! You will receive updates from now on.' : 
        '🔕 Push notifications disabled. You won\'t receive push alerts anymore.',
      data: {
        push_enabled
      }
    });
  } catch (error) {
    console.error('Error updating push preferences:', error.message);
    res.status(500).json({
      success: false,
      message: 'Failed to update push preferences'
    });
  }
};
