import express from 'express';
import { authenticateToken } from '../middleware/auth.js';
import {
  getNotifications,
  getUnreadCount,
  markAsRead,
  markAllAsRead,
  deleteNotification,
  pollNotifications,
  getPushPreferences,
  updatePushPreferences
} from '../controllers/notificationController.js';

const router = express.Router();

// All routes require authentication
router.use(authenticateToken);

// GET /api/notifications - Get all notifications for user
router.get('/', getNotifications);

// GET /api/notifications/poll - Poll for new notifications
router.get('/poll', pollNotifications);

// GET /api/notifications/unread-count - Get unread notification count
router.get('/unread-count', getUnreadCount);

// PUT /api/notifications/:notification_id/read - Mark notification as read
router.put('/:notification_id/read', markAsRead);

// PUT /api/notifications/mark-all-read - Mark all notifications as read
router.put('/mark-all-read', markAllAsRead);

// DELETE /api/notifications/:notification_id - Delete a notification
router.delete('/:notification_id', deleteNotification);

// GET /api/notifications/push-preferences - Get user's push notification preferences
router.get('/push-preferences', getPushPreferences);

// PUT /api/notifications/push-preferences - Update user's push notification preferences
router.put('/push-preferences', updatePushPreferences);

export default router;
