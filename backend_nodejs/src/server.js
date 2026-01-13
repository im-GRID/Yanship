import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import path from 'path';
import http from 'http';
import { WebSocketServer } from 'ws';
import jwt from 'jsonwebtoken';
import { testConnection } from './config/database.js';
import authRoutes from './routes/authRoutes.js';
import ordersRoutes from './routes/ordersRoutes.js';
import notificationRoutes from './routes/notificationRoutes.js';
import contactRoutes from './routes/contactRoutes.js';
import clientRoutes from './routes/clientRoutes.js';


// Configure dotenv - when running from the backend_nodejs directory
dotenv.config();

const app = express();
const server = http.createServer(app);
const wss = new WebSocketServer({ server });
const PORT = process.env.PORT || 3001;

// Store WebSocket connections by user ID
const userConnections = new Map();

// WebSocket connection handler
wss.on('connection', (ws, req) => {
  // Set up heartbeat
  ws.isAlive = true;
  ws.on('pong', () => {
    ws.isAlive = true;
  });
  
  ws.on('message', (message) => {
    try {
      const data = JSON.parse(message);
      
      if (data.type === 'authenticate' && data.token) {
        // Verify JWT token
        jwt.verify(data.token, process.env.JWT_SECRET, (err, decoded) => {
          if (err) {
            ws.send(JSON.stringify({
              type: 'auth_error',
              message: 'Invalid token'
            }));
            ws.close();
            return;
          }
          
          // Remove any existing connection for this user to prevent duplicates
          if (userConnections.has(decoded.id)) {
            const oldWs = userConnections.get(decoded.id);
            if (oldWs !== ws && oldWs.readyState === 1) {
              oldWs.close();
            }
          }
          
          // Store connection with user ID
          ws.userId = decoded.id;
          userConnections.set(decoded.id, ws);
          
          ws.send(JSON.stringify({
            type: 'auth_success',
            message: 'Authenticated successfully',
            timestamp: new Date().toISOString()
          }));
        });
      } else if (data.type === 'ping') {
        // Respond to ping with pong
        ws.send(JSON.stringify({
          type: 'pong',
          timestamp: new Date().toISOString()
        }));
      }
    } catch (error) {
      console.error('WebSocket message error:', error);
    }
  });
  
  ws.on('close', (code, reason) => {
    if (ws.userId) {
      userConnections.delete(ws.userId);
    }
  });
  
  ws.on('error', (error) => {
    console.error('WebSocket error:', error);
    if (ws.userId) {
      userConnections.delete(ws.userId);
    }
  });
});

// Heartbeat to keep WebSocket connections alive
const heartbeatInterval = setInterval(() => {
  wss.clients.forEach((ws) => {
    if (!ws.isAlive) {
      return ws.terminate();
    }
    
    ws.isAlive = false;
    ws.ping();
  });
}, 30000);

// Function to send notification to specific user via WebSocket
export const sendNotificationToUser = (userId, notification) => {
  const userWs = userConnections.get(userId);
  if (userWs && userWs.readyState === 1) { // WebSocket.OPEN
    userWs.send(JSON.stringify({
      type: 'notification',
      data: notification
    }));
    return true;
  }
  return false;
};

// Middleware
app.use(cors({
  origin: process.env.CLIENT_URL || '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

// Request logging middleware
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.url}`);
  console.log('Headers:', JSON.stringify(req.headers, null, 2));
  next();
});

app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Serve static files from uploads directory
app.use('/uploads', express.static(path.join(process.cwd(), 'uploads')));

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/orders', ordersRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/contact', contactRoutes);
app.use('/api', clientRoutes);


// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({
    success: true,
    message: 'Yanship API is running!',
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

// Default route
app.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'Welcome to Yanship API',
    endpoints: {
      health: '/api/health',
      auth: {
        register: 'POST /api/auth/register',
        login: 'POST /api/auth/login',
        profile: 'GET /api/auth/profile',
        updateProfile: 'PUT /api/auth/profile',
        changePassword: 'PUT /api/auth/change-password'
      },
      orders: {
        create: 'POST /api/orders',
        getUserOrders: 'GET /api/orders',
        getRecentOrders: 'GET /api/orders/recent',
        getUserDashboard: 'GET /api/orders/dashboard',
        getOrderById: 'GET /api/orders/:id',
        updateOrder: 'PUT /api/orders/:id',
        deleteOrder: 'DELETE /api/orders/:id',
        trackOrder: 'GET /api/orders/track/:trackingNumber',
        updateStatus: 'PUT /api/orders/:id/status (admin)',
        getAllOrders: 'GET /api/orders/admin/all (admin)'
      }
    }
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Error:', err);
  
  // Handle Multer errors
  if (err.code === 'LIMIT_FILE_SIZE') {
    return res.status(400).json({
      success: false,
      message: 'File too large. Maximum size is 5MB.'
    });
  }
  
  if (err.code === 'LIMIT_UNEXPECTED_FILE') {
    return res.status(400).json({
      success: false,
      message: 'Too many files or invalid field name.'
    });
  }
  
  if (err.message === 'Only image files are allowed!' || err.message.includes('Only image files are allowed!')) {
    return res.status(400).json({
      success: false,
      message: err.message
    });
  }
  
  res.status(500).json({
    success: false,
    message: 'Internal server error',
    error: process.env.NODE_ENV === 'development' ? err.message : undefined
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    message: 'Route not found'
  });
});

// Start server
const startServer = async () => {
  try {
    // Test database connection
    const dbConnected = await testConnection();
    
    if (!dbConnected) {
      console.error('Failed to connect to database. Please check your configuration.');
      process.exit(1);
    }

    server.listen(PORT, () => {
      console.log(`Server running on port ${PORT}`);
      console.log(`API URL: http://localhost:${PORT}`);
      console.log(`WebSocket URL: ws://localhost:${PORT}`);
    });
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
};

startServer();
