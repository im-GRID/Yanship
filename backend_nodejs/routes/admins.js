const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const bcrypt = require('bcrypt');
const pool = require('../config/db');
const { authenticateToken, requireRole } = require('../src/middleware/auth'); 


const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, 'uploads/avatars/'),
  filename: (req, file, cb) => cb(null, file.fieldname + '-' + Date.now() + path.extname(file.originalname))
});
const upload = multer({ storage: storage });




router.get('/offices', authenticateToken, requireRole(2), async (req, res) => {
  try {
    const [offices] = await pool.query('SELECT id, name_off FROM cdb_offices');
    
    res.json({
      success: true,
      data: offices
    });
  } catch (error) {
    console.error('Error fetching offices:', error);
    res.status(500).json({ 
      success: false,
      message: 'Internal server error' 
    });
  }
});


router.post('/admins', authenticateToken, requireRole(9), async (req, res) => {
  let connection;
  try {
    const adminData = req.body;

    // Vérification des permissions supplémentaires
    // Seuls les super admins peuvent créer d'autres super admins
    if (adminData.userLevel >= 9 && req.user.userlevel !== 9) {
      return res.status(403).json({ 
        success: false,
        message: 'Insufficient permissions: Only super admins can create other super admins'
      });
    }

    const requiredFields = ['username', 'email', 'phone', 'firstName', 'lastName', 'password'];
    const missingFields = requiredFields.filter(field => !adminData[field]);
    
    if (missingFields.length > 0) {
      return res.status(400).json({ 
        success: false,
        message: 'Missing required fields',
        fields: missingFields
      });
    }

    connection = await pool.getConnection();
    await connection.beginTransaction();

    const [emailCheck] = await connection.query(
      'SELECT id FROM cdb_users WHERE email = ?',
      [adminData.email]
    );

    if (emailCheck.length > 0) {
      return res.status(400).json({ 
        success: false,
        message: 'Email already exists' 
      });
    }

    const [usernameCheck] = await connection.query(
      'SELECT id FROM cdb_users WHERE username = ?',
      [adminData.username]
    );

    if (usernameCheck.length > 0) {
      return res.status(400).json({ 
        success: false,
        message: 'Username already exists' 
      });
    }

    const hashedPassword = await bcrypt.hash(adminData.password, 10);

    const [userResult] = await connection.query(
      `INSERT INTO cdb_users (
        username, password, userlevel, name_off, 
        fname, lname, email, phone, gender, active, 
        newsletter, notes, created
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())`,
      [
        adminData.username,
        hashedPassword,
        adminData.userLevel || 0,
        adminData.nameOff || '',
        adminData.firstName,
        adminData.lastName,
        adminData.email,
        adminData.phone,
        adminData.gender || '',
        adminData.isActive === 'true' || adminData.isActive === true ? 1 : 0,
        adminData.newsletterSubscribed === 'true' || adminData.newsletterSubscribed === true ? 1 : 0,
        adminData.userNotes || '',
      ]
    );

    const userId = userResult.insertId;

    // Traitement des addresses
    if (adminData.addresses && Array.isArray(adminData.addresses)) {
      for (const address of adminData.addresses) {
        await connection.query(
          `INSERT INTO cdb_users_multiple_addresses 
          (address, country, city, zip_code, user_id) 
          VALUES (?, ?, ?, ?, ?)`,
          [
            address.street || '',
            address.country || '',
            address.city || '',
            address.zipCode || '',
            userId
          ]
        );
      }
    }

    await connection.commit();
    
    // Récupérer l'utilisateur créé
    const [newUser] = await connection.query(
      'SELECT * FROM cdb_users WHERE id = ?',
      [userId]
    );

    res.status(201).json({
      success: true,
      message: 'User created successfully',
      data: newUser[0]
    });
  } catch (error) {
    if (connection) await connection.rollback();
    console.error('Error creating admin:', error);
    res.status(500).json({ 
      success: false,
      message: 'Internal server error',
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  } finally {
    if (connection) connection.release();
  }
});





module.exports = router;
