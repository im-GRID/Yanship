import express from 'express';
import pool from '../config/database.js';
import {
  createOrder,
  getUserOrders,
  getUserOrdersWithHistory,
  getOrderById,
  updateOrder,
  deleteOrder,
  getOrderByTracking,
  updateOrderStatus,
  getAllOrders,
  getRecentOrders,
  getRecentOrdersWithHistory,
  getUserDashboard,
  debugOrders,
  addOrderStatusHistory,
  getOrderHistory,
  bulkPickupOrders
} from '../controllers/ordersController.js';
import { authenticateToken } from '../middleware/auth.js';

const router = express.Router();

// Public routes
router.get('/track/:trackingNumber', getOrderByTracking);
router.get('/table-info', async (req, res) => {
  try {
    const [columns] = await pool.execute("DESCRIBE cdb_add_order");
    res.json({
      success: true,
      tableStructure: columns
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
});

// Protected routes (require authentication)
router.use(authenticateToken);

// Debug endpoint
router.get('/debug', debugOrders);                 // Debug orders and table info

// User dashboard and recent orders (for home page)
router.get('/dashboard', getUserDashboard);        // Get dashboard stats + recent orders
router.get('/recent', getRecentOrders);            // Get recent orders only
router.get('/recent/history', getRecentOrdersWithHistory); // Get recent orders with status history

// User order routes
router.post('/', createOrder);                     // Create new order
router.get('/', getUserOrders);                    // Get user's orders (with pagination)
router.get('/history', getUserOrdersWithHistory);  // Get user's orders with status history
router.get('/:id', getOrderById);                  // Get specific order by ID
router.get('/:id/history', getOrderHistory);       // Get order history by ID
router.put('/:id', updateOrder);                  // Update order
router.delete('/:id', deleteOrder);               // Delete order

// Order history management
router.post('/:orderId/history', addOrderStatusHistory); // Add status history entry

// Admin routes (you might want to add role-based middleware later)
router.get('/admin/all', getAllOrders);           // Get all orders (admin)
router.put('/:id/status', updateOrderStatus);     // Update order status (admin)
router.post('/bulk-pickup', bulkPickupOrders);    // Bulk pickup all confirmed orders

export default router;
