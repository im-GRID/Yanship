const pool = require('../config/db');
const path = require('path');
const fs = require('fs').promises;

const VALID_STATUSES = [
  "Picked up",
  "No answer", 
  "Reported",
  "Rejected",
  "Cancelled",
  "Delivered"
];

// Map status IDs to status names based on the database
const STATUS_MAP = {
  25: "Picked up",
  28: "Delivered",
  3: "Cancelled",
  5: "Rejected",
  26: "Reported",
  29: "No answer",
};

// Status IDs that cannot be changed once set
const LOCKED_STATUS_IDS = [5,28,3]; // rejected delivered

// Validation des données
const validateMissionId = (id) => {
  if (!id || isNaN(id)) {
    throw new Error('ID de mission invalide');
  }
  return parseInt(id, 10);
};

// Liste des missions d'un livreur
exports.getMissionsByLivreur = async (req, res) => {
  try {
    const driverId = req.query.driverId;
    const searchQuery = req.query.search;
    const filterType = req.query.filterType;

    if (!driverId) {
      return res.status(400).json({ success: false, message: 'Le paramètre driverId est manquant.' });
    }

    let query = `
        SELECT 
          o.order_id,
          o.order_no,
          o.order_prefix,
          o.order_encoded,
          o.order_date,
          o.driver_id,
          o.person_receives,
          o.address,
          o.receiver_name,
          o.city,
          c.name AS city_name,
          o.phone,
          o.price,
          o.price_afterfee,
          o.photo_delivered,
          o.status_courier,
          o.notes,
          o.is_invoiced,
          u.fname,
          u.lname,
          u.phone as driver_phone
        FROM cdb_add_order o
        LEFT JOIN cdb_users u ON o.driver_id = u.id
        LEFT JOIN cdb_cities c ON o.city = c.id
        WHERE o.driver_id = ?
    `;
    let params = [driverId];

    if (searchQuery && filterType) {
      switch (filterType) {
        case 'Status':
          query += ' AND o.status_courier IN (SELECT id FROM cdb_styles WHERE detail LIKE ?)';
          params.push(`%${searchQuery}%`);
          break;
        case 'Client':
          query += ' AND (o.receiver_name LIKE ? OR o.person_receives LIKE ?)';
          params.push(`%${searchQuery}%`, `%${searchQuery}%`);
          break;
        case 'Order':
          query += ' AND (o.order_no LIKE ? OR o.order_encoded LIKE ?)';
          params.push(`%${searchQuery}%`, `%${searchQuery}%`);
          break;
      }
    }

    query += ' ORDER BY o.order_date DESC';

    const [orders] = await pool.query(query, params);

    // Map status IDs to readable names and add status change restrictions
    const ordersWithStatus = orders.map(order => ({
      ...order,
      status_name: STATUS_MAP[order.status_courier] || 'Unknown',
      status_id: order.status_courier,
      can_change_status: !LOCKED_STATUS_IDS.includes(order.status_courier),
      can_generate_invoice: order.status_courier === 28 && !order.is_invoiced, // Only delivered and not invoiced
      can_upload_proof: order.status_courier === 28 && !order.photo_delivered // Only delivered without proof
    }));

    res.json({
      success: true,
      data: ordersWithStatus,
      count: ordersWithStatus.length
    });
  } catch (error) {
    console.error('Erreur lors de la récupération des missions:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des missions',
      error: error.message
    });
  }
};

// Marquer une mission comme effectuée (avec upload de preuve)
exports.completeMission = async (req, res) => {
  try {
    const missionId = validateMissionId(req.params.id);
    let preuveUrl = null;

    if (req.file) {
      const fileName = req.file.filename;
      preuveUrl = `/uploads/preuves/${fileName}`;

      // Vérifier si le fichier existe
      await fs.access(req.file.path);
    }

    // Vérifier si la mission existe avant la mise à jour
    const [mission] = await pool.query('SELECT order_id, order_prefix, order_no, driver_id, status_courier FROM cdb_add_order WHERE order_id = ?', [missionId]);
    if (mission.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Mission non trouvée.'
      });
    }

    // Check if order is already delivered
    if (mission[0].status_courier === 28) {
      return res.status(400).json({
        success: false,
        message: 'Cette commande est déjà livrée.'
      });
    }

    // Mettre à jour la base de données MySQL
    await pool.query(
      'UPDATE cdb_add_order SET status_courier = ?, photo_delivered = ? WHERE order_id = ?',
      [28, preuveUrl, missionId]
    );

    const orderTrack = `${mission[0].order_prefix || ''}${mission[0].order_no || ''}`;

    // Add tracking entry
    await pool.query(
      'INSERT INTO cdb_courier_track (order_track, comments, t_date, status_courier, user_id) VALUES (?, ?, NOW(), ?, ?)',
      [orderTrack, 'Order delivered by driver with proof', 28, mission[0].driver_id]
    );

    res.json({
      success: true,
      message: 'Mission marquée comme effectuée.',
      data: {
        missionId,
        preuveUrl,
        status_courier: 28,
        status_name: 'Delivered',
        can_generate_invoice: true
      }
    });
  } catch (error) {
    console.error('Erreur lors de la complétion de la mission:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la complétion de la mission',
      error: error.message
    });
  }
};

// Mettre à jour le statut d'une commande
const whatsappService = require('../services/whatsapp.service');

// In updateOrderStatus function, after updating the status
exports.updateOrderStatus = async (req, res) => {
  try {
    const orderId = validateMissionId(req.params.id);
    const { newStatus } = req.body;

    // Map status names to IDs (aligned with STATUS_MAP)
    const statusNameToId = {
      'Picked up': 25,    // 25: "Picked up"
      'Delivered': 28,    // 28: "Delivered" (changed from 8 to 28)
      'No answer': 29,    // 29: "No answer"
      'Cancelled': 3,     // 3: "Cancelled"
      'Rejected': 5,      // 5: "Rejected"
      'Reported': 26      // 26: "Reported"
    };

    // Check if newStatus is a number (ID) or string (name)
    let statusId = parseInt(newStatus);
    
    // If not a valid number, try to look up by name
    if (isNaN(statusId)) {
      statusId = statusNameToId[newStatus];
      if (!statusId) {
        return res.status(400).json({
          success: false,
          message: 'Statut invalide.',
          validStatuses: Object.entries(STATUS_MAP).map(([id, name]) => ({
            id: parseInt(id),
            name: name
          }))
        });
      }
    }

    // Vérifier si la commande existe et obtenir son statut actuel
    const [order] = await pool.query('SELECT order_id, order_prefix, order_no, driver_id, status_courier, receiver_name, address, price FROM cdb_add_order WHERE order_id = ?', [orderId]);
    if (order.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Commande non trouvée.'
      });
    }

    // Check if current status is locked
    if (LOCKED_STATUS_IDS.includes(order[0].status_courier)) {
      return res.status(400).json({
        success: false,
        message: `Le statut actuel "${STATUS_MAP[order[0].status_courier]}" ne peut pas être modifié.`,
        currentStatus: STATUS_MAP[order[0].status_courier]
      });
    }

    // Construct orderTrack from the order data
    const orderTrack = `${order[0].order_prefix || ''}${order[0].order_no || ''}`;

    // After successful status update
    await pool.query(
      'UPDATE cdb_add_order SET status_courier = ? WHERE order_id = ?',
      [statusId, orderId]
    );

    // Add tracking entry
    await pool.query(
      'INSERT INTO cdb_courier_track (order_track, comments, t_date, status_courier, user_id) VALUES (?, ?, NOW(), ?, ?)',
      [orderTrack, `Status updated to: ${newStatus}`, statusId, order[0].driver_id]
    );

    // Send notification to the driver
    await pool.query(
      'INSERT INTO cdb_notifications_users (user_id, notification_id, notification_read, notification_status) VALUES (?, ?, ?, ?)',
      [order[0].driver_id, null, 0, 1]
    );

    // Get driver's phone number
    const [driver] = await pool.query(
      'SELECT phone FROM cdb_users WHERE id = ?',
      [order[0].driver_id]
    );

    console.log('Driver query result:', driver);
    console.log('Driver phone:', driver && driver[0] ? driver[0].phone : 'No phone found');

    if (driver && driver[0] && driver[0].phone) {
      console.log('Sending WhatsApp notification to:', driver[0].phone);
      // Send WhatsApp notification
      const whatsappResult = await whatsappService.sendOrderUpdate(driver[0].phone, {
        order_no: orderTrack,
        status_name: newStatus,
        receiver_name: order[0].receiver_name,
        address: order[0].address,
        price: order[0].price
      });
      console.log('WhatsApp notification result:', whatsappResult);
      
      if (!whatsappResult.success) {
        console.error('WhatsApp notification failed:', whatsappResult.error);
      }
    } else {
      console.log('No driver phone found, skipping WhatsApp notification');
    }

    res.json({
      success: true,
      message: 'Status updated successfully',
      data: {
        orderId,
        newStatus,
        status_id: statusId,
        can_change_status: !LOCKED_STATUS_IDS.includes(statusId)
      }
    });
  } catch (error) {
    console.error('Erreur lors de la mise à jour du statut:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la mise à jour du statut',
      error: error.message
    });
  }
};

// Generate invoice for delivered order
exports.generateInvoice = async (req, res) => {
  try {
    const orderId = validateMissionId(req.params.id);

    // Check if order exists and is delivered
    const [order] = await pool.query('SELECT order_id, order_no, status_courier, is_invoiced FROM cdb_add_order WHERE order_id = ?', [orderId]);
    if (order.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Commande non trouvée.'
      });
    }

    if (order[0].status_courier !== 28) {
      return res.status(400).json({
        success: false,
        message: 'La facture ne peut être générée que pour les commandes livrées.'
      });
    }

    if (order[0].is_invoiced) {
      return res.status(400).json({
        success: false,
        message: 'La facture a déjà été générée pour cette commande.'
      });
    }

    // Generate invoice (in a real app, this would create an actual invoice)
    const invoiceNumber = `INV-${order[0].order_no}-${Date.now()}`;
    
    // Mark as invoiced
    await pool.query(
      'UPDATE cdb_add_order SET is_invoiced = 1 WHERE order_id = ?',
      [orderId]
    );

    res.json({
      success: true,
      message: 'Facture générée avec succès.',
      data: {
        orderId,
        invoiceNumber,
        orderNo: order[0].order_no
      }
    });
  } catch (error) {
    console.error('Erreur lors de la génération de la facture:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la génération de la facture',
      error: error.message
    });
  }
};

// Upload delivery proof
exports.uploadDeliveryProof = async (req, res) => {
  try {
    const orderId = validateMissionId(req.params.id);

    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'Aucun fichier fourni.'
      });
    }

    // Check if order exists and is delivered
    const [order] = await pool.query('SELECT order_id, order_no, status_courier, photo_delivered FROM cdb_add_order WHERE order_id = ?', [orderId]);
    if (order.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Commande non trouvée.'
      });
    }

    if (order[0].status_courier !== 28) {
      return res.status(400).json({
        success: false,
        message: 'La preuve de livraison ne peut être uploadée que pour les commandes livrées.'
      });
    }

    if (order[0].photo_delivered) {
      return res.status(400).json({
        success: false,
        message: 'Une preuve de livraison existe déjà pour cette commande.'
      });
    }

    const fileName = req.file.filename;
    const preuveUrl = `/uploads/preuves/${fileName}`;

    // Update order with proof
    await pool.query(
      'UPDATE cdb_add_order SET photo_delivered = ? WHERE order_id = ?',
      [preuveUrl, orderId]
    );

    res.json({
      success: true,
      message: 'Preuve de livraison uploadée avec succès.',
      data: {
        orderId,
        preuveUrl,
        fileName
      }
    });
  } catch (error) {
    console.error('Erreur lors de l\'upload de la preuve:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de l\'upload de la preuve',
      error: error.message
    });
  }
};

// Ajouter cette nouvelle fonction d'export
exports.getDeliveryHistory = async (req, res) => {
  try {
    const driverId = req.query.driverId;
    if (!driverId) {
      return res.status(400).json({ success: false, message: 'Le paramètre driverId est manquant.' });
    }

    const [history] = await pool.query(`
     SELECT 
    o.order_id,
    o.order_no,
    o.order_prefix,
    o.order_encoded,
    o.order_date,
    o.driver_id,
    o.person_receives,
    o.address,
    o.receiver_name,
    o.city,
    c.name AS city_name,        
    o.phone,
    o.price,
    o.price_afterfee,
    o.photo_delivered,
    o.status_courier,
    o.notes,
    o.is_invoiced,
    u.fname,
    u.lname
      FROM cdb_add_order o
      LEFT JOIN cdb_users u ON o.driver_id = u.id
      LEFT JOIN cdb_cities c ON o.city = c.id   
      WHERE o.driver_id = ? AND o.status_courier IN (28, 29, 3, 5)
      ORDER BY o.order_date DESC
    `, [driverId]);

    // Map status IDs to readable names
    const historyWithStatus = history.map(order => ({
      ...order,
      status_name: STATUS_MAP[order.status_courier] || 'Unknown',
      status_id: order.status_courier
    }));

    res.json({
      success: true,
      data: historyWithStatus,
      count: historyWithStatus.length
    });
  } catch (error) {
    console.error('Erreur lors de la récupération de l\'historique:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération de l\'historique',
      error: error.message
    });
  }
};

// Get order timeline from cdb_courier_track
exports.getOrderTimeline = async (req, res) => {
  try {
    const orderId = validateMissionId(req.params.id);

    // Get order details
    const [orderRows] = await pool.query(
      'SELECT order_prefix, order_no FROM cdb_add_order WHERE order_id = ?', 
      [orderId]
    );
    
    if (orderRows.length === 0) {
      return res.status(404).json({ 
        success: false, 
        message: 'Commande non trouvée.' 
      });
    }
    
    const orderTrack = `${orderRows[0].order_prefix || ''}${orderRows[0].order_no || ''}`;

    // Debug: Check what status_courier values exist for this order
    const [debugStatuses] = await pool.query(
      `SELECT DISTINCT status_courier 
       FROM cdb_courier_track 
       WHERE order_track = ?`,
      [orderTrack]
    );
    
    console.log('Debug - status_courier values for', orderTrack, ':', debugStatuses);

    // Debug: Check what statuses exist in cdb_styles
    const [allStatuses] = await pool.query(
      `SELECT id, detail FROM cdb_styles 
       WHERE detail IS NOT NULL AND detail != '' 
       ORDER BY id`
    );
    
    console.log('Debug - Available statuses in cdb_styles:', allStatuses);

    // Get timeline with status name
    const [timeline] = await pool.query(
      `SELECT 
         t.id, 
         t.t_date, 
         t.comments, 
         t.status_courier,
         COALESCE(s.detail, CONCAT('Status #', t.status_courier)) AS status_name
       FROM cdb_courier_track t
       LEFT JOIN cdb_styles s ON s.id = t.status_courier
       WHERE t.order_track = ?
       ORDER BY t.t_date ASC, t.id ASC`,
      [orderTrack]
    );

    console.log('Debug - Timeline query result for', orderTrack, ':', JSON.stringify(timeline, null, 2));

    res.json({ 
      success: true, 
      data: timeline, 
      count: timeline.length 
    });
  } catch (error) {
    console.error('Erreur lors de la récupération du timeline:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Erreur lors de la récupération du timeline', 
      error: error.message 
    });
  }
};

// Driver earnings summary
exports.getDriverEarnings = async (req, res) => {
  try {
    const driverId = req.query.driverId;
    if (!driverId) {
      return res.status(400).json({ success: false, message: 'ID du chauffeur manquant.' });
    }

    const [rows] = await pool.query(
      `SELECT 
         COUNT(*) AS delivered_count,
         SUM(CASE WHEN status_courier = 28 THEN 1 ELSE 0 END) AS delivered_orders,
         SUM(CASE WHEN status_courier = 28 THEN CAST(price_afterfee AS DECIMAL(10,2)) ELSE 0 END) AS delivered_amount,
         SUM(CASE WHEN status_courier = 28 AND is_invoiced = 1 THEN 1 ELSE 0 END) AS invoiced_orders,
         SUM(CASE WHEN status_courier = 28 AND is_invoiced = 0 THEN 1 ELSE 0 END) AS pending_invoice_orders,
         SUM(CASE WHEN status_courier = 28 AND payment_status = 'pending' THEN 1 ELSE 0 END) AS pending_payment_invoices
       FROM cdb_add_order
       WHERE driver_id = ?`,
      [driverId]
    );

    const deliveredAmount = Number(rows[0].delivered_amount || 0);
    const deliveredOrders = Number(rows[0].delivered_orders || 0);
    const averageTicket = deliveredOrders > 0 ? deliveredAmount / deliveredOrders : 0;

    res.json({
      success: true,
      data: {
        delivered_orders: deliveredOrders,
        delivered_amount: deliveredAmount,
        average_ticket: Number(averageTicket.toFixed(2)),
        invoiced_orders: Number(rows[0].invoiced_orders || 0),
        pending_invoice_orders: Number(rows[0].pending_invoice_orders || 0),
        pending_payment_invoices: Number(rows[0].pending_payment_invoices || 0)
      }
    });
  } catch (error) {
    console.error('Erreur lors de la récupération des gains du chauffeur:', error);
    res.status(500).json({ success: false, message: 'Erreur lors de la récupération des gains du chauffeur', error: error.message });
  }
};

// Get driver profile
exports.getDriverProfile = async (req, res) => {
  try {
    const driverId = req.params.id;
    
    if (!driverId) {
      return res.status(400).json({ success: false, message: 'ID du chauffeur manquant.' });
    }

    // Récupérer les informations de base du chauffeur
    const [driver] = await pool.query(`
      SELECT 
        id,
        username,
        fname,
        lname,
        email,
        phone,
        address,
        city,
        enrollment,
        vehiclecode,
        avatar,
        created,
        lastlogin,
        cne,
        ice,
        rib,
        username,
        password
      FROM cdb_users 
      WHERE id = ? AND userlevel = 3
    `, [driverId]);

    if (driver.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Chauffeur non trouvé.'
      });
    }

    // Récupérer les statistiques du chauffeur
    const [stats] = await pool.query(`
      SELECT 
        COUNT(*) as total_orders,
        SUM(CASE WHEN status_courier = 28 THEN 1 ELSE 0 END) as delivered_orders,
        SUM(CASE WHEN status_courier = 29 THEN 1 ELSE 0 END) as returned_orders,
        SUM(CASE WHEN status_courier IN (3, 5) THEN 1 ELSE 0 END) as cancelled_orders
      FROM cdb_add_order 
      WHERE driver_id = ?
    `, [driverId]);

    const driverData = {
      ...driver[0],
      stats: stats[0] || {
        total_orders: 0,
        delivered_orders: 0,
        returned_orders: 0,
        cancelled_orders: 0
      }
    };

    res.json({
      success: true,
      data: driverData
    });
  } catch (error) {
    console.error('Erreur lors de la récupération du profil:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération du profil',
      error: error.message
    });
  }
};

// Update driver profile
exports.updateDriverProfile = async (req, res) => {
  try {
    const driverId = req.params.id;
    const { password } = req.body;

    if (!driverId) {
      return res.status(400).json({ success: false, message: 'ID du chauffeur manquant.' });
    }

    // Vérifier si le chauffeur existe
    const [driver] = await pool.query('SELECT id FROM cdb_users WHERE id = ? AND userlevel = 3', [driverId]);
    if (driver.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Chauffeur non trouvé.'
      });
    }

    if (!password) {
      return res.status(400).json({
        success: false,
        message: 'Le mot de passe est requis.'
      });
    }

    const [result] = await pool.query(
      'UPDATE cdb_users SET password = ? WHERE id = ?',
      [password, driverId]
    );

    res.json({
      success: true,
      message: 'Mot de passe mis à jour avec succès.',
      data: { driverId }
    });
  } catch (error) {
    console.error('Erreur lors de la mise à jour du mot de passe:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la mise à jour du mot de passe',
      error: error.message
    });
  }
};

// Get driver statistics
exports.getDriverStats = async (req, res) => {
  try {
    const driverId = req.query.driverId;
    
    if (!driverId) {
      return res.status(400).json({ success: false, message: 'ID du chauffeur manquant.' });
    }

    const [stats] = await pool.query(`
      SELECT 
        COUNT(*) as total,
        SUM(CASE WHEN status_courier = 28 THEN 1 ELSE 0 END) as delivered,
        SUM(CASE WHEN status_courier = 29 THEN 1 ELSE 0 END) as returned,
        SUM(CASE WHEN status_courier IN (3, 5) THEN 1 ELSE 0 END) as cancelled
      FROM cdb_add_order 
      WHERE driver_id = ?
    `, [driverId]);

    res.json({
      success: true,
      data: stats[0]
    });
  } catch (error) {
    console.error('Erreur lors de la récupération des statistiques:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des statistiques',
      error: error.message
    });
  }
};