// Client Management Routes
// File: backend_nodejs/src/routes/clientRoutes.js


import express from 'express';
import pool from '../config/database.js';
import { authenticateToken } from '../middleware/auth.js';

const router = express.Router();

// Apply authentication to all client routes
router.use(authenticateToken);

// Get all clients with pagination and filtering
router.get('/clients', async (req, res) => {
  console.log('API /clients request query:', req.query);
  // Debug: log headers and user
  console.log('Headers:', req.headers);
  console.log('req.user:', req.user);
  if (!req.user || !req.user.id) {
    return res.status(401).json({ success: false, message: 'Not authenticated. Please log in.' });
  }
  try {
    const { 
      page = 1, 
      limit = 20, 
      search = '', 
      status = 'all', // all, active, blacklisted
      sortBy = 'created_at',
      sortOrder = 'DESC'
    } = req.query;

    const offset = (page - 1) * limit;
    

  // Only show clients for the current user
  let whereClause = 'c.user_id = ?';
  const queryParams = [req.user.id];

    // Search filter
    if (search) {
      whereClause += ' AND (name LIKE ? OR phone LIKE ? OR company_name LIKE ?)';
      const searchPattern = `%${search}%`;
      queryParams.push(searchPattern, searchPattern, searchPattern);
    }

    // Status filter
    if (status === 'blacklisted') {
      whereClause += ' AND c.is_blacklisted = 1';
    } else if (status === 'active') {
      whereClause += ' AND (c.is_blacklisted = 0 OR c.is_blacklisted IS NULL)';
    }

    // Get per-user statistics
    const countWhereClause = whereClause.replace(/c\./g, '');
    // All clients for this user
    const [allCountResult] = await pool.execute(
      `SELECT COUNT(*) as total FROM cdb_clients WHERE user_id = ?`,
      [req.user.id]
    );
    // Active clients for this user
    const [activeCountResult] = await pool.execute(
      `SELECT COUNT(*) as total FROM cdb_clients WHERE user_id = ? AND (is_blacklisted = 0 OR is_blacklisted IS NULL)`,
      [req.user.id]
    );
    // Blocked clients for this user
    const [blockedCountResult] = await pool.execute(
      `SELECT COUNT(*) as total FROM cdb_clients WHERE user_id = ? AND is_blacklisted = 1`,
      [req.user.id]
    );
    // For pagination, use filtered count
    const [countResult] = await pool.execute(
      `SELECT COUNT(*) as total FROM cdb_clients WHERE ${countWhereClause}`,
      queryParams
    );

    // Get clients data with real order statistics (unique to each user)
    const [clients] = await pool.execute(
      `SELECT 
        c.id, c.name, c.phone, c.company_name, c.address, c.city, c.country,
        c.is_blacklisted, c.blacklisted_date, c.blacklisted_by,
        c.created_at, c.updated_at,
        COALESCE(o.total_orders, 0) as total_orders,
        COALESCE(o.delivered_orders, 0) as successful_orders, 
        0 as cancelled_orders,
        0.0 as total_revenue,
        CASE 
          WHEN COALESCE(o.total_orders, 0) > 0 
          THEN ROUND((COALESCE(o.delivered_orders, 0) / COALESCE(o.total_orders, 0)) * 100, 1)
          ELSE NULL 
        END as success_rate,
        o.last_order_date
       FROM cdb_clients c
       LEFT JOIN (
         SELECT 
           phone COLLATE utf8mb4_general_ci as phone,
           user_id,
           COUNT(*) as total_orders,
           SUM(CASE WHEN status_courier = 28 THEN 1 ELSE 0 END) as delivered_orders,
           MAX(order_date) as last_order_date
         FROM cdb_add_order
         GROUP BY phone COLLATE utf8mb4_general_ci, user_id
       ) o ON c.phone = o.phone AND c.user_id = o.user_id
  WHERE ${whereClause}
  ORDER BY c.${sortBy} ${sortOrder}
  LIMIT ? OFFSET ?`,
      [...queryParams, parseInt(limit), parseInt(offset)]
    );

    // Ensure proper data types for frontend
    const processedClients = clients.map(client => ({
      ...client,
      total_orders: parseInt(client.total_orders) || 0,
      successful_orders: parseInt(client.successful_orders) || 0,
      cancelled_orders: parseInt(client.cancelled_orders) || 0,
      total_revenue: parseFloat(client.total_revenue) || 0.0,
      success_rate: client.success_rate ? parseFloat(client.success_rate) : null
    }));

    console.log('API /clients called with status:', status, '| Found clients:', processedClients.length);
    const responseObj = {
      success: true,
      data: Array.isArray(processedClients) ? processedClients : [],
      pagination: {
        currentPage: parseInt(page),
        totalPages: Math.ceil(countResult[0].total / limit),
        totalItems: countResult[0].total,
        itemsPerPage: parseInt(limit)
      },
      statistics: {
        all: allCountResult[0].total,
        active: activeCountResult[0].total,
        blocked: blockedCountResult[0].total
      }
    };
    console.log('API /clients response object:', JSON.stringify(responseObj));
    res.json(responseObj);
  } catch (error) {
    console.error('Get clients error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Get single client details
router.get('/clients/:id', async (req, res) => {
  if (!req.user || !req.user.id) {
    return res.status(401).json({ success: false, message: 'Not authenticated. Please log in.' });
  }
  try {
    const { id } = req.params;

    // Get client data
    const [clients] = await pool.execute(
      `SELECT 
        id, name, phone, company_name, address, city, country,
        is_blacklisted, blacklisted_date, blacklisted_by,
        created_at, updated_at
       FROM cdb_clients WHERE id = ? AND user_id = ?`,
      [id, req.user.id]
    );

    if (clients.length === 0) {
      return res.status(404).json({ success: false, message: 'Client not found' });
    }

    const client = clients[0];

    // Get real order statistics by phone number (receiver identification)
    let orderStats = {
      total_orders: 0,
      delivered_orders: 0,
      success_rate: null,
      last_order_date: null
    };

    if (client.phone) {
      try {
        // Count total orders for this client's phone number and user
        const [totalOrdersResult] = await pool.execute(`
          SELECT COUNT(*) as total
          FROM cdb_add_order
          WHERE phone COLLATE utf8mb4_general_ci = ? COLLATE utf8mb4_general_ci AND user_id = ?
        `, [client.phone, req.user.id]);

        // Count delivered orders (status_courier = 28)
        const [deliveredOrdersResult] = await pool.execute(`
          SELECT COUNT(*) as delivered
          FROM cdb_add_order
          WHERE phone COLLATE utf8mb4_general_ci = ? COLLATE utf8mb4_general_ci AND status_courier = 28 AND user_id = ?
        `, [client.phone, req.user.id]);

        // Get last order date
        const [lastOrderResult] = await pool.execute(`
          SELECT MAX(order_date) as last_order_date
          FROM cdb_add_order
          WHERE phone COLLATE utf8mb4_general_ci = ? COLLATE utf8mb4_general_ci AND user_id = ?
        `, [client.phone, req.user.id]);

        orderStats.total_orders = totalOrdersResult[0].total || 0;
        orderStats.delivered_orders = deliveredOrdersResult[0].delivered || 0;
        orderStats.last_order_date = lastOrderResult[0].last_order_date;
        
        if (orderStats.total_orders > 0) {
          orderStats.success_rate = ((orderStats.delivered_orders / orderStats.total_orders) * 100).toFixed(1);
        }
      } catch (error) {
        console.log('Could not fetch order statistics:', error.message);
      }
    }

    // Update client object with real statistics
    client.total_orders = parseInt(orderStats.total_orders) || 0;
    client.successful_orders = parseInt(orderStats.delivered_orders) || 0; // Using delivered orders as successful
    client.cancelled_orders = 0; // We can calculate this later if needed
    client.total_revenue = 0.0; // We can add this calculation later
    client.success_rate = orderStats.success_rate ? parseFloat(orderStats.success_rate) : null;
    client.last_order_date = orderStats.last_order_date;

    // Get client notes (may not exist yet)
    let notes = [];
    try {
      const [notesResult] = await pool.execute(`
        SELECT cn.*, u.username as admin_name 
        FROM cdb_client_notes cn
        LEFT JOIN cdb_users u ON cn.admin_id = u.id
        WHERE cn.client_id = ?
        ORDER BY cn.created_at DESC
      `, [id]);
      notes = notesResult;
    } catch (error) {
      console.log('Notes table does not exist yet:', error.message);
    }

    // Get blacklist history (may not exist yet)
    let blacklistHistory = [];
    try {
      const [historyResult] = await pool.execute(`
        SELECT cbh.*, u.username as admin_name
        FROM cdb_client_blacklist_history cbh
        LEFT JOIN cdb_users u ON cbh.admin_id = u.id
        WHERE cbh.client_id = ?
        ORDER BY cbh.action_date DESC
      `, [id]);
      blacklistHistory = historyResult;
    } catch (error) {
      console.log('Blacklist history table does not exist yet:', error.message);
    }

    // Get recent orders with their delivery status
    let recentOrders = [];
    try {
      const [ordersResult] = await pool.execute(`
        SELECT 
          order_id, order_no, order_prefix, order_date, status_courier, price,
          CASE 
            WHEN status_courier = 28 THEN 'Delivered'
            WHEN status_courier = 24 THEN 'Pending'
            WHEN status_courier = 25 THEN 'In Transit'
            WHEN status_courier = 26 THEN 'Failed'
            WHEN status_courier = 27 THEN 'Cancelled'
            ELSE 'Unknown'
          END as status_text
        FROM cdb_add_order
        WHERE phone COLLATE utf8mb4_general_ci = ? COLLATE utf8mb4_general_ci
        ORDER BY order_date DESC
        LIMIT 10
      `, [client.phone]);
      recentOrders = ordersResult;
    } catch (error) {
      console.log('Could not fetch recent orders:', error.message);
    }

    res.json({
      success: true,
      data: {
        client: clients[0],
        notes,
        blacklistHistory,
        recentOrders
      }
    });
  } catch (error) {
    console.error('Get client details error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Create new client
router.post('/clients', async (req, res) => {
  if (!req.user || !req.user.id) {
    return res.status(401).json({ success: false, message: 'Not authenticated. Please log in.' });
  }
  try {
    const {
      name,
      phone,
      company_name,
      address,
      city,
      country = 'Morocco'
    } = req.body;

    // Validation
    if (!name) {
      return res.status(400).json({ success: false, message: 'Name is required' });
    }

    // Check if phone already exists
    if (phone) {
      const [existingClient] = await pool.execute(
        'SELECT id FROM cdb_clients WHERE phone = ?',
        [phone]
      );
      
      if (existingClient.length > 0) {
        return res.status(400).json({ success: false, message: 'Phone number already exists' });
      }
    }

    const [result] = await pool.execute(`
      INSERT INTO cdb_clients (name, phone, company_name, address, city, country, user_id)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `, [name, phone, company_name, address, city, country, req.user.id]);

    res.status(201).json({
      success: true,
      message: 'Client created successfully',
      clientId: result.insertId
    });
  } catch (error) {
    console.error('Create client error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Update client
router.put('/clients/:id', async (req, res) => {
  if (!req.user || !req.user.id) {
    return res.status(401).json({ success: false, message: 'Not authenticated. Please log in.' });
  }
  try {
    const { id } = req.params;
    const {
      name,
      phone,
      company_name,
      address,
      city,
      country
    } = req.body;

    // Check if client exists
    const [existingClient] = await pool.execute(
      'SELECT id FROM cdb_clients WHERE id = ? AND user_id = ?',
      [id, req.user.id]
    );

    if (existingClient.length === 0) {
      return res.status(404).json({ success: false, message: 'Client not found' });
    }

    // Check phone uniqueness if phone is being updated
    if (phone) {
      const [phoneCheck] = await pool.execute(
        'SELECT id FROM cdb_clients WHERE phone = ? AND id != ?',
        [phone, id]
      );
      
      if (phoneCheck.length > 0) {
        return res.status(400).json({ success: false, message: 'Phone number already exists' });
      }
    }

    await pool.execute(`
      UPDATE cdb_clients 
      SET name = ?, phone = ?, company_name = ?, 
          address = ?, city = ?, country = ?
      WHERE id = ?
    `, [name, phone, company_name, address, city, country, id]);

    res.json({ success: true, message: 'Client updated successfully' });
  } catch (error) {
    console.error('Update client error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Blacklist/Unblacklist client
router.post('/clients/:id/blacklist', async (req, res) => {
  if (!req.user || !req.user.id) {
    return res.status(401).json({ success: false, message: 'Not authenticated. Please log in.' });
  }
  try {
  const { id } = req.params;
  const { action, reason } = req.body; // action: 'blacklist' or 'unblacklist'

    if (!['blacklist', 'unblacklist'].includes(action)) {
      return res.status(400).json({ success: false, message: 'Invalid action' });
    }

    const isBlacklisted = action === 'blacklist' ? 1 : 0;
    
    // Update client status
    await pool.execute(`
      UPDATE cdb_clients 
      SET is_blacklisted = ?, 
          blacklisted_date = ?,
          blacklisted_by = ?
      WHERE id = ? AND user_id = ?
    `, [
      isBlacklisted, 
      isBlacklisted ? new Date() : null,
      isBlacklisted ? req.user.id : null,
      id,
      req.user.id
    ]);

    // Try to add to history (table might not exist)
    try {
      await pool.execute(`
        INSERT INTO cdb_client_blacklist_history (client_id, action, reason, admin_id)
        VALUES (?, ?, ?, ?)
      `, [id, action.toUpperCase() + 'ED', reason, req.user.id]);
    } catch (historyError) {
      console.log('Blacklist history table does not exist, skipping history insert');
    }

    res.json({ 
      success: true, 
      message: `Client ${action}ed successfully` 
    });
  } catch (error) {
    console.error('Blacklist client error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Add note to client
router.post('/clients/:id/notes', async (req, res) => {
  try {
    const { id } = req.params;
    const { note, adminId } = req.body;

    if (!note) {
      return res.status(400).json({ success: false, message: 'Note is required' });
    }

    await pool.execute(`
      INSERT INTO cdb_client_notes (client_id, note, admin_id)
      VALUES (?, ?, ?)
    `, [id, note, adminId]);

    res.json({ success: true, message: 'Note added successfully' });
  } catch (error) {
    console.error('Add note error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Delete client (hard delete)
router.delete('/clients/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { adminId = 1, reason = 'Client deleted' } = req.query;

    console.log(`DELETE request for client ID: ${id}, adminId: ${adminId}, reason: ${reason}`);

    // Hard delete the client
    const [result] = await pool.execute(`
      DELETE FROM cdb_clients 
      WHERE id = ?
    `, [id]);

    console.log(`Delete result:`, result);

    // Check if any rows were affected
    if (result.affectedRows === 0) {
      return res.status(404).json({ 
        success: false, 
        message: 'Client not found' 
      });
    }

    // Try to add to history (table might not exist)
    try {
      await pool.execute(`
        INSERT INTO cdb_client_blacklist_history (client_id, action, reason, admin_id)
        VALUES (?, 'DELETED', ?, ?)
      `, [id, reason, adminId]);
      console.log('Added to deletion history');
    } catch (historyError) {
      console.log('History table does not exist, skipping history insert');
    }

    res.json({ success: true, message: 'Client deleted successfully' });
  } catch (error) {
    console.error('Delete client error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Get client statistics
router.get('/clients/stats/overview', async (req, res) => {
  try {
    const [stats] = await pool.execute(`
      SELECT 
        COUNT(*) as total_clients,
        COUNT(CASE WHEN (is_blacklisted = 0 OR is_blacklisted IS NULL) THEN 1 END) as active_clients,
        COUNT(CASE WHEN is_blacklisted = 1 THEN 1 END) as blacklisted_clients,
        0.0 as avg_rating,
        0.0 as total_revenue,
        0.0 as avg_success_rate
      FROM cdb_clients
    `);

    res.json({ success: true, data: stats[0] });
  } catch (error) {
    console.error('Get client stats error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

export default router;
