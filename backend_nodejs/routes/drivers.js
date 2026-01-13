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

router.post('/drivers', authenticateToken, requireRole(2), upload.single('avatar'), async (req, res) => {
  let connection;
  try {
    const driverData = req.body;
    const avatarFile = req.file;

  

    const requiredFields = ['username', 'email', 'phone', 'firstName', 'lastName'];
    const missingFields = requiredFields.filter(field => !driverData[field]);
    
    if (missingFields.length > 0) {
      return res.status(400).json({ 
        success: false,
        message: 'Missing required fields',
        fields: missingFields
      });
    }

    connection = await pool.getConnection();
    await connection.beginTransaction();

    // Vérifications email/username...

    const hashedPassword = await bcrypt.hash(driverData.password, 10);
    let avatarPath = avatarFile ? 'avatars/' + avatarFile.filename : '';

    const [userResult] = await connection.query(
      `INSERT INTO cdb_users (
        username, password, userlevel, enrollment, vehiclecode, 
        fname, lname, email, phone, gender, active, 
        newsletter, notes, created, avatar
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), ?)`,
      [
        driverData.username,
        hashedPassword,
        driverData.userLevel || 3,
        driverData.vehicleRegistrationNumber || '',
        driverData.vehicleCode || '',
        driverData.firstName,
        driverData.lastName,
        driverData.email,
        driverData.phone,
        driverData.gender || '',
        driverData.isActive !== false ? 1 : 0,
        driverData.newsletterSubscribed ? 1 : 0,
        driverData.userNotes || '',
        avatarPath
      ]
    );

    const userId = userResult.insertId;

    // CORRECTION CRITIQUE: Gestion des adresses
    let addresses = [];

    // Méthode 1: Si les addresses viennent sous forme de string simple
    if (typeof driverData.addresses === 'string') {
      const addressStrings = driverData.addresses.split(';');
      for (const addrStr of addressStrings) {
        const parts = addrStr.split(',');
        if (parts.length >= 4) {
          addresses.push({
            street: parts[0] || '',
            city: parts[1] || '',
            country: parts[2] || '',
            zipCode: parts[3] || ''
          });
        }
      }
    }
    // Méthode 2: Si les addresses viennent sous forme de champs indexés
    else {
      let i = 0;
      while (req.body[`addresses[${i}][street]`] !== undefined) {
        addresses.push({
          street: req.body[`addresses[${i}][street]`] || '',
          city: req.body[`addresses[${i}][city]`] || '',
          country: req.body[`addresses[${i}][country]`] || '',
          zipCode: req.body[`addresses[${i}][zipCode]`] || ''
        });
        i++;
      }
    }


    // Insérer les adresses
    for (const address of addresses) {
      await connection.query(
        `INSERT INTO cdb_users_multiple_addresses 
        (address, country, city, zip_code, user_id) 
        VALUES (?, ?, ?, ?, ?)`,
        [
          address.street,
          address.country,
          address.city,
          address.zipCode,
          userId
        ]
      );
    }

    await connection.commit();

    // Récupérer le driver créé
    const [newDriver] = await connection.query(
      'SELECT * FROM cdb_users WHERE id = ?',
      [userId]
    );

    res.status(201).json({
      success: true,
      message: 'Driver created successfully',
      data: newDriver[0]
    });

  } catch (error) {
    if (connection) await connection.rollback();
    console.error('Error creating driver:', error);
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
