import express from 'express';
import pool from '../config/database.js';

const router = express.Router();

// Submit contact message
router.post('/', async (req, res) => {
  try {
    const { name, email, phone, message } = req.body;

    // Validate required fields
    if (!name || !email || !phone || !message) {
      return res.status(400).json({
        success: false,
        message: 'All fields are required'
      });
    }

    // Validate email format
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({
        success: false,
        message: 'Please provide a valid email address'
      });
    }

    // Insert into database
    const query = `
      INSERT INTO contact_messages (name, email, phone, message, status, created_at, updated_at)
      VALUES (?, ?, ?, ?, 'new', NOW(), NOW())
    `;

    const [result] = await pool.execute(query, [name, email, phone, message]);

    console.log('Contact message saved:', {
      id: result.insertId,
      name: name,
      email: email,
      phone: phone,
      timestamp: new Date().toISOString()
    });

    res.status(201).json({
      success: true,
      message: 'Thank you for your message! We will get back to you soon.',
      data: {
        id: result.insertId,
        name: name,
        email: email,
        phone: phone,
        message: message,
        status: 'new',
        created_at: new Date().toISOString()
      }
    });

  } catch (error) {
    console.error('Error saving contact message:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error. Please try again later.'
    });
  }
});

// Get all contact messages (for admin)
router.get('/', async (req, res) => {
  try {
    const query = `
      SELECT id, name, email, phone, message, status, created_at, updated_at
      FROM contact_messages
      ORDER BY created_at DESC
    `;

    const [rows] = await pool.execute(query);

    res.json({
      success: true,
      data: rows
    });

  } catch (error) {
    console.error('Error fetching contact messages:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// Update contact message status
router.patch('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    // Validate status
    const validStatuses = ['new', 'read', 'replied'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid status. Must be one of: new, read, replied'
      });
    }

    const query = `
      UPDATE contact_messages
      SET status = ?, updated_at = NOW()
      WHERE id = ?
    `;

    const [result] = await pool.execute(query, [status, id]);

    if (result.affectedRows === 0) {
      return res.status(404).json({
        success: false,
        message: 'Contact message not found'
      });
    }

    res.json({
      success: true,
      message: 'Contact message status updated successfully'
    });

  } catch (error) {
    console.error('Error updating contact message:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

export default router;
