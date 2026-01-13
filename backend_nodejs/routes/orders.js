// routes/orders.js
const express = require('express');
const router = express.Router();
const pool = require('../config/db');
const { authenticateToken, requireRole } = require('../src/middleware/auth');




const getAllOrders = async (req, res) => {
  try {
    const { status, limit = 50, offset = 0, userId } = req.query;

    const limitInt = parseInt(limit, 10) || 50;
    const offsetInt = parseInt(offset, 10) || 0;

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

    if (status) {
      conditions.push('o.status_courier = ?');
      params.push(status);
    }

    if (userId) {
      conditions.push('o.user_id = ?');
      params.push(userId);
    }

    if (conditions.length > 0) {
      query += ' WHERE ' + conditions.join(' AND ');
    }

  query += ` ORDER BY o.order_date DESC, o.order_id DESC LIMIT ${limitInt} OFFSET ${offsetInt}`;

    const [orders] = await pool.execute(query, params);


    // Maintenant, récupérer l'historique des statuts pour chaque commande
    for (const order of orders) {
      const [historyRows] = await pool.execute(
        `SELECT history_id, user_id, order_id, action, date_history, is_consolidate
         FROM cdb_order_user_history
         WHERE order_id = ?
         ORDER BY date_history ASC`,
        [order.order_id]
      );

      // Ajouter dans l'objet order sous la clé statusHistory
      order.statusHistory = historyRows.map(row => ({
        historyId: row.history_id,
        userId: row.user_id,
        action: row.action,
        date: row.date_history,
        isConsolidate: row.is_consolidate
      }));
    }

    // Count total
    let countQuery = 'SELECT COUNT(*) as total FROM cdb_add_order o';
    let countParams = [];
    if (conditions.length > 0) {
      countQuery += ' WHERE ' + conditions.join(' AND ');
      countParams = params;
    }
    const [countResult] = await pool.execute(countQuery, countParams);

    res.json({
      success: true,
      data: {
        orders,
        pagination: {
          total: countResult[0].total,
          limit: limitInt,
          offset: offsetInt,
          hasMore: countResult[0].total > offsetInt + orders.length
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


// Mettre à jour une commande
const updateOrder = async (req, res) => {
  try {
    const { id } = req.params;
    const {
      recipientName,
      recipientPhone,
      deliveryAddress,
      city,
      price,
      description
    } = req.body;

   

    // Vérifier si la commande existe
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

    // Préparer les valeurs pour la mise à jour
    const updateFields = [];
    const updateValues = [];

    if (recipientName !== undefined) {
      updateFields.push('receiver_name = ?');
      updateValues.push(recipientName);
    }
    
    if (recipientPhone !== undefined) {
      updateFields.push('phone = ?');
      updateValues.push(recipientPhone);
    }
    
    if (deliveryAddress !== undefined) {
      updateFields.push('address = ?');
      updateValues.push(deliveryAddress);
    }
    
    if (city !== undefined) {
      updateFields.push('city = ?');
      updateValues.push(city);
    }
    
    if (price !== undefined) {
      updateFields.push('price = ?');
      updateValues.push(price);
    }
    
    // Gestion spéciale pour description - peut être null
    if (description !== undefined) {
      updateFields.push('description = ?');
      updateValues.push(description);
    }

    // Ajouter la date de mise à jour
    updateFields.push('updated_at = NOW()');

    // Ajouter l'ID à la fin pour la clause WHERE
    updateValues.push(id);

    if (updateFields.length === 1) { // Seulement updated_at
      return res.status(400).json({
        success: false,
        message: 'No fields to update'
      });
    }

    const query = `UPDATE cdb_add_order SET ${updateFields.join(', ')} WHERE order_id = ?`;

  

    // Mettre à jour la commande
    const [result] = await pool.execute(query, updateValues);

    // Récupérer la commande mise à jour
    const [updatedOrder] = await pool.execute(
      'SELECT * FROM cdb_add_order WHERE order_id = ?',
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


// Assigner un chauffeur à une commande
router.put('/:id/assign-driver', authenticateToken, requireRole(2), async (req, res) => {
  try {
    const { id } = req.params;
    const { driver_id } = req.body;

    // Vérifier si la commande existe
    const [existingOrder] = await pool.execute(
      'SELECT order_id FROM cdb_add_order WHERE order_id = ?',
      [id]
    );

    if (existingOrder.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Order not found'
      });
    }

    // Vérifier si le chauffeur existe
    if (driver_id) {
      const [driver] = await pool.execute(
        'SELECT id FROM cdb_users WHERE id = ? AND userlevel = 3',
        [driver_id]
      );

      if (driver.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'Driver not found'
        });
      }
    }

    // Mettre à jour le chauffeur de la commande
    await pool.execute(
      `UPDATE cdb_add_order 
       SET driver_id = ?
       WHERE order_id = ?`,
      [driver_id || null, id]
    );

    res.json({
      success: true,
      message: 'Driver assigned successfully'
    });

  } catch (error) {
    console.error('Assign driver error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});


// Mettre à jour le statut d'une commande - Accessible selon le statut
router.put('/:id/status', authenticateToken, async (req, res) => {
  try {
    // Vérifier les permissions selon le statut demandé
    const { status } = req.body;
    
    // Les drivers ne peuvent mettre à jour que certains statuts
    if (req.user.userlevel === 3) { // Driver
      const allowedDriverStatuses = ['Picked up', 'In Transit', 'Out for Delivery', 'Attempted Delivery', 'Delivered'];
      if (!allowedDriverStatuses.includes(status)) {
        return res.status(403).json({
          success: false,
          message: 'Drivers can only update status to: ' + allowedDriverStatuses.join(', ')
        });
      }
    }
    
    // Les users normaux ne peuvent pas modifier les statuts
    if (req.user.userlevel < 2) {
      return res.status(403).json({
        success: false,
        message: 'Insufficient permissions to update order status'
      });
    }

    // Le reste du code existant reste inchangé...
    const { id } = req.params;
    const { note } = req.body;

    if (!status) {
      return res.status(400).json({
        success: false,
        message: 'Status is required'
      });
    }

    // Status mapping... (le code existant reste)
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
});


// Récupérer toutes les villes (sans pagination)
const getAllCities = async (req, res) => {
  try {
    const query = `
      SELECT id, name, comm, created_at, updated_at, status 
      FROM cdb_cities 
      WHERE status = 'active'
      ORDER BY name ASC
    `;

    const [cities] = await pool.execute(query);

    res.json({
      success: true,
      data: cities
    });
  } catch (error) {
    console.error('Get all cities error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};


// Routes
router.get('/all', authenticateToken, requireRole(2), getAllOrders);
router.put('/:id', authenticateToken, requireRole(2), updateOrder);
router.get('/cities/all', authenticateToken, getAllCities);

module.exports = router;
