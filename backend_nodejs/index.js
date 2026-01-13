const express = require('express');
const path = require('path');
const cors = require('cors');
const bodyParser = require('body-parser');
const session = require('express-session');
require('dotenv').config();

const app = express();
const { authenticateToken } = require('./src/middleware/auth');


app.use(cors({
  origin: '*', 
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

app.use(session({
  secret: process.env.SESSION_SECRET || 'your-secret-key',
  resave: false,
  saveUninitialized: false,
  cookie: { secure: false }
}));

app.use('/webhook/whatsapp', bodyParser.urlencoded({ extended: false }));
app.use(bodyParser.json({ limit: '50mb' }));
app.use(bodyParser.urlencoded({ extended: true, limit: '50mb' }));

app.use('/uploads', express.static(path.join(__dirname, 'uploads')));
app.use('/invoices', express.static(path.join(__dirname, 'invoices')));

app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.url}`);
  next();
});

const uploadRoutes = require('./routes/upload');
const customerRoutes = require('./routes/customers');
const driverRoutes = require('./routes/drivers');
const adminRoutes = require('./routes/admins');
const usersRoutes = require('./routes/users');
const ordersRoutes = require('./routes/orders');
const citiesRoutes = require('./routes/cities');
const contactsRoutes = require('./routes/contacts');

const missionsRoutes = require('./routes/missions');
const webhookRoutes = require('./routes/webhook');
const factureRoutes = require('./routes/factures');
const autoInvoiceService = require('./services/autoInvoiceService');//do not delete
app.use('/api', uploadRoutes);
app.use('/api', authenticateToken,customerRoutes);
app.use('/api', authenticateToken,driverRoutes);
app.use('/api', authenticateToken,adminRoutes);
app.use('/users', authenticateToken, usersRoutes);
app.use('/orders', authenticateToken,ordersRoutes);
app.use('/cities', authenticateToken,citiesRoutes);
app.use('/contacts', authenticateToken,contactsRoutes);



app.use('/missions', missionsRoutes);
app.use('/webhook', webhookRoutes);
app.use('/factures', factureRoutes);


app.use('/api/factures', factureRoutes);
app.use('/', factureRoutes);

app.get('/', (req, res) => {
  res.json({ 
    message: 'API de livraison fonctionnelle avec MySQL',
    version: '1.0.0',
    endpoints: {
      missions: '/missions',
      webhooks: '/webhook',
      factures: '/factures',
      driver_dashboard: '/driver/:id/dashboard',
      driver_invoices: '/driver/:id/invoices',
      generate_invoice: '/driver/:id/generate-invoice',
      order_invoice: '/driver/:id/orders/:orderId/invoice',

      // Service automatique do not delete
      auto_invoice_start: '/factures/auto-invoice/start',
      auto_invoice_stop: '/factures/auto-invoice/stop',
      auto_invoice_status: '/factures/auto-invoice/status',
      auto_invoice_trigger: '/factures/auto-invoice/trigger',
      auto_invoice_driver: '/factures/auto-invoice/driver/:driverId'
      //do not delete
    }
  });
});

app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

app.use((err, req, res, next) => {
  console.error('Error Stack:', err.stack);
  res.status(err.status || 500).json({
    success: false,
    message: 'Une erreur est survenue sur le serveur',
    error: process.env.NODE_ENV === 'development' ? {
      message: err.message,
      stack: err.stack
    } : 'Erreur interne'
  });
});

app.use((req, res) => {
  console.log(`Route not found: ${req.method} ${req.url}`);
  res.status(404).json({
    success: false,
    message: 'Route non trouvée',
    requestedUrl: req.url,
    method: req.method
  });
});

const PORT = process.env.PORT || 3000;
console.log('🚀 Initialisation du service de facturation automatique...');
autoInvoiceService.start();
app.listen(PORT, () => {
  console.log(`Serveur Node.js en écoute sur le port ${PORT}`);
  console.log(`Environnement: ${process.env.NODE_ENV || 'development'}`);
  console.log(`URL locale: http://localhost:${PORT}`);
  console.log('Routes disponibles:');
  console.log('  - GET  / (info API)');
  console.log('  - GET  /health (health check)');
  console.log('  - GET  /missions (missions)');
  console.log('  - POST /webhook (webhooks)');
  console.log('  - GET  /driver/:id/dashboard (dashboard livreur)');
  console.log('  - GET  /driver/:id/invoices (factures livreur)');
  console.log('  - POST /driver/:id/generate-invoice (générer facture)');
  console.log('  - POST /driver/:id/orders/:orderId/invoice (générer facture commande)');
  //do not delete
  console.log('  - POST /factures/auto-invoice/start (démarrer service automatique)');
  console.log('  - POST /factures/auto-invoice/stop (arrêter service automatique)');
  console.log('  - GET  /factures/auto-invoice/status (statut service automatique)');
  console.log('  - POST /factures/auto-invoice/trigger (déclencher manuellement)');
  console.log('  - POST /factures/auto-invoice/driver/:driverId (générer facture automatique pour un livreur)');
});