const express = require('express');
const router = express.Router();
const missionsController = require('../controllers/missionsController');
const whatsappBotController = require('../controllers/whatsappBotController');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Assurer que le dossier d'upload existe
const uploadDir = path.join(__dirname, '../uploads/preuves');
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

// Configuration de multer pour l'upload de fichiers
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, uploadDir);
  },
  filename: function (req, file, cb) {
    const missionId = req.params.id;
    const ext = path.extname(file.originalname);
    const fileName = `${missionId}_${Date.now()}${ext}`;
    cb(null, fileName);
  }
});

// Validation des types de fichiers
const fileFilter = (req, file, cb) => {
  const allowedTypes = ['image/jpeg', 'image/png', 'image/jpg', 'image/webp'];
  const allowedExts = ['.jpg', '.jpeg', '.png', '.webp'];
  const ext = path.extname(file.originalname).toLowerCase();
  console.log('uploaded file extension:', ext);
  console.log('uploaded file mimetype:', file.mimetype);
  
  if (allowedTypes.includes(file.mimetype) || 
      (file.mimetype === 'application/octet-stream' && allowedExts.includes(ext))) {
    cb(null, true);
  } else {
    cb(new Error('Type de fichier non supporté. Utilisez JPG, JPEG, PNG ou WEBP.'), false);
  }
  };

const upload = multer({
  storage: storage,
  fileFilter: fileFilter,
  limits: {
    fileSize: process.env.MAX_FILE_SIZE || 5 * 1024 * 1024 // 5MB par défaut
  }
});

// Middleware de gestion des erreurs multer
const handleMulterError = (err, req, res, next) => {
  if (err instanceof multer.MulterError) {
    if (err.code === 'LIMIT_FILE_SIZE') {
      return res.status(400).json({
        success: false,
        message: 'Le fichier est trop volumineux. Taille maximum: 5MB'
      });
    }
    return res.status(400).json({
      success: false,
      message: 'Erreur lors de l\'upload du fichier',
      error: err.message
    });
  }
  next(err);
};

// Routes for missions/orders
router.get('/', missionsController.getMissionsByLivreur);
router.get('/history', missionsController.getDeliveryHistory);

// Route pour compléter une mission avec upload de preuve
router.post('/:id/complete',
  upload.single('preuve'),
  handleMulterError,
  missionsController.completeMission
);

// Route pour mettre à jour le statut d'une mission
router.patch('/:id/status', missionsController.updateOrderStatus);

// Route pour générer une facture (nouvelle fonctionnalité)
router.post('/:id/invoice', missionsController.generateInvoice);

// Route pour uploader une preuve de livraison (nouvelle fonctionnalité)
router.post('/:id/proof',
  upload.single('proof'),
  handleMulterError,
  missionsController.uploadDeliveryProof
);

// Additional features using DB tables
router.get('/order/:id/timeline', missionsController.getOrderTimeline);
router.get('/driver/earnings', missionsController.getDriverEarnings);

// Routes for driver profile management
router.get('/driver/:id/profile', missionsController.getDriverProfile);
router.put('/driver/:id/profile', missionsController.updateDriverProfile);
router.get('/driver/stats', missionsController.getDriverStats);

// WhatsApp Bot Routes
router.post('/whatsapp/webhook', whatsappBotController.handleIncomingMessage);
router.post('/whatsapp/welcome', whatsappBotController.sendWelcomeMessage);

// Test endpoint for WhatsApp service
router.get('/test-whatsapp', async (req, res) => {
  const whatsappService = require('../services/whatsapp.service');
  
  try {
    // Test connection
    const connectionTest = await whatsappService.testConnection();
    
    // Test sending a message (replace with your phone number)
    const testPhone = '+212666666666'; // Your phone number with country code
    const result = await whatsappService.sendMessage(testPhone, 'Test message from your app!');
    
    res.json({
      connection: connectionTest,
      messageResult: result
    });
  } catch (error) {
    res.status(500).json({
      error: 'Test failed',
      message: error.message
    });
  }
});

module.exports = router;