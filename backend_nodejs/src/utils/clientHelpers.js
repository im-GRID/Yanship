// Client Helper Functions for Order Management
// File: backend_nodejs/src/utils/clientHelpers.js

import pool from '../config/database.js';

/**
 * Find or create a client based on order information
 * @param {Object} receiverData - Receiver data containing client info
 * @returns {Object} - { client: clientData, created: boolean }
 */
export const findOrCreateClient = async (receiverData) => {
  try {
  // Normalize all fields to null if undefined
  const name = receiverData.name ?? null;
  const phone = receiverData.phone ?? null;
  const address = receiverData.address ?? null;
  const city = receiverData.city ?? null;
  const company_name = receiverData.company_name ?? null;
  const country = receiverData.country ?? null;
  const user_id = receiverData.user_id ?? null;

    // Check if client with this phone exists for this user
    if (phone && user_id) {
      const [phoneResult] = await pool.execute(
        'SELECT * FROM cdb_clients WHERE phone = ? AND user_id = ?',
        [phone, user_id]
      );
      if (phoneResult.length > 0) {
        // Update existing client with new information
        await pool.execute(`
          UPDATE cdb_clients 
          SET name = COALESCE(?, name),
              address = COALESCE(?, address),
              city = COALESCE(?, city),
              company_name = COALESCE(?, company_name),
              country = COALESCE(?, country),
              updated_at = CURRENT_TIMESTAMP
          WHERE id = ?
        `, [name, address, city, company_name, country, phoneResult[0].id]);
        // Return updated client data
        const [updatedClient] = await pool.execute(
          'SELECT * FROM cdb_clients WHERE id = ?',
          [phoneResult[0].id]
        );
        return {
          client: updatedClient[0],
          created: false
        };
      } else {
        // Create new client if not found
        const [result] = await pool.execute(`
          INSERT INTO cdb_clients (
            name, 
            phone, 
            company_name, 
            address, 
            city,
            country,
            is_blacklisted,
            user_id
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        `, [
          name || 'Unknown',
          phone,
          company_name,
          address,
          city,
          country || 'Morocco',
          0, // Not blacklisted by default
          user_id
        ]);
        // Get the created client data
        const [newClient] = await pool.execute(
          'SELECT * FROM cdb_clients WHERE id = ?',
          [result.insertId]
        );
        return {
          client: newClient[0],
          created: true
        };
      }
    }
  } catch (error) {
    console.error('Error in findOrCreateClient:', error);
    throw error;
  }
};

/**
 * Check if a client is blacklisted
 * @param {number} clientId - Client ID to check
 * @returns {boolean} - True if blacklisted
 */
export const isClientBlacklisted = async (clientId) => {
  try {
    const [result] = await pool.execute(
      'SELECT is_blacklisted FROM cdb_clients WHERE id = ?',
      [clientId]
    );

    if (result.length === 0) {
      return false; // Client doesn't exist, allow order
    }

    return result[0].is_blacklisted === 1;
  } catch (error) {
    console.error('Error checking blacklist status:', error);
    return false; // On error, allow order
  }
};

/**
 * Update client statistics after order status change
 * @param {number} clientId - Client ID
 * @param {string} oldStatus - Previous order status
 * @param {string} newStatus - New order status
 * @param {number} orderValue - Order price
 */
export const updateClientStats = async (clientId, oldStatus, newStatus, orderValue = 0) => {
  try {
    if (!clientId) return;

    // Since your table doesn't have individual stat columns, 
    // we'll rely on the view for analytics
    // This function can be used for future enhancements or logging
    console.log(`Client ${clientId} order status changed from ${oldStatus} to ${newStatus}, value: ${orderValue}`);
    
  } catch (error) {
    console.error('Error updating client stats:', error);
  }
};

/**
 * Update client rating based on performance
 * @param {number} clientId - Client ID
 */
const updateClientRating = async (clientId) => {
  try {
    const [stats] = await pool.execute(`
      SELECT 
        total_orders,
        successful_orders,
        cancelled_orders,
        (successful_orders / NULLIF(total_orders, 0)) * 100 as success_rate
      FROM cdb_clients 
      WHERE id = ?
    `, [clientId]);

    if (stats.length === 0) return;

    const { total_orders, success_rate } = stats[0];
    
    // Calculate rating (0-5 stars) based on success rate and order volume
    let rating = 0;
    
    if (total_orders >= 1) {
      // Base rating from success rate
      rating = (success_rate / 100) * 4; // 0-4 stars from success rate
      
      // Bonus star for loyalty (more orders)
      if (total_orders >= 10) rating += 0.5;
      if (total_orders >= 25) rating += 0.3;
      if (total_orders >= 50) rating += 0.2;
      
      // Cap at 5 stars
      rating = Math.min(rating, 5);
    }

    await pool.execute(
      'UPDATE cdb_clients SET rating = ? WHERE id = ?',
      [rating.toFixed(1), clientId]
    );
  } catch (error) {
    console.error('Error updating client rating:', error);
  }
};

/**
 * Get client blacklist reason for order rejection
 * @param {number} clientId - Client ID
 * @returns {string|null} - Blacklist reason or null
 */
export const getBlacklistReason = async (clientId) => {
  try {
    // Since your table doesn't have blacklist_reason column, 
    // we'll check the history table for the latest reason
    const [result] = await pool.execute(`
      SELECT reason 
      FROM cdb_client_blacklist_history 
      WHERE client_id = ? AND action = 'BLACKLISTED'
      ORDER BY action_date DESC 
      LIMIT 1
    `, [clientId]);

    return result.length > 0 ? result[0].reason : 'Client is blacklisted';
  } catch (error) {
    console.error('Error getting blacklist reason:', error);
    return 'Client is blacklisted';
  }
};

/**
 * Search clients for order assignment
 * @param {string} searchTerm - Search term (name, phone)
 * @returns {Array} - Array of matching clients
 */
export const searchClients = async (searchTerm) => {
  try {
    const searchPattern = `%${searchTerm}%`;
    
    const [clients] = await pool.execute(`
      SELECT 
        c.id,
        c.name,
        c.phone,
        c.company_name,
        c.city,
        c.is_blacklisted,
        ca.total_orders,
        ca.delivered_orders,
        ca.success_rate
      FROM cdb_clients c
      LEFT JOIN client_analytics ca ON c.id = ca.id
      WHERE (
        c.name LIKE ? OR 
        c.phone LIKE ? OR 
        c.company_name LIKE ?
      ) AND c.is_blacklisted = false
      ORDER BY ca.success_rate DESC, ca.total_orders DESC
      LIMIT 10
    `, [searchPattern, searchPattern, searchPattern]);

    return clients;
  } catch (error) {
    console.error('Error searching clients:', error);
    return [];
  }
};

export default {
  findOrCreateClient,
  isClientBlacklisted,
  updateClientStats,
  getBlacklistReason,
  searchClients
};
