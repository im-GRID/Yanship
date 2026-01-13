const express = require('express');
const router = express.Router();
const pool = require('../config/db');
const { authenticateToken, requireRole } = require('../src/middleware/auth');

// Récupérer tous les messages de contact
const getAllContactMessages = async (req, res) => {
  try {
    const { status, limit = 100, offset = 0, search } = req.query;

    const limitInt = parseInt(limit, 10) || 100;
    const offsetInt = parseInt(offset, 10) || 0;

    let query = `
      SELECT id, name, email, phone, message, status, created_at, updated_at
      FROM contact_messages
    `;

    let params = [];
    let conditions = [];

    if (status) {
      conditions.push('status = ?');
      params.push(status);
    }

    if (search) {
      conditions.push('(name LIKE ? OR email LIKE ? OR phone LIKE ? OR message LIKE ?)');
      params.push(`%${search}%`, `%${search}%`, `%${search}%`, `%${search}%`);
    }

    if (conditions.length > 0) {
      query += ' WHERE ' + conditions.join(' AND ');
    }

    query += ` ORDER BY created_at DESC LIMIT ${limitInt} OFFSET ${offsetInt}`;

    const [messages] = await pool.execute(query, params);

    // Count total
    let countQuery = 'SELECT COUNT(*) as total FROM contact_messages';
    let countParams = [];
    if (conditions.length > 0) {
      countQuery += ' WHERE ' + conditions.join(' AND ');
      countParams = params;
    }
    const [countResult] = await pool.execute(countQuery, countParams);

    res.json({
      success: true,
      data: {
        messages,
        pagination: {
          total: countResult[0].total,
          limit: limitInt,
          offset: offsetInt,
          hasMore: countResult[0].total > offsetInt + messages.length
        }
      }
    });
  } catch (error) {
    console.error('Get all contact messages error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Récupérer un message de contact par ID
const getContactMessageById = async (req, res) => {
  try {
    const { id } = req.params;

    const [messages] = await pool.execute(
      'SELECT id, name, email, phone, message, status, created_at, updated_at FROM contact_messages WHERE id = ?',
      [id]
    );

    if (messages.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Message not found'
      });
    }

    res.json({
      success: true,
      data: {
        message: messages[0]
      }
    });
  } catch (error) {
    console.error('Get contact message by ID error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Supprimer un message de contact
const deleteContactMessage = async (req, res) => {
  try {
    const { id } = req.params;

    // Vérifier si le message existe
    const [existingMessages] = await pool.execute(
      'SELECT id FROM contact_messages WHERE id = ?',
      [id]
    );

    if (existingMessages.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Message not found'
      });
    }

    // Supprimer le message
    await pool.execute(
      'DELETE FROM contact_messages WHERE id = ?',
      [id]
    );

    res.json({
      success: true,
      message: 'Message deleted successfully'
    });
  } catch (error) {
    console.error('Delete contact message error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Mettre à jour le statut d'un message (optionnel)
const updateContactMessageStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    if (!status) {
      return res.status(400).json({
        success: false,
        message: 'Status is required'
      });
    }

    // Vérifier si le message existe
    const [existingMessages] = await pool.execute(
      'SELECT id FROM contact_messages WHERE id = ?',
      [id]
    );

    if (existingMessages.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Message not found'
      });
    }

    // Mettre à jour le statut
    await pool.execute(
      'UPDATE contact_messages SET status = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?',
      [status, id]
    );

    res.json({
      success: true,
      message: 'Message status updated successfully'
    });
  } catch (error) {
    console.error('Update contact message status error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Routes
router.get('/', authenticateToken, requireRole(2), getAllContactMessages);
router.get('/:id', authenticateToken, requireRole(2), getContactMessageById);
router.delete('/:id', authenticateToken, requireRole(2), deleteContactMessage);
router.put('/:id/status', authenticateToken, requireRole(2), updateContactMessageStatus);

module.exports = router;