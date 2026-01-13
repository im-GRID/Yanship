import pool from '../src/config/database.js';

export class Notification {
  constructor({
    notification_id = null,
    user_id,
    order_id = null,
    title,
    notification_description,
    shipping_type = 'general',
    notification_date = new Date(),
    is_read = false
  }) {
    this.notification_id = notification_id;
    this.user_id = user_id;
    this.order_id = order_id;
    this.title = title;
    this.notification_description = notification_description;
    this.shipping_type = shipping_type;
    this.notification_date = notification_date;
    this.is_read = is_read;
  }

  // Create a new notification
  static async create({
    user_id,
    order_id = null,
    title,
    notification_description,
    shipping_type = 'general'
  }) {
    try {
      const [result] = await pool.execute(
        `INSERT INTO cdb_notifications 
         (user_id, order_id, title, notification_description, shipping_type, notification_date, is_read) 
         VALUES (?, ?, ?, ?, ?, NOW(), false)`,
        [user_id, order_id, title, notification_description, shipping_type]
      );

      console.log(`✅ Notification created for user ${user_id}:`, title);
      return result.insertId;
    } catch (error) {
      console.error('❌ Error creating notification:', error);
      throw error;
    }
  }

  // Get all notifications for a user
  static async getByUserId(user_id, limit = 50, offset = 0) {
    try {
      const [rows] = await pool.execute(
        `SELECT 
           notification_id,
           user_id,
           order_id,
           title,
           notification_description,
           shipping_type,
           notification_date,
           is_read
         FROM cdb_notifications 
         WHERE user_id = ? 
         ORDER BY notification_date DESC 
         LIMIT ? OFFSET ?`,
        [user_id, limit, offset]
      );

      return rows.map(row => new Notification(row));
    } catch (error) {
      console.error('❌ Error fetching notifications for user:', error);
      throw error;
    }
  }

  // Mark notification as read
  static async markAsRead(notification_id) {
    try {
      const [result] = await pool.execute(
        `UPDATE cdb_notifications 
         SET is_read = true 
         WHERE notification_id = ?`,
        [notification_id]
      );

      return result.affectedRows > 0;
    } catch (error) {
      console.error('❌ Error marking notification as read:', error);
      throw error;
    }
  }

  // Mark all notifications as read for a user
  static async markAllAsRead(user_id) {
    try {
      const [result] = await pool.execute(
        `UPDATE cdb_notifications 
         SET is_read = true 
         WHERE user_id = ? AND is_read = false`,
        [user_id]
      );

      return result.affectedRows;
    } catch (error) {
      console.error('❌ Error marking all notifications as read:', error);
      throw error;
    }
  }

  // Get unread count for a user
  static async getUnreadCount(user_id) {
    try {
      const [rows] = await pool.execute(
        `SELECT COUNT(*) as unread_count 
         FROM cdb_notifications 
         WHERE user_id = ? AND is_read = false`,
        [user_id]
      );

      return rows[0].unread_count;
    } catch (error) {
      console.error('❌ Error getting unread count:', error);
      throw error;
    }
  }

  // Delete a notification
  static async delete(notification_id) {
    try {
      const [result] = await pool.execute(
        `DELETE FROM cdb_notifications WHERE notification_id = ?`,
        [notification_id]
      );

      return result.affectedRows > 0;
    } catch (error) {
      console.error('❌ Error deleting notification:', error);
      throw error;
    }
  }

  // Delete all notifications for a user
  static async deleteAllForUser(user_id) {
    try {
      const [result] = await pool.execute(
        `DELETE FROM cdb_notifications WHERE user_id = ?`,
        [user_id]
      );

      return result.affectedRows;
    } catch (error) {
      console.error('❌ Error deleting all notifications for user:', error);
      throw error;
    }
  }

  // Get notifications by order_id
  static async getByOrderId(order_id) {
    try {
      const [rows] = await pool.execute(
        `SELECT 
           notification_id,
           user_id,
           order_id,
           title,
           notification_description,
           shipping_type,
           notification_date,
           is_read
         FROM cdb_notifications 
         WHERE order_id = ? 
         ORDER BY notification_date DESC`,
        [order_id]
      );

      return rows.map(row => new Notification(row));
    } catch (error) {
      console.error('❌ Error fetching notifications by order ID:', error);
      throw error;
    }
  }

  // Get recent notifications (last 7 days)
  static async getRecent(user_id, days = 7) {
    try {
      const [rows] = await pool.execute(
        `SELECT 
           notification_id,
           user_id,
           order_id,
           title,
           notification_description,
           shipping_type,
           notification_date,
           is_read
         FROM cdb_notifications 
         WHERE user_id = ? 
         AND notification_date >= DATE_SUB(NOW(), INTERVAL ? DAY)
         ORDER BY notification_date DESC`,
        [user_id, days]
      );

      return rows.map(row => new Notification(row));
    } catch (error) {
      console.error('❌ Error fetching recent notifications:', error);
      throw error;
    }
  }

  // Notification types for consistency
  static get TYPES() {
    return {
      ORDER_CREATED: 'order_created',
      ORDER_STATUS_CHANGED: 'order_status',
      PROFILE_UPDATED: 'profile_update',
      PASSWORD_CHANGED: 'password_change',
      AVATAR_UPDATED: 'avatar_update',
      PAYMENT_SUCCESS: 'payment_success',
      DELIVERY_UPDATE: 'delivery_update',
      SYSTEM_MESSAGE: 'system'
    };
  }

  // Helper method to create different types of notifications
  static async createOrderNotification(user_id, order_id, type, orderData = {}) {
   
    const getStatusDisplayName = (status) => {
    
      const statusIdToName = {
        1: 'Created',
        3: 'Cancelled',
        5: 'Rejected',
        10: 'Confirmed',
        24: 'In Transit',
        25: 'Picked up',
        26: 'Out for Delivery',
        27: 'Attempted Delivery',
        28: 'Delivered',
        29: 'Returned',
      };
      
      // If status is a number, convert it using the map
      if (typeof status === 'number') {
        return statusIdToName[status] || `Status ${status}`;
      }
      
      // Handle string status names (legacy support)
      const statusNames = {
        'pending': 'Pending Confirmation',
        'confirmed': 'Confirmed & Processing',
        'created': 'Created',
        'processing': 'Being Prepared',
        'shipped': 'Shipped & In Transit',
        'in_transit': 'In Transit',
        'picked_up': 'Picked up',
        'out_for_delivery': 'Out for Delivery',
        'attempted_delivery': 'Attempted Delivery',
        'delivered': 'Successfully Delivered',
        'cancelled': 'Cancelled',
        'rejected': 'Rejected',
        'returned': 'Returned to Sender'
      };
      
      if (typeof status === 'string') {
        return statusNames[status?.toLowerCase()] || status || 'Processing';
      }
      
      return 'Processing';
    };



    const notification = notifications[type];
    if (notification) {
      return await this.create({
        user_id,
        order_id,
        title: notification.title,
        notification_description: notification.description,
        shipping_type: notification.shipping_type
      });
    }
  }

  static async createProfileNotification(user_id, type, details = {}) {
    const notifications = {
     
      [this.TYPES.PASSWORD_CHANGED]: {
        title: 'Password Changed',
        description: 'Your account password has been updated successfully. If this wasn\'t you, please contact support.',
      },
   
    };

    const notification = notifications[type];
    if (notification) {
      return await this.create({
        user_id,
        title: notification.title,
        notification_description: notification.description,
        shipping_type: 'profile'
      });
    }
  }
}

export default Notification;
