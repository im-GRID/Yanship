const express = require('express');

const multer = require('multer');

const path = require('path');

const bcrypt = require('bcrypt');

const pool = require('../config/db');


const router = express.Router();
const { authenticateToken, requireRole } = require('../src/middleware/auth'); 


const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, 'uploads/avatars/'),
  filename: (req, file, cb) => cb(null, file.fieldname + '-' + Date.now() + path.extname(file.originalname))
});
const upload = multer({ storage: storage });


//####################################################################################
//####################################################################################


router.get('/super-admins', authenticateToken, requireRole(9), async (req, res) => {
  try {
    const [users] = await pool.query(`
      SELECT id, username, email, fname, gender, lname, phone, userlevel, name_off, avatar, active, created 
      FROM cdb_users 
      WHERE userlevel = 9 
      ORDER BY created DESC
    `);
    
    res.json(users);
  } catch (error) {
    console.error('Error fetching super admins:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Récupérer la liste des User Management (userlevel = 2)
router.get('/user-managements', authenticateToken, requireRole(2), async (req, res) => {
  try {
    const [users] = await pool.query(`
      SELECT id, username, email, fname, gender, lname, phone, userlevel, name_off, active, created 
      FROM cdb_users 
      WHERE userlevel = 2 
      ORDER BY created DESC
    `);
    
    res.json(users);
  } catch (error) {
    console.error('Error fetching user managements:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Récupérer la liste des Customers (userlevel = 1)
router.get('/customers', authenticateToken, requireRole(1), async (req, res) => {
  try {
    const [users] = await pool.query(`
      SELECT id, username, email, fname, gender, lname, phone, userlevel, document_type, document_number, active, created 
      FROM cdb_users 
      WHERE userlevel = 1
      ORDER BY created DESC
    `);
    
    res.json(users);
  } catch (error) {
    console.error('Error fetching customers:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Récupérer la liste des drivers (userlevel = 3)
router.get('/drivers', authenticateToken, requireRole(1), async (req, res) => {
  try {
    const [users] = await pool.query(`
      SELECT id, username, email, fname, gender, lname, phone, userlevel, vehiclecode, enrollment, active, created 
      FROM cdb_users 
      WHERE userlevel = 3
      ORDER BY created DESC
    `);
    
    res.json(users);
  } catch (error) {
    console.error('Error fetching drivers:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

//####################################################################################
//####################################################################################


router.get('/:id', authenticateToken, requireRole(2), async (req, res) => {
  try {
    const userId = req.params.id;
    
    // Vérifier que l'utilisateur peut accéder à cette ressource
    if (req.user.userlevel < 9 && req.user.id !== parseInt(userId)) {
      return res.status(403).json({ 
        success: false,
        message: 'Access denied: Cannot view other users' 
      });
    }
    
    const [users] = await pool.query(`
      SELECT id, username, email, fname, lname, phone, userlevel, avatar, active, created ,name_off,newsletter,gender,notes
      FROM cdb_users 
      WHERE id = ?
    `, [userId]);
    
    if (users.length === 0) {
      return res.status(404).json({ 
        success: false,
        message: 'User not found' 
      });
    }
    
    res.json({
      success: true,
      data: users[0]
    });
  } catch (error) {
    console.error('Error fetching user:', error);
    res.status(500).json({ 
      success: false,
      message: 'Internal server error' 
    });
  }
});

// Récupérer un customer spécifique
router.get('/customer/:id', authenticateToken, requireRole(1), async (req, res) => {
  try {
    const userId = req.params.id;
    
    // Les user managers et super admins peuvent voir tous les customers
    if (req.user.userlevel < 2 && req.user.id !== parseInt(userId)) {
      return res.status(403).json({ 
        success: false,
        message: 'Access denied' 
      });
    }
    
    const [users] = await pool.query(`
      SELECT id, username, email, fname, lname, phone, userlevel, avatar, active, created ,document_type,document_number,newsletter,gender,notes
      FROM cdb_users 
      WHERE id = ? AND userlevel = 1
    `, [userId]);
    
    if (users.length === 0) {
      return res.status(404).json({ 
        success: false,
        message: 'Customer not found' 
      });
    }
    
    res.json({
      success: true,
      data: users[0]
    });
  } catch (error) {
    console.error('Error fetching customer:', error);
    res.status(500).json({ 
      success: false,
      message: 'Internal server error' 
    });
  }
});

// Récupérer un driver spécifique
router.get('/driver/:id', authenticateToken, requireRole(2), async (req, res) => {
  try {
    const userId = req.params.id;
    
    // Seuls les user managers et super admins peuvent voir les drivers
    if (req.user.userlevel < 2) {
      return res.status(403).json({ 
        success: false,
        message: 'Access denied: Requires user management privileges' 
      });
    }
    
    const [users] = await pool.query(`
      SELECT id, username, email, fname, lname, phone, userlevel, avatar, active, created ,vehiclecode,enrollment,newsletter,gender,notes
      FROM cdb_users 
      WHERE id = ? AND userlevel = 3
    `, [userId]);
    
    if (users.length === 0) {
      return res.status(404).json({ 
        success: false,
        message: 'Driver not found' 
      });
    }
    
    res.json({
      success: true,
      data: users[0]
    });
  } catch (error) {
    console.error('Error fetching driver:', error);
    res.status(500).json({ 
      success: false,
      message: 'Internal server error' 
    });
  }
});

//####################################################################################
//####################################################################################
// Récupérer les adresses d'un utilisateur
router.get('/:id/addresses', authenticateToken, async (req, res) => {
  try {
    const userId = req.params.id;
    
    // Un utilisateur ne peut voir que ses propres adresses
    // Sauf les admins qui peuvent tout voir
    if (req.user.userlevel < 2 && req.user.id !== parseInt(userId)) {
      return res.status(403).json({ 
        success: false,
        message: 'Access denied: Cannot view other users addresses' 
      });
    }
    
    const [addresses] = await pool.query(`
      SELECT id_addresses, address, country, city, zip_code 
      FROM cdb_users_multiple_addresses 
      WHERE user_id = ?
    `, [userId]);
    
    res.json({
      success: true,
      data: addresses
    });
  } catch (error) {
    console.error('Error fetching user addresses:', error);
    res.status(500).json({ 
      success: false,
      message: 'Internal server error' 
    });
  }
});

//####################################################################################
//####################################################################################

// Supprimer un utilisateur
router.delete('/:id', authenticateToken, requireRole(9), async (req, res) => {
  let connection;
  try {
    const userId = req.params.id;
    
    // Un super admin ne peut pas se supprimer lui-même
    if (req.user.id === parseInt(userId)) {
      return res.status(400).json({ 
        success: false,
        message: 'Cannot delete your own account' 
      });
    }
    
    connection = await pool.getConnection();
    await connection.beginTransaction();
    
    // Vérifier si l'utilisateur existe
    const [existingUsers] = await connection.query(
      'SELECT id, userlevel FROM cdb_users WHERE id = ?',
      [userId]
    );
    
    if (existingUsers.length === 0) {
      return res.status(404).json({ 
        success: false,
        message: 'User not found' 
      });
    }
    
    const userToDelete = existingUsers[0];
    
    // Empêcher la suppression d'autres super admins
    if (userToDelete.userlevel === 9 && req.user.userlevel !== 9) {
      return res.status(403).json({ 
        success: false,
        message: 'Cannot delete super admin accounts' 
      });
    }
    
    // Supprimer l'utilisateur
    await connection.query(
      'DELETE FROM cdb_users WHERE id = ?',
      [userId]
    );
    
    await connection.commit();
    
    res.json({ 
      success: true,
      message: 'User deleted successfully' 
    });
    
  } catch (error) {
    if (connection) await connection.rollback();
    console.error('Error deleting user:', error);
    res.status(500).json({ 
      success: false,
      message: 'Internal server error' 
    });
  } finally {
    if (connection) connection.release();
  }
});



//####################################################################################
//####################################################################################
router.put('/:id', upload.single('avatar'), async (req, res) => {
  let connection;
  try {
    const userId = parseInt(req.params.id); 
    const adminData = req.body;
    const avatarFile = req.file;

    connection = await pool.getConnection();
    await connection.beginTransaction();

    // Vérifier si l'utilisateur existe
    const [existingUsers] = await connection.query(
      'SELECT id FROM cdb_users WHERE id = ?',
      [userId]
    );

    if (existingUsers.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Vérifications email/username...

    // Préparer les champs à mettre à jour
    let updateFields = [];
    let updateValues = [];

    // CORRECTION : Utiliser le bon nom de champ (nameOff au lieu de name_off)
    const baseFields = {
      username: adminData.username,
      fname: adminData.firstName,
      lname: adminData.lastName,
      email: adminData.email,
      phone: adminData.phone,
      gender: adminData.gender || '',
      userlevel: adminData.userLevel || 0,
      active: adminData.isActive === true || adminData.isActive === 'true' ? 1 : 0,
      newsletter: adminData.newsletterSubscribed === true || adminData.newsletterSubscribed === 'true' ? 1 : 0,
      notes: adminData.userNotes || '',
      name_off: adminData.nameOffice || '' ,
      vehiclecode : adminData.vehicleCode || '' ,
      enrollment: adminData.vehicleRegistrationNumber || '' ,
      document_type: adminData.documentType || '' ,
      document_number: adminData.documentNumber || '' 

    };

    Object.entries(baseFields).forEach(([field, value]) => {
      updateFields.push(`${field} = ?`);
      updateValues.push(value);
    });

    // Gérer le mot de passe si fourni
    if (adminData.password) {
      const hashedPassword = await bcrypt.hash(adminData.password, 10);
      updateFields.push('password = ?');
      updateValues.push(hashedPassword);
    }

    updateValues.push(userId);

    const updateQuery = `UPDATE cdb_users SET ${updateFields.join(', ')} WHERE id = ?`;
    await connection.query(updateQuery, updateValues);

    // Mettre à jour les adresses
    await connection.query(
      'DELETE FROM cdb_users_multiple_addresses WHERE user_id = ?',
      [userId]
    );

    // CORRECTION : Traitement simplifié des addresses
    if (adminData.addresses && Array.isArray(adminData.addresses)) {
      for (const address of adminData.addresses) {
        await connection.query(
          `INSERT INTO cdb_users_multiple_addresses 
          (address, country, city, zip_code, user_id) 
          VALUES (?, ?, ?, ?, ?)`,
          [
            address.address || '',
            address.country || '',
            address.city || '',
            address.zip_code || '',
            userId
          ]
          
        );
      }
    }

    await connection.commit();
    res.json({ 
      message: 'User updated successfully',
      id: userId
    });
  } catch (error) {
    if (connection) await connection.rollback();
    console.error('Error updating user:', error);
    res.status(500).json({ 
      error: 'Internal server error',
      details: error.message 
    });
  } finally {
    if (connection) connection.release();
  }
});

//####################################################################################
//####################################################################################
module.exports = router;
