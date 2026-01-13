const express = require('express');
const router = express.Router();
const whatsappBotController = require('../controllers/whatsappBotController');

// Webhook endpoint for incoming WhatsApp messages
router.post('/whatsapp', whatsappBotController.handleIncomingMessage);

// Test endpoint to send welcome message
router.post('/whatsapp/welcome', whatsappBotController.sendWelcomeMessage);

module.exports = router;