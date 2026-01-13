import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import pool from '../config/database.js';
import dotenv from 'dotenv';
import multer from 'multer';
import path from 'path';
import fs from 'fs';
import { triggerNotification } from './notificationController.js';

dotenv.config();

// Configure multer for avatar uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadPath = path.join(process.cwd(), 'uploads', 'avatars');
    if (!fs.existsSync(uploadPath)) {
      fs.mkdirSync(uploadPath, { recursive: true });
    }
    cb(null, uploadPath);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    const ext = path.extname(file.originalname);
    cb(null, `avatar-${req.user.id}-${uniqueSuffix}${ext}`);
  }
});

const fileFilter = (req, file, cb) => {
  console.log('=== FILE FILTER DEBUG START ===');
  console.log('File object:', JSON.stringify(file, null, 2));
  console.log('Original name:', file.originalname);
  console.log('MIME type:', file.mimetype);
  console.log('Field name:', file.fieldname);
  
  // Get file extension
  const fileExtension = path.extname(file.originalname).toLowerCase();
  console.log('File extension:', fileExtension);
  
  // Very permissive validation - if it looks like an image, accept it
  const imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp', '.tiff', '.svg'];
  const hasImageExtension = imageExtensions.includes(fileExtension);
  const hasImageMimeType = file.mimetype && file.mimetype.startsWith('image/');
  
  console.log('Has image extension:', hasImageExtension);
  console.log('Has image MIME type:', hasImageMimeType);
  
  // Accept if it has an image extension OR image mime type
  if (hasImageExtension || hasImageMimeType) {
    console.log('✅ FILE ACCEPTED');
    console.log('=== FILE FILTER DEBUG END ===');
    cb(null, true);
  } else {
    console.log('❌ FILE REJECTED');
    console.log('Reason: Not recognized as image file');
    console.log('=== FILE FILTER DEBUG END ===');
    cb(new Error(`Only image files are allowed! File: ${file.originalname}, MIME: ${file.mimetype}, Extension: ${fileExtension}`), false);
  }
};

export const upload = multer({
  storage,
  fileFilter,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB limit
  }
});

// Generate JWT tokens
const generateTokens = (user) => {
  const accessToken = jwt.sign(
    {
      id: user.id,
      username: user.username,
      email: user.email,
      userlevel: user.userlevel
    },
    process.env.JWT_SECRET,
    { expiresIn: '15m' } // Short-lived access token
  );

  const refreshToken = jwt.sign(
    {
      id: user.id,
      type: 'refresh'
    },
    process.env.JWT_REFRESH_SECRET || process.env.JWT_SECRET,
    { expiresIn: '7d' } // Longer-lived refresh token
  );

  return { accessToken, refreshToken };
};

// Legacy function for backward compatibility
const generateToken = (user) => {
  const tokens = generateTokens(user);
  return tokens.accessToken;
};

// Register new user
export const register = async (req, res) => {
  try {
    const {
      username,
      password,
      email,
      fname,
      lname,
      document_type,
      document_number,
      address,
      city,
      company,
      website
    } = req.body;

    // Validate required fields
    if (!username || !password || !email) {
      return res.status(400).json({
        success: false,
        message: 'Username, password, and email are required'
      });
    }

    // Check if user already exists
    const [existingUsers] = await pool.execute(
      'SELECT id FROM cdb_users WHERE username = ? OR email = ?',
      [username, email]
    );

    if (existingUsers.length > 0) {
      return res.status(409).json({
        success: false,
        message: 'Username or email already exists'
      });
    }

    // Hash password
    const saltRounds = 12;
    const hashedPassword = await bcrypt.hash(password, saltRounds);

    // Insert new user
    const [result] = await pool.execute(
      `INSERT INTO cdb_users 
       (username, password, email, fname, lname, document_type, document_number, address, city, company, website, userlevel, ip) 
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        username,
        hashedPassword,
        email,
        fname || null,
        lname || null,
        document_type || null,
        document_number || null,
        address || null,
        city || null,
        company || null,
        website || null,
        1, // Default user level
        req.ip || req.connection.remoteAddress
      ]
    );

    // Get the created user (without password)
    const [newUser] = await pool.execute(
      'SELECT id, username, email, fname, lname, userlevel FROM cdb_users WHERE id = ?',
      [result.insertId]
    );

    // Generate tokens
    const tokens = generateTokens(newUser[0]);

    res.status(201).json({
      success: true,
      message: 'User registered successfully',
      data: {
        user: newUser[0],
        token: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        expiresIn: 900 // 15 minutes in seconds
      }
    });

  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error during registration'
    });
  }
};



// Login user
export const login = async (req, res) => {
  try {
    const { username, password } = req.body;

    // Validate input
    if (!username || !password) {
      return res.status(400).json({
        success: false,
        message: 'Username and password are required'
      });
    }

    // Find user by username or email
    const [users] = await pool.execute(
      'SELECT * FROM cdb_users WHERE username = ? OR email = ?',
      [username, username]
    );

    if (users.length === 0) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }

    const user = users[0];

    // Verify password
    const isPasswordValid = await bcrypt.compare(password, user.password);

    if (!isPasswordValid) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }

    // Generate tokens
    const tokens = generateTokens(user);

    // Return user data (without password)
    const { password: _, ...userWithoutPassword } = user;

    res.json({
      success: true,
      message: 'Login successful',
      data: {
        user: userWithoutPassword,
        token: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        expiresIn: 900, // 15 minutes in seconds
        userLevel: user.userlevel // Ajouter le niveau d'utilisateur dans la réponse
      }
    });

  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error during login'
    });
  }
};

// Refresh access token
export const refreshToken = async (req, res) => {
  try {
    const { refreshToken } = req.body;

    if (!refreshToken) {
      return res.status(401).json({
        success: false,
        message: 'Refresh token is required'
      });
    }

    // Verify refresh token
    const decoded = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET || process.env.JWT_SECRET);
    
    if (decoded.type !== 'refresh') {
      return res.status(401).json({
        success: false,
        message: 'Invalid refresh token'
      });
    }

    // Get user from database
    const [users] = await pool.execute(
      'SELECT id, username, email, userlevel FROM cdb_users WHERE id = ?',
      [decoded.id]
    );

    if (users.length === 0) {
      return res.status(401).json({
        success: false,
        message: 'User not found'
      });
    }

    // Generate new tokens
    const tokens = generateTokens(users[0]);

    res.json({
      success: true,
      message: 'Tokens refreshed successfully',
      data: {
        token: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        expiresIn: 900 // 15 minutes in seconds
      }
    });

  } catch (error) {
    console.error('Refresh token error:', error);
    res.status(401).json({
      success: false,
      message: 'Invalid or expired refresh token'
    });
  }
};

// Get current user profile
export const getProfile = async (req, res) => {
  try {
    const userId = req.user.id;

    const [users] = await pool.execute(
      `SELECT id, username, email, fname, lname, document_type, document_number, 
              address, city, company, website, userlevel, avatar 
       FROM cdb_users WHERE id = ?`,
      [userId]
    );

    if (users.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    res.json({
      success: true,
      data: {
        user: users[0]
      }
    });

  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Update user profile
export const updateProfile = async (req, res) => {
  try {
    const userId = req.user.id;
    const {
      fname,
      lname,
      ice,
      rib,
      cne,
      company,
      website
    } = req.body;

    console.log('Update profile request:', {
      userId,
      body: req.body,
      fields: { fname, lname, ice, rib, cne, company, website }
    });

    // Validation: Check that at least some fields are provided and not empty
    const fieldsToUpdate = {};
    
    if (fname !== undefined && fname !== null) {
      if (typeof fname !== 'string' || fname.trim() === '') {
        return res.status(400).json({
          success: false,
          message: 'First name cannot be empty'
        });
      }
      fieldsToUpdate.fname = fname.trim();
    }

    if (lname !== undefined && lname !== null) {
      if (typeof lname !== 'string' || lname.trim() === '') {
        return res.status(400).json({
          success: false,
          message: 'Last name cannot be empty'
        });
      }
      fieldsToUpdate.lname = lname.trim();
    }

    if (ice !== undefined && ice !== null) {
      if (typeof ice !== 'string' || ice.trim() === '') {
        return res.status(400).json({
          success: false,
          message: 'ICE number cannot be empty'
        });
      }
      fieldsToUpdate.ice = ice.trim();
    }

    if (rib !== undefined && rib !== null) {
      if (typeof rib !== 'string' || rib.trim() === '') {
        return res.status(400).json({
          success: false,
          message: 'RIB cannot be empty'
        });
      }
      fieldsToUpdate.rib = rib.trim();
    }

    if (cne !== undefined && cne !== null) {
      if (typeof cne !== 'string' || cne.trim() === '') {
        return res.status(400).json({
          success: false,
          message: 'CNE number cannot be empty'
        });
      }
      fieldsToUpdate.cne = cne.trim();
    }

    if (company !== undefined && company !== null) {
      if (typeof company !== 'string' || company.trim() === '') {
        return res.status(400).json({
          success: false,
          message: 'Company name cannot be empty'
        });
      }
      fieldsToUpdate.company = company.trim();
    }

    if (website !== undefined && website !== null) {
      if (typeof website !== 'string' || website.trim() === '') {
        return res.status(400).json({
          success: false,
          message: 'Website cannot be empty'
        });
      }
      fieldsToUpdate.website = website.trim();
    }

    // Check if at least one field is being updated
    if (Object.keys(fieldsToUpdate).length === 0) {
      return res.status(400).json({
        success: false,
        message: 'At least one field must be provided for update'
      });
    }

    // Build dynamic update query based on provided fields
    const updateFields = [];
    const updateParams = [];

    if (fieldsToUpdate.fname !== undefined) {
      updateFields.push('fname = ?');
      updateParams.push(fieldsToUpdate.fname);
    }

    if (fieldsToUpdate.lname !== undefined) {
      updateFields.push('lname = ?');
      updateParams.push(fieldsToUpdate.lname);
    }

    if (fieldsToUpdate.ice !== undefined) {
      updateFields.push('ice = ?');
      updateParams.push(fieldsToUpdate.ice);
    }

    if (fieldsToUpdate.rib !== undefined) {
      updateFields.push('rib = ?');
      updateParams.push(fieldsToUpdate.rib);
    }

    if (fieldsToUpdate.cne !== undefined) {
      updateFields.push('cne = ?');
      updateParams.push(fieldsToUpdate.cne);
    }

    if (fieldsToUpdate.company !== undefined) {
      updateFields.push('company = ?');
      updateParams.push(fieldsToUpdate.company);
    }

    if (fieldsToUpdate.website !== undefined) {
      updateFields.push('website = ?');
      updateParams.push(fieldsToUpdate.website);
    }

    // If no fields to update, return error
    if (updateFields.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'No valid fields provided for update'
      });
    }

    const updateQuery = `UPDATE cdb_users SET ${updateFields.join(', ')} WHERE id = ?`;
    updateParams.push(userId);
    
    console.log('Executing query:', updateQuery);
    console.log('With params:', updateParams);

    await pool.execute(updateQuery, updateParams);

    // Get updated user data
    const selectQuery = `SELECT id, username, email, fname, lname, ice, rib, cne, 
              company, website, userlevel, avatar
       FROM cdb_users WHERE id = ?`;
    
    console.log('Fetching updated user with query:', selectQuery);
    const [updatedUser] = await pool.execute(selectQuery, [userId]);

    console.log('Updated user data:', updatedUser[0]);

    // Trigger notification for profile update
    await triggerNotification(userId, 'profile_updated');

    res.json({
      success: true,
      message: 'Profile updated successfully',
      data: {
        user: updatedUser[0]
      }
    });

  } catch (error) {
    console.error('Update profile error details:', {
      message: error.message,
      code: error.code,
      errno: error.errno,
      sqlState: error.sqlState,
      sqlMessage: error.sqlMessage,
      stack: error.stack
    });
    res.status(500).json({
      success: false,
      message: 'Internal server error: ' + error.message
    });
  }
};

// Change password
export const changePassword = async (req, res) => {
  try {
    const userId = req.user.id;
    const { currentPassword, newPassword } = req.body;

    if (!currentPassword || !newPassword) {
      return res.status(400).json({
        success: false,
        message: 'Current password and new password are required'
      });
    }

    // Get user's current password
    const [users] = await pool.execute(
      'SELECT password FROM cdb_users WHERE id = ?',
      [userId]
    );

    if (users.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Verify current password
    const isCurrentPasswordValid = await bcrypt.compare(currentPassword, users[0].password);

    if (!isCurrentPasswordValid) {
      return res.status(401).json({
        success: false,
        message: 'Current password is incorrect'
      });
    }

    // Hash new password
    const saltRounds = 12;
    const hashedNewPassword = await bcrypt.hash(newPassword, saltRounds);

    // Update password
    await pool.execute(
      'UPDATE cdb_users SET password = ? WHERE id = ?',
      [hashedNewPassword, userId]
    );

    // Trigger notification for password change
    await triggerNotification(userId, 'password_changed');

    res.json({
      success: true,
      message: 'Password changed successfully'
    });

  } catch (error) {
    console.error('Change password error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Upload avatar
export const uploadAvatar = async (req, res) => {
  try {
    console.log('Upload avatar request received');
    console.log('File:', req.file);
    console.log('User:', req.user);

    if (!req.file) {
      console.log('No file uploaded');
      return res.status(400).json({
        success: false,
        message: 'No image file uploaded'
      });
    }

    const userId = req.user.id;
    const avatarPath = `/uploads/avatars/${req.file.filename}`;
    
    console.log('Avatar path:', avatarPath);
    console.log('User ID:', userId);

    // Delete old avatar if exists
    const [users] = await pool.execute(
      'SELECT avatar FROM cdb_users WHERE id = ?',
      [userId]
    );

    if (users.length > 0 && users[0].avatar) {
      const oldAvatarPath = path.join(process.cwd(), users[0].avatar.replace('/', path.sep));
      console.log('Old avatar path:', oldAvatarPath);
      if (fs.existsSync(oldAvatarPath)) {
        fs.unlinkSync(oldAvatarPath);
        console.log('Old avatar deleted');
      }
    }

    // Update avatar path in database
    console.log('Updating avatar in database...');
    await pool.execute(
      'UPDATE cdb_users SET avatar = ? WHERE id = ?',
      [avatarPath, userId]
    );

    // Get updated user data
    const [updatedUsers] = await pool.execute(
      'SELECT id, username, email, fname, lname, avatar, ice, rib, cne, company, website, userlevel FROM cdb_users WHERE id = ?',
      [userId]
    );

    console.log('Avatar upload successful');
    
    // Trigger notification for avatar update
    await triggerNotification(userId, 'avatar_updated');
    
    res.json({
      success: true,
      message: 'Avatar uploaded successfully',
      user: updatedUsers[0],
      avatarUrl: `${req.protocol}://${req.get('host')}${avatarPath}`
    });

  } catch (error) {
    console.error('Avatar upload error:', error);
    
    // Clean up uploaded file on error
    if (req.file && fs.existsSync(req.file.path)) {
      fs.unlinkSync(req.file.path);
    }
    
    res.status(500).json({
      success: false,
      message: 'Failed to upload avatar: ' + error.message
    });
  }
};

// Get user addresses
export const getUserAddresses = async (req, res) => {
  try {
    const userId = req.user.id;

    const [addresses] = await pool.execute(
      'SELECT id_addresses, address, country, city, zip_code FROM cdb_users_multiple_addresses WHERE user_id = ? ORDER BY id_addresses ASC',
      [userId]
    );

    res.json({
      success: true,
      addresses: addresses,
      message: `Found ${addresses.length} address${addresses.length !== 1 ? 'es' : ''}`
    });

  } catch (error) {
    console.error('Get addresses error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get addresses: ' + error.message
    });
  }
};

// Get available cities
export const getCities = async (req, res) => {
  try {
    console.log('🏙️ Getting cities from database...');

    const [cities] = await pool.execute(
      'SELECT id, name, comm FROM cdb_cities WHERE status = "active" ORDER BY name ASC'
    );

    console.log(`🏙️ Found ${cities.length} cities`);

    res.json({
      success: true,
      cities: cities,
      message: `Found ${cities.length} active cit${cities.length !== 1 ? 'ies' : 'y'}`
    });

  } catch (error) {
    console.error('Get cities error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get cities: ' + error.message
    });
  }
};
