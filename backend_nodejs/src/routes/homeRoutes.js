import express from 'express';
import { 
  getHomeOrders, 
  bulkUpdateOrderStatus, 
  getDashboardStats, 
  printLabels,
  quickActions 
} from '../controllers/homeController.js';
import { authenticateToken } from '../middleware/auth.js';

const router = express.Router();


router.use(authenticateToken);

router.get('/orders', getHomeOrders);

/**
 * GET /api/home/stats
 * Get dashboard statistics for home page
 */
router.get('/stats', getDashboardStats);

/**
 * PUT /api/home/orders/bulk-update
 * Bulk update order status (for selection mode)
 * Body: {
 *   orderIds: number[],
 *   newStatus?: string,
 *   action?: string ('pickup_confirmed')
 * }
 */
router.put('/orders/bulk-update', bulkUpdateOrderStatus);

/**
 * POST /api/home/print-labels
 * Print labels for selected orders
 * Body: {
 *   orderIds: number[],
 *   printType?: string ('bon_de_reception', 'shipping_label')
 * }
 */
router.post('/print-labels', printLabels);

/**
 * POST /api/home/quick-actions
 * Execute quick actions like "pickup all confirmed"
 * Body: {
 *   action: string ('pickup_all_confirmed')
 * }
 */
router.post('/quick-actions', quickActions);

export default router;
