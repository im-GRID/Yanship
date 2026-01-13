import express from 'express';
import {
  register,
  login,
  refreshToken,
  getProfile,
  updateProfile,
  changePassword,
  uploadAvatar,
  getUserAddresses,
  getCities,
  upload
} from '../controllers/authController.js';
import { authenticateToken } from '../middleware/auth.js';

const router = express.Router();

// Public routes
router.post('/register', register);
router.post('/login', login);
router.post('/refresh-token', refreshToken);

// Protected routes
router.get('/profile', authenticateToken, getProfile);
router.put('/profile', authenticateToken, updateProfile);
router.put('/change-password', authenticateToken, changePassword);
router.post('/upload-avatar', authenticateToken, upload.single('avatar'), uploadAvatar);
router.get('/addresses', authenticateToken, getUserAddresses);
router.get('/cities', authenticateToken, getCities);

export default router;
 