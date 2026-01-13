import pool from '../config/database.js';
import { triggerNotification } from './notificationController.js';
import { findOrCreateClient, isClientBlacklisted, getBlacklistReason } from '../utils/clientHelpers.js';
import dotenv from 'dotenv';

dotenv.config();

// Generate tracking number
const generateTrackingNumber = () => {
  const timestamp = Date.now();
  const random = Math.floor(Math.random() * 1000).toString().padStart(3, '0');
  return `YAN${timestamp}${random}`;
};

// Debug endpoint to check orders and user data
export const debugOrders = async (req, res) => {
  try {
    const userId = req.user.id;
    
    // Check user info
    const [userInfo] = await pool.execute(
      'SELECT id, username, email FROM cdb_users WHERE id = ?',
      [userId]
    );

    // Check if table exists
    const [tableCheck] = await pool.execute(
      "SHOW TABLES LIKE 'cdb_add_order'"
    );

    // Try different possible table names
    const possibleTables = ['cdb_add_order', 'orders', 'cdb_orders', 'add_order'];
    const tableResults = {};
    
    for (const tableName of possibleTables) {
      try {
        const [count] = await pool.execute(`SELECT COUNT(*) as count FROM ${tableName}`);
        const [userOrders] = await pool.execute(`SELECT COUNT(*) as count FROM ${tableName} WHERE userId = ?`, [userId]);
        tableResults[tableName] = {
          exists: true,
          totalOrders: count[0].count,
          userOrders: userOrders[0].count
        };
      } catch (error) {
        tableResults[tableName] = {
          exists: false,
          error: error.message
        };
      }
    }

    res.json({
      success: true,
      debug: {
        currentUser: {
          id: userId,
          info: userInfo[0] || 'User not found'
        },
        tableAnalysis: tableResults,
        recommendation: 'Check which table exists and has data'
      }
    });

  } catch (error) {
    console.error('Debug orders error:', error);
    res.status(500).json({
      success: false,
      message: 'Debug error: ' + error.message
    });
  }
};

// Create new order (matches full table schema safely)
export const createOrder = async (req, res) => {
  try {
    const userId = req.user.id; // From JWT token
    const {
      receiver_name,
      phone,
      address,
      city,
      price,
      open_product,
      sender_address_id
    } = req.body;

    // Validate required fields
    if (!receiver_name || !phone || !address || !city || price === undefined || open_product === undefined) {
      return res.status(400).json({
        success: false,
        message: 'Receiver name, phone, address, city, price, and open_product are required'
      });
    }

    // Client Management Integration
    try {
      // Extract additional receiver information from request body
      const receiverData = {
        name: receiver_name,
        phone: phone,
        address: address,
        city: city,
        company_name: req.body.company_name || null, // Optional company name
        country: req.body.country || 'Morocco', // Default to Morocco if not specified
        user_id: userId
      };

      // Check if client is blacklisted before creating order
      const blacklistStatus = await isClientBlacklisted(phone);
      if (blacklistStatus.isBlacklisted) {
        const reason = await getBlacklistReason(phone);
        return res.status(403).json({
          success: false,
          message: 'Order cannot be created for blacklisted client',
          blacklist_reason: reason,
          client_info: {
            name: receiver_name,
            phone: phone
          }
        });
      }

      // Find or create client based on receiver information
      const clientResult = await findOrCreateClient(receiverData);
      
      // Store the client_id for potential future use (can be added to order table if needed)
      const receiver_client_id = clientResult.client.id;
      
      console.log(`📋 Client management: ${clientResult.created ? 'Created new' : 'Found existing'} client ID ${receiver_client_id} for receiver ${receiver_name} (${phone})`);
      
    } catch (clientError) {
      console.error('Client management error (non-critical, continuing with order):', clientError);
      // Continue with order creation even if client management fails
    }

    // --- Generators ---
    const generateDailyUserPrefix = async (userId) => {
      // Generate a daily rotating 3-letter prefix for each user
      const today = new Date();
      const dayOfYear = Math.floor((today - new Date(today.getFullYear(), 0, 0)) / (1000 * 60 * 60 * 24));
      
      // Create a seed based on user ID and day of year for consistency
      const seed = (userId * 1000) + dayOfYear;
      
      // Generate 3 random letters based on the seed
      const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
      let prefix = '';
      let currentSeed = seed;
      
      for (let i = 0; i < 3; i++) {
        currentSeed = (currentSeed * 9301 + 49297) % 233280; // Linear congruential generator
        const index = currentSeed % chars.length;
        prefix += chars[index];
      }
      
      return prefix;
    };

    const generateSequentialOrderNumber = async (userId) => {
      // Get the max order_no for this user
      const [maxRows] = await pool.execute(
        'SELECT MAX(CAST(order_no AS UNSIGNED)) as max_no FROM cdb_add_order WHERE user_id = ?',
        [userId]
      );
      let nextNo = (maxRows[0].max_no || 0) + 1;

      // Find the next available (unused) order_no for this user
      let found = false;
      let tryCount = 0;
      while (!found && tryCount < 1000) { // avoid infinite loop
        const [exists] = await pool.execute(
          'SELECT order_id FROM cdb_add_order WHERE user_id = ? AND order_no = ?',
          [userId, String(nextNo).padStart(6, '0')]
        );
        if (exists.length === 0) {
          found = true;
        } else {
          nextNo++;
        }
        tryCount++;
      }
      return String(nextNo).padStart(6, '0'); // 6-digit format: 000001, 000010, etc.
    };

    const generateOrderEncoded = () => {
      return Buffer.from(Date.now().toString() + Math.random().toString())
        .toString('base64')
        .slice(0, 12);
    };

    // Generate auto values
    const order_prefix = await generateDailyUserPrefix(userId);
    const order_no = await generateSequentialOrderNumber(userId);
    const order_encoded = generateOrderEncoded();
    const status_courier = 1; // created by default
    const order_date = new Date();

    // Check for duplicate order_no
    const [existingOrder] = await pool.execute(
      'SELECT order_id FROM cdb_add_order WHERE user_id = ? AND order_no = ?',
      [userId, order_no]
    );
    if (existingOrder.length > 0) {
      return res.status(409).json({
        success: false,
        message: 'Duplicate order_no: An order with this order_no already exists for this user.'
      });
    }

    // Get next order_id 
    const [lastOrder] = await pool.execute('SELECT order_id FROM cdb_add_order ORDER BY order_id DESC LIMIT 1');
    let nextId = lastOrder.length ? (parseInt(lastOrder[0].order_id, 10) + 1) : 1;
    let formatted_order_id = String(nextId).padStart(5, '0');

    // Insert order
    const [result] = await pool.execute(
      `INSERT INTO cdb_add_order (
        user_id, order_prefix, order_no, order_encoded, order_date, status_courier,
        address, receiver_name, city, phone, price, open_product, sender_id, sender_address_id
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        userId,
        order_prefix,
        order_no,
        order_encoded,
        order_date,
        status_courier,
        address,
        receiver_name,
        city,
        phone,
        price,
        open_product,
        userId,
        sender_address_id || null
      ]
    );

    // Add initial history entry for order creation
    try {
      await pool.execute(
        'INSERT INTO cdb_order_user_history (user_id, order_id, action, date_history) VALUES (?, ?, ?, NOW())',
        [userId, result.insertId, 'Order created']
      );
    } catch (historyError) {
      console.log('History insert failed for order creation (non-critical):', historyError.message);
    }

    // Trigger notification for order creation
    console.log(`🚀 Triggering order creation notification for user ${userId}, order ${result.insertId}`);
    await triggerNotification(userId, 'order_created', {
      orderId: result.insertId,
      trackingNumber: order_no,
      shipping_type: "standard",
      status: status_courier,
      recipientName: receiver_name,
      city: city,
      price: price,
      phone: phone
    });

    // Respond with created order
    res.status(201).json({
      success: true,
      message: 'Order created successfully',
      data: {
        order: {
          id: result.insertId,
          formattedId: formatted_order_id,
          prefix: order_prefix,
          trackingNumber: order_no,
          encoded: order_encoded,
          status: status_courier,
          recipientName: receiver_name,
          deliveryAddress: address,
          city,
          phone, // Include phone field
          price,
          openProduct: open_product,
          createdAt: order_date,
          date: order_date // Also include as 'date' for consistency
        }
      }
    });

  } catch (error) {
    console.error('Create order error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error during order creation'
    });
  }
};

// Get recent orders for home page (last 10 orders) - simple version
export const getRecentOrders = async (req, res) => {
  try {
    const userId = req.user.id;

    const [orders] = await pool.execute(
      `SELECT o.order_id, o.receiver_name, o.address, o.city, o.status_courier, 
              o.order_prefix, o.order_no, o.price, o.order_date, o.order_datetime, o.phone
       FROM cdb_add_order o 
       WHERE o.user_id = ? 
       ORDER BY o.order_id DESC 
       LIMIT 10`,
      [userId]
    );

    // Format the response to match expected structure
    const formattedOrders = orders.map(order => ({
      id: order.order_id,
      recipientName: order.receiver_name,
      deliveryAddress: order.address,
      city: order.city,
      status: order.status_courier,
      orderPrefix: order.order_prefix,
      trackingNumber: order.order_no,
      fullTrackingNumber: `${order.order_prefix}-${order.order_no}`, // Combined format
      date: order.order_date || order.order_datetime, // Use order_date with fallback to order_datetime
      price: order.price,
      phone: order.phone,
      created_at: order.order_datetime,
      updated_at: order.order_datetime
    }));

    res.json({
      success: true,
      data: {
        recentOrders: formattedOrders,
        totalCount: formattedOrders.length
      }
    });

  } catch (error) {
    console.error('Get recent orders error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Get recent orders for home page (last 10 orders) with history
export const getRecentOrdersWithHistory = async (req, res) => {
  try {
    const userId = req.user.id;

    const query = `
      SELECT 
        o.order_id, o.receiver_name, o.address, o.city, o.status_courier, 
        o.order_prefix, o.order_no, o.price, o.order_date, o.order_datetime, o.phone, o.sender_address_id,
        c.name as cityName, c.comm as cityDescription,
        ua.address as senderAddressText,
        h.action, h.date_history
      FROM cdb_add_order o 
      LEFT JOIN cdb_cities c ON o.city = c.id
      LEFT JOIN cdb_users_multiple_addresses ua ON o.sender_address_id = ua.id_addresses
      LEFT JOIN cdb_order_user_history h ON o.order_id = h.order_id
      WHERE o.user_id = ? 
      ORDER BY o.order_id DESC, h.date_history ASC
    `;

    const [results] = await pool.execute(query, [userId]);

    // Group results by order_id and build statusHistory
    const ordersMap = new Map();
    
    results.forEach(row => {
      const orderId = row.order_id;
      
      if (!ordersMap.has(orderId)) {
        ordersMap.set(orderId, {
          id: row.order_id,
          recipientName: row.receiver_name,
          deliveryAddress: row.address,
          city: row.city, // Keep for backward compatibility
          cityName: row.cityName || 'Unknown City',
          cityDescription: row.cityDescription,
          senderAddress: row.senderAddressText ? {
            address: row.senderAddressText,
            name: 'Address' // Default name since name column doesn't exist
          } : null,
          status: row.status_courier,
          orderPrefix: row.order_prefix,
          trackingNumber: row.order_no,
          fullTrackingNumber: `${row.order_prefix}-${row.order_no}`, // Combined format
          price: row.price,
          phone: row.phone,
          date: row.order_date || row.order_datetime, // Use order_date with fallback to order_datetime
          created_at: row.order_datetime,
          updated_at: row.order_datetime,
          statusHistory: {}
        });
      }
      
      // Add history entry if it exists
      if (row.action && row.date_history) {
        ordersMap.get(orderId).statusHistory[row.action] = row.date_history;
      }
    });

    // Convert to array and take only the first 10 orders
    const recentOrders = Array.from(ordersMap.values()).slice(0, 10);

    res.json({
      success: true,
      data: {
        recentOrders: recentOrders,
        totalCount: recentOrders.length
      }
    });

  } catch (error) {
    console.error('Get recent orders with history error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Get user dashboard stats
export const getUserDashboard = async (req, res) => {
  try {
    const userId = req.user.id;

    // Get order counts by status
    const [statusCounts] = await pool.execute(
      `SELECT 
         COUNT(*) as total_orders,
         SUM(CASE WHEN status_courier = 31 THEN 1 ELSE 0 END) as pending_orders,
         SUM(CASE WHEN status_courier = 24 THEN 1 ELSE 0 END) as confirmed_orders,
         SUM(CASE WHEN status_courier = 25 THEN 1 ELSE 0 END) as picked_up_orders,
         SUM(CASE WHEN status_courier = 26 THEN 1 ELSE 0 END) as in_transit_orders,
         SUM(CASE WHEN status_courier = 27 THEN 1 ELSE 0 END) as delivered_orders,
         SUM(CASE WHEN status_courier = 28 THEN 1 ELSE 0 END) as cancelled_orders
       FROM cdb_add_order 
       WHERE user_id = ?`,
      [userId]
    );

    // Get recent orders (last 10)
    const [recentOrders] = await pool.execute(
      `SELECT o.order_id, o.receiver_name, o.address, o.city, o.status_courier, 
              o.order_prefix, o.order_no, o.price, o.order_datetime
       FROM cdb_add_order o 
       WHERE o.user_id = ? 
       ORDER BY o.order_id DESC 
       LIMIT 10`,
      [userId]
    );

    const stats = statusCounts[0];

    // Format recent orders
    const formattedOrders = recentOrders.map(order => ({
      id: order.order_id,
      recipientName: order.receiver_name,
      deliveryAddress: order.address,
      city: order.city,
      status: order.status_courier,
      orderPrefix: order.order_prefix,
      trackingNumber: order.order_no,
      fullTrackingNumber: `${order.order_prefix}-${order.order_no}`, // Combined format
      price: order.price,
      created_at: order.order_datetime
    }));

    res.json({
      success: true,
      data: {
        orderStats: {
          totalOrders: parseInt(stats.total_orders) || 0,
          pendingOrders: parseInt(stats.pending_orders) || 0,
          confirmedOrders: parseInt(stats.confirmed_orders) || 0,
          pickedUpOrders: parseInt(stats.picked_up_orders) || 0,
          inTransitOrders: parseInt(stats.in_transit_orders) || 0,
          deliveredOrders: parseInt(stats.delivered_orders) || 0,
          cancelledOrders: parseInt(stats.cancelled_orders) || 0
        },
        recentOrders: formattedOrders
      }
    });

  } catch (error) {
    console.error('Get user dashboard error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Get all orders for current user (simple version)
export const getUserOrders = async (req, res) => {
  try {
    const userId = req.user.id;
    const { status, limit = 50, offset = 0 } = req.query;

    let query = `
      SELECT o.order_id, o.receiver_name, o.phone, o.address, o.city, 
             o.price, o.status_courier, o.order_no, o.order_datetime,
             o.open_product, o.notes, o.sender_address_id,
             u.username, u.email as user_email, u.fname, u.lname,
             c.name as city_name, c.comm as city_description,
             sa.address as sender_address, sa.city as sender_city, 
             sa.country as sender_country, sa.zip_code as sender_zip
      FROM cdb_add_order o 
      JOIN cdb_users u ON o.user_id = u.id 
      LEFT JOIN cdb_cities c ON o.city = c.id
      LEFT JOIN cdb_users_multiple_addresses sa ON o.sender_address_id = sa.id_addresses
      WHERE o.user_id = ?
    `;
    let params = [userId];

    // Filter by status if provided
    if (status) {
      query += ' AND o.status_courier = ?';
      params.push(parseInt(status));
    }

    query += ' ORDER BY o.order_id DESC LIMIT ? OFFSET ?';
    params.push(parseInt(limit), parseInt(offset));

    const [orders] = await pool.execute(query, params);

    // Get total count
    let countQuery = 'SELECT COUNT(*) as total FROM cdb_add_order WHERE user_id = ?';
    let countParams = [userId];
    
    if (status) {
      countQuery += ' AND status_courier = ?';
      countParams.push(parseInt(status));
    }

    const [countResult] = await pool.execute(countQuery, countParams);

    // Format orders to match expected structure
    const formattedOrders = orders.map(order => ({
      id: order.order_id,
      userId: userId,
      recipientName: order.receiver_name,
      recipientPhone: order.phone,
      deliveryAddress: order.address,
      city: order.city, // This is now the city ID
      cityName: order.city_name, // This is the actual city name
      cityDescription: order.city_description,
      price: order.price,
      status: order.status_courier,
      trackingNumber: order.order_no,
      authorizeToOpenBox: order.open_product,
      description: order.notes,
      created_at: order.order_datetime,
      updated_at: order.order_datetime,
      username: order.username,
      user_email: order.user_email,
      fname: order.fname,
      lname: order.lname,
      senderAddressId: order.sender_address_id,
      senderAddress: {
        address: order.sender_address,
        city: order.sender_city,
        country: order.sender_country,
        zipCode: order.sender_zip
      }
    }));

    res.json({
      success: true,
      data: {
        orders: formattedOrders,
        pagination: {
          total: countResult[0].total,
          limit: parseInt(limit),
          offset: parseInt(offset),
          hasMore: countResult[0].total > parseInt(offset) + formattedOrders.length
        }
      }
    });

  } catch (error) {
    console.error('Get user orders error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Get all orders for current user with status history
export const getUserOrdersWithHistory = async (req, res) => {
  try {
    const userId = req.user.id;
    const { status, limit = 50, offset = 0 } = req.query;

    // Main query to get orders with history
    let query = `
      SELECT 
        o.order_id, o.receiver_name, o.phone, o.address, o.city, 
        o.price, o.status_courier, o.order_no, o.order_date, o.order_datetime,
        o.open_product, o.notes, o.sender_address_id, o.order_prefix,
        u.username, u.email as user_email, u.fname, u.lname,
        c.name as city_name, c.comm as city_description,
        sa.address as sender_address, sa.city as sender_city, 
        sa.country as sender_country, sa.zip_code as sender_zip,
        h.action, h.date_history
      FROM cdb_add_order o 
      JOIN cdb_users u ON o.user_id = u.id 
      LEFT JOIN cdb_cities c ON o.city = c.id
      LEFT JOIN cdb_users_multiple_addresses sa ON o.sender_address_id = sa.id_addresses
      LEFT JOIN cdb_order_user_history h ON o.order_id = h.order_id
      WHERE o.user_id = ?
    `;
    let params = [userId];

    // Filter by status if provided
    if (status) {
      query += ' AND o.status_courier = ?';
      params.push(parseInt(status));
    }

    query += ' ORDER BY o.order_id DESC, h.date_history ASC';

    const [results] = await pool.execute(query, params);

    // Group results by order_id and build statusHistory
    const ordersMap = new Map();
    
    results.forEach(row => {
      const orderId = row.order_id;
      
      if (!ordersMap.has(orderId)) {
        ordersMap.set(orderId, {
          id: row.order_id,
          userId: userId,
          recipientName: row.receiver_name,
          recipientPhone: row.phone,
          deliveryAddress: row.address,
          city: row.city, // This is now the city ID
          cityName: row.city_name, // This is the actual city name
          cityDescription: row.city_description,
          price: row.price,
          status: row.status_courier,
          trackingNumber: row.order_no,
          orderPrefix: row.order_prefix, // Add order prefix
          fullTrackingNumber: `${row.order_prefix || ''}-${row.order_no || ''}`, // Add full tracking number
          authorizeToOpenBox: row.open_product,
          description: row.notes,
          date: row.order_date || row.order_datetime, // Use order_date with fallback to order_datetime
          created_at: row.order_datetime,
          updated_at: row.order_datetime,
          username: row.username,
          user_email: row.user_email,
          fname: row.fname,
          lname: row.lname,
          senderAddressId: row.sender_address_id,
          senderAddress: {
            address: row.sender_address,
            city: row.sender_city,
            country: row.sender_country,
            zipCode: row.sender_zip
          },
          statusHistory: {}
        });
        
        // Debug date info
        console.log(`Debug - Order ${row.order_id} dates:`, {
          order_date: row.order_date,
          order_datetime: row.order_datetime,
          final_date: row.order_date || row.order_datetime
        });
      }
      
      // Add history entry if it exists
      if (row.action && row.date_history) {
        ordersMap.get(orderId).statusHistory[row.action] = row.date_history;
      }
    });
    
    // Convert map to array and apply pagination
    const allOrders = Array.from(ordersMap.values());
    const paginatedOrders = allOrders.slice(offset, offset + parseInt(limit));

    console.log('Debug - getUserOrdersWithHistory:');
    console.log('- Total orders found:', allOrders.length);
    console.log('- Sample order data:', JSON.stringify(paginatedOrders[0], null, 2));

    // Get total count for pagination
    let countQuery = 'SELECT COUNT(DISTINCT o.order_id) as total FROM cdb_add_order o WHERE o.user_id = ?';
    let countParams = [userId];
    
    if (status) {
      countQuery += ' AND o.status_courier = ?';
      countParams.push(parseInt(status));
    }

    const [countResult] = await pool.execute(countQuery, countParams);

    res.json({
      success: true,
      data: {
        orders: paginatedOrders,
        pagination: {
          total: countResult[0].total,
          limit: parseInt(limit),
          offset: parseInt(offset),
          hasMore: countResult[0].total > parseInt(offset) + paginatedOrders.length
        }
      }
    });

  } catch (error) {
    console.error('Get user orders with history error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Get single order by ID
export const getOrderById = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    const [orders] = await pool.execute(
      `SELECT o.order_id, o.receiver_name, o.phone, o.address, o.city, 
             o.price, o.status_courier, o.order_no, o.order_datetime,
             o.open_product, o.notes, u.username, u.email as user_email, u.fname, u.lname,
             c.name as cityName, c.description as cityDescription
       FROM cdb_add_order o 
       JOIN cdb_users u ON o.user_id = u.id 
       LEFT JOIN cdb_cities c ON o.city = c.id
       WHERE o.order_id = ? AND o.user_id = ?`,
      [id, userId]
    );

    if (orders.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Order not found or you do not have permission to view it'
      });
    }

    // Format the order to match expected structure
    const order = orders[0];
    const formattedOrder = {
      id: order.order_id,
      userId: userId,
      recipientName: order.receiver_name,
      recipientPhone: order.phone,
      deliveryAddress: order.address,
      city: order.city, // City ID for updating
      cityName: order.cityName, // City name for display
      cityDescription: order.cityDescription,
      price: order.price,
      status: order.status_courier,
      trackingNumber: order.order_no,
      authorizeToOpenBox: order.open_product,
      description: order.notes,
      created_at: order.order_datetime,
      updated_at: order.order_datetime,
      username: order.username,
      user_email: order.user_email,
      fname: order.fname,
      lname: order.lname
    };

    res.json({
      success: true,
      data: {
        order: formattedOrder
      }
    });

  } catch (error) {
    console.error('Get order by ID error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Update order
export const updateOrder = async (req, res) => {
  console.log('🎯 UPDATE ORDER CALLED');
  console.log('- Order ID:', req.params.id);
  console.log('- User ID:', req.user?.id);
  console.log('- Request body:', JSON.stringify(req.body, null, 2));
  
  try {
    const { id } = req.params;
    const userId = req.user.id;
    const {
      recipientName,
      recipientPhone,
      deliveryAddress,
      city,
      pickupPoint,
      price,
      authorizeToOpenBox,
      description,
      weight,
      dimensions
    } = req.body;

    // Check if order exists
    const [existingOrder] = await pool.execute(
      'SELECT order_id, status_courier FROM cdb_add_order WHERE order_id = ?',
      [id]
    );

    if (existingOrder.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Order not found'
      });
    }

    // Check if order can be updated (only pending orders can be updated)
    console.log('📋 Order status check:');
    console.log('- Current status_courier:', existingOrder[0].status_courier);
    console.log('- Required status (pending):', 1);
    console.log('- Status match:', existingOrder[0].status_courier === 1);
    
    if (existingOrder[0].status_courier !== 1) { // 1 is pending status
      return res.status(400).json({
        success: false,
        message: 'Only pending orders can be updated'
      });
    }

    // Update order
    await pool.execute(
      `UPDATE cdb_add_order 
       SET receiver_name = COALESCE(?, receiver_name),
           phone = COALESCE(?, phone),
           address = COALESCE(?, address),
           city = COALESCE(?, city),
           price = COALESCE(?, price),
           notes = COALESCE(?, notes)
       WHERE order_id = ?`,
      [
        recipientName,
        recipientPhone,
        deliveryAddress,
        city,
        price,
        description,
        id
      ]
    );

    // Get updated order
    const [updatedOrder] = await pool.execute(
      `SELECT 
        o.order_id, o.receiver_name, o.address, o.city, o.status_courier, 
        o.order_prefix, o.order_no, o.price, o.order_date, o.order_datetime, o.phone, o.sender_address_id,
        c.name as cityName, c.comm as cityDescription,
        ua.address as senderAddressText
      FROM cdb_add_order o 
      LEFT JOIN cdb_cities c ON o.city = c.id
      LEFT JOIN cdb_users_multiple_addresses ua ON o.sender_address_id = ua.id_addresses
      WHERE o.order_id = ?`,
      [id]
    );

    res.json({
      success: true,
      message: 'Order updated successfully',
      data: {
        order: updatedOrder[0]
      }
    });

  } catch (error) {
    console.error('Update order error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Delete order
export const deleteOrder = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    // Check if order exists and belongs to user
    const [existingOrder] = await pool.execute(
      'SELECT order_id, status_courier FROM cdb_add_order WHERE order_id = ? AND user_id = ?',
      [id, userId]
    );

    if (existingOrder.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Order not found or you do not have permission to delete it'
      });
    }

    // Check if order can be deleted (only pending orders can be deleted)
    if (existingOrder[0].status_courier !== 1) { // 1 is 'Created' status
      return res.status(400).json({
        success: false,
        message: 'Only pending orders can be deleted'
      });
    }

    // Delete order
    await pool.execute(
      'DELETE FROM cdb_add_order WHERE order_id = ? AND user_id = ?',
      [id, userId]
    );

    res.json({
      success: true,
      message: 'Order deleted successfully'
    });

  } catch (error) {
    console.error('Delete order error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Get order by tracking number
export const getOrderByTracking = async (req, res) => {
  try {
    const { trackingNumber } = req.params;

    const [orders] = await pool.execute(
      `SELECT o.*, u.username, u.fname, u.lname 
       FROM cdb_add_order o 
       JOIN cdb_users u ON o.userId = u.id 
       WHERE o.trackingNumber = ?`,
      [trackingNumber]
    );

    if (orders.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Order not found with this tracking number'
      });
    }

    // Don't show sensitive user information for public tracking
    const order = orders[0];
    const publicOrder = {
      id: order.id,
      trackingNumber: order.trackingNumber,
      recipientName: order.recipientName,
      deliveryAddress: order.deliveryAddress,
      city: order.city,
      status: order.status,
      created_at: order.created_at,
      updated_at: order.updated_at
    };

    res.json({
      success: true,
      data: {
        order: publicOrder
      }
    });

  } catch (error) {
    console.error('Get order by tracking error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Update order status (for admin/system use)
export const updateOrderStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status, note } = req.body;

    if (!status) {
      return res.status(400).json({
        success: false,
        message: 'Status is required'
      });
    }

    // Status mapping from display names to database IDs
    const statusMap = {
      'Created': 1,
      'Confirmed': 10,
      'In Transit': 24,
      'Picked up': 25,
      'Out for Delivery': 26,
      'Attempted Delivery': 27,
      'Delivered': 28,
      'Returned': 29,
      'Cancelled': 3,
      'Rejected': 5,
      // Also support lowercase variants for backward compatibility
      'created': 1,
      'confirmed': 10,
      'picked_up': 25,
      'in_transit': 24,
      'delivered': 28,
      'cancelled': 3,
      'rejected': 5,
    };

    const statusId = statusMap[status];
    if (statusId === undefined) {
      return res.status(400).json({
        success: false,
        message: 'Invalid status. Valid statuses are: ' + Object.keys(statusMap).join(', ')
      });
    }

    // Check if order exists
    const [existingOrder] = await pool.execute(
      'SELECT order_id, user_id, order_no FROM cdb_add_order WHERE order_id = ?',
      [id]
    );

    if (existingOrder.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Order not found'
      });
    }

    // Update order status with numeric ID
    const [result] = await pool.execute(
      'UPDATE cdb_add_order SET status_courier = ? WHERE order_id = ?',
      [statusId, id]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({
        success: false,
        message: 'Failed to update order status'
      });
    }

    // Add status history entry
    try {
      let historyMessage = '';
      
      // Create specific messages for different status changes
      switch (status) {
        case 'Confirmed':
          historyMessage = 'Order confirmed';
          break;
        case 'Picked up':
          historyMessage = 'Order picked up';
          break;
        case 'In Transit':
          historyMessage = 'Order in transit';
          break;
        case 'Out for Delivery':
          historyMessage = 'Order out for delivery';
          break;
        case 'Delivered':
          historyMessage = 'Order delivered';
          break;
        case 'Cancelled':
          historyMessage = 'Order cancelled';
          break;
        default:
          historyMessage = note ? `${status}: ${note}` : `Status updated to ${status}`;
      }
      
      await pool.execute(
        'INSERT INTO cdb_order_user_history (user_id, order_id, action, date_history) VALUES (?, ?, ?, NOW())',
        [existingOrder[0].user_id, id, historyMessage]
      );
    } catch (historyError) {
      console.log('History insert failed (non-critical):', historyError.message);
    }

    // Try to trigger notification (non-critical)
    try {
      await triggerNotification(existingOrder[0].user_id, 'order_status', {
        orderId: id,
        trackingNumber: existingOrder[0].order_no,
        status: statusId, // Send numeric status ID
        shipping_type: "standard"
      });
    } catch (notifyError) {
      console.log('Notification failed (non-critical):', notifyError.message);
    }

    res.json({
      success: true,
      message: `Order status updated to ${status} successfully`
    });

  } catch (error) {
    console.error('Update order status error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update order status: ' + error.message
    });
  }
};

// Bulk pickup - Update all confirmed orders to picked up status
export const bulkPickupOrders = async (req, res) => {
  try {
    const userId = req.user.id;

    // Get all confirmed orders for this user (status_courier = 10)
    const [confirmedOrders] = await pool.execute(
      'SELECT order_id, order_no FROM cdb_add_order WHERE user_id = ? AND status_courier = 10',
      [userId]
    );

    if (confirmedOrders.length === 0) {
      return res.json({
        success: true,
        message: 'No confirmed orders found to pickup',
        updatedCount: 0,
        orders: []
      });
    }

    // Update all confirmed orders to picked up status (25)
    const [updateResult] = await pool.execute(
      'UPDATE cdb_add_order SET status_courier = 25 WHERE user_id = ? AND status_courier = 10',
      [userId]
    );

    // Add history entries for each order
    const historyPromises = confirmedOrders.map(order => 
      pool.execute(
        'INSERT INTO cdb_order_user_history (user_id, order_id, action, date_history) VALUES (?, ?, ?, NOW())',
        [userId, order.order_id, 'Order picked up']
      ).catch(err => console.log('History insert failed for order', order.order_id, ':', err.message))
    );

    // Execute all history inserts (non-blocking)
    Promise.all(historyPromises);

    // Send notifications for each order (non-blocking)
    confirmedOrders.forEach(order => {
      triggerNotification(userId, 'order_status', {
        orderId: order.order_id,
        trackingNumber: order.order_no,
        status: 25, // Picked up status ID
        shipping_type: "standard"
      }).catch(err => console.log('Notification failed for order', order.order_id, ':', err.message));
    });

    res.json({
      success: true,
      message: `Successfully picked up ${updateResult.affectedRows} orders`,
      updatedCount: updateResult.affectedRows,
      orders: confirmedOrders.map(order => ({
        id: order.order_id,
        trackingNumber: order.order_no
      }))
    });

  } catch (error) {
    console.error('Bulk pickup error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to pickup orders: ' + error.message
    });
  }
};

// Get all orders (admin function)
export const getAllOrders = async (req, res) => {
  try {
    const { status, limit = 50, offset = 0, userId } = req.query;

    let query = `
      SELECT o.*, u.username, u.email as user_email, u.fname, u.lname,
             c.name as city_name, c.comm as city_description,
             sa.address as sender_address, sa.city as sender_city, 
             sa.country as sender_country, sa.zip_code as sender_zip
      FROM cdb_add_order o 
      JOIN cdb_users u ON o.user_id = u.id
      LEFT JOIN cdb_cities c ON o.city = c.id
      LEFT JOIN cdb_users_multiple_addresses sa ON o.sender_address_id = sa.id_addresses
    `;
    let params = [];
    let conditions = [];

    // Filter by status if provided
    if (status) {
      conditions.push('o.status_courier = ?');
      params.push(status);
    }

    // Filter by user ID if provided
    if (userId) {
      conditions.push('o.user_id = ?');
      params.push(userId);
    }

    if (conditions.length > 0) {
      query += ' WHERE ' + conditions.join(' AND ');
    }

    query += ' ORDER BY o.order_id DESC LIMIT ? OFFSET ?';
    params.push(parseInt(limit), parseInt(offset));

    const [orders] = await pool.execute(query, params);

    // Get total count
    let countQuery = 'SELECT COUNT(*) as total FROM cdb_add_order o';
    let countParams = [];
    
    if (conditions.length > 0) {
      countQuery += ' WHERE ' + conditions.join(' AND ');
      // Remove limit and offset params for count
      countParams = params.slice(0, -2);
    }

    const [countResult] = await pool.execute(countQuery, countParams);

    res.json({
      success: true,
      data: {
        orders: orders,
        pagination: {
          total: countResult[0].total,
          limit: parseInt(limit),
          offset: parseInt(offset),
          hasMore: countResult[0].total > parseInt(offset) + orders.length
        }
      }
    });

  } catch (error) {
    console.error('Get all orders error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Add status history entry
export const addOrderStatusHistory = async (req, res) => {
  try {
    const { orderId } = req.params;
    const { action, date_history = new Date() } = req.body;
    const userId = req.user.id;

    // Verify the order belongs to the user
    const [orderCheck] = await pool.execute(
      'SELECT user_id FROM cdb_add_order WHERE order_id = ?',
      [orderId]
    );

    if (orderCheck.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Order not found'
      });
    }

    if (orderCheck[0].user_id !== userId && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    // Insert history entry
    const [result] = await pool.execute(
      'INSERT INTO cdb_order_user_history (user_id, order_id, action, date_history) VALUES (?, ?, ?, ?)',
      [orderCheck[0].user_id, orderId, action, date_history]
    );

    res.json({
      success: true,
      message: 'Status history added successfully',
      data: {
        historyId: result.insertId,
        orderId: parseInt(orderId),
        action,
        date_history
      }
    });

  } catch (error) {
    console.error('Add order status history error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Get order history for a specific order
export const getOrderHistory = async (req, res) => {
  try {
    const { orderId } = req.params;
    const userId = req.user.id;

    // Verify the order belongs to the user
    const [orderCheck] = await pool.execute(
      'SELECT user_id FROM cdb_add_order WHERE order_id = ?',
      [orderId]
    );

    if (orderCheck.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Order not found'
      });
    }

    if (orderCheck[0].user_id !== userId && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    // Get history
    const [history] = await pool.execute(
      'SELECT * FROM cdb_order_user_history WHERE order_id = ? ORDER BY date_history ASC',
      [orderId]
    );

    res.json({
      success: true,
      data: {
        orderId: parseInt(orderId),
        history: history
      }
    });

  } catch (error) {
    console.error('Get order history error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};
