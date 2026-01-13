const express = require('express');
const router = express.Router();
const factureController = require('../controllers/factureController');
const autoInvoiceService = require('../services/autoInvoiceService');
const path = require('path');
const { body, param, validationResult } = require('express-validator');

// Middleware d'authentification LIVREURS UNIQUEMENT (modifié pour API)
const requireDriverAuth = async (req, res, next) => {
  try {
    // Vérifier le driverId dans les paramètres, le corps ou les query params
    const driverId = req.params.driverId || req.body.driverId || req.query.driverId;
    
    if (!driverId) {
      console.log('Aucun driverId fourni dans la requête');
      return res.status(401).json({ 
        success: false, 
        message: 'Identifiant du livreur requis' 
      });
    }
    
    // Vérifier que le driver existe et est actif dans la base de données
    const pool = require('../config/db');
    const [rows] = await pool.execute(
      'SELECT id FROM cdb_users WHERE id = ? AND userlevel = 3 AND active = 1',
      [driverId]
    );
    
    if (rows.length === 0) {
      console.log(`Driver non trouvé ou non autorisé: ${driverId}`);
      return res.status(401).json({
        success: false,
        message: 'Livreur non trouvé ou non autorisé'
      });
    }
    
    // Ajouter l'ID du driver à la requête pour les middlewares suivants
    req.driverId = parseInt(driverId, 10);
    next();
  } catch (error) {
    console.error('Erreur lors de l\'authentification du livreur:', error);
    return res.status(500).json({
      success: false,
      message: 'Erreur serveur lors de l\'authentification'
    });
  }
};

// Dashboard LIVREUR - modifié pour accepter driverId dans l'URL
router.get('/driver/:driverId/dashboard', requireDriverAuth, async (req, res) => {
  try {
    const driverId = req.driverId;
    const { date_from, date_to } = req.query;
    
    const stats = await factureController.getDriverStats(driverId, date_from, date_to);
    
    res.json({
      success: true,
      data: stats
    });
  } catch (error) {
    console.error('Error fetching driver dashboard:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des statistiques'
    });
  }
});

// Mettre à jour le statut d'une facture
router.put('/driver/:driverId/invoices/:invoiceNumber/status', requireDriverAuth, async (req, res) => {
  try {
    const driverId = req.driverId;
    const { invoiceNumber } = req.params;
    const { status } = req.body;

    console.log('=== DÉBOGAGE ===');
    console.log('Mise à jour du statut de la facture');
    console.log('URL:', req.originalUrl);
    console.log('Headers:', req.headers);
    console.log('Params:', { driverId, invoiceNumber });
    console.log('Body:', req.body);
    console.log('Content-Type:', req.get('Content-Type'));
    console.log('================');

    if (!status) {
      return res.status(400).json({
        success: false,
        error: 'Le statut est requis'
      });
    }

    const result = await factureController.updateInvoiceStatus(invoiceNumber, driverId, status);
    
    if (result.success) {
      res.json({
        success: true,
        message: result.message,
        data: {
          invoice_number: invoiceNumber,
          status: status
        }
      });
    } else {
      res.status(400).json({
        success: false,
        error: result.error || 'Erreur lors de la mise à jour du statut'
      });
    }
  } catch (error) {
    console.error('Error updating invoice status:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur serveur lors de la mise à jour du statut',
      error: error.message
    });
  }
});

// Récupérer les factures d'un livreur
router.get('/driver/:driverId/invoices', requireDriverAuth, async (req, res) => {
  try {
    const driverId = req.driverId;
    const invoices = await factureController.getDriverInvoices(driverId);
    
    res.json({
      success: true,
      data: invoices
    });
  } catch (error) {
    console.error('Error fetching driver invoices:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des factures'
    });
  }
});

// Récupérer les livraisons d'un livreur
router.get('/driver/:driverId/deliveries', requireDriverAuth, async (req, res) => {
  try {
    const driverId = req.driverId;
    const { dateFrom, dateTo } = req.query;
    
    const deliveries = await factureController.getDriverDeliveries(driverId, dateFrom, dateTo);
    
    res.json({
      success: true,
      data: deliveries
    });
  } catch (error) {
    console.error('Error fetching driver deliveries:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des livraisons'
    });
  }
});

// Générer facture pour un livreur spécifique (période)
router.post('/driver/:driverId/generate-invoice', requireDriverAuth, async (req, res) => {
  try {
    const driverId = req.driverId;
    const { dateFrom, dateTo } = req.body;
    
    // Récupérer les livraisons pour la période
    const deliveries = await factureController.getDriverDeliveries(driverId, dateFrom, dateTo);
    
    if (deliveries.length === 0) {
      return res.status(400).json({ 
        success: false, 
        message: 'Aucune livraison trouvée pour cette période' 
      });
    }
    
    // Générer la facture
    const result = await factureController.generateDriverInvoice(driverId, deliveries);
    
    if (result.success) {
      // Sauvegarder l'enregistrement de la facture
      await factureController.saveInvoiceRecord(driverId, result);
      
      res.json({
        success: true,
        message: 'Facture générée avec succès',
        data: result
      });
    } else {
      res.status(500).json({
        success: false,
        message: 'Erreur lors de la génération de la facture',
        error: result.error
      });
    }
  } catch (error) {
    console.error('Error generating invoice:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la génération de la facture'
    });
  }
});

// Générer une facture pour une COMMANDE précise du livreur
router.post('/driver/:driverId/orders/:orderId/invoice', requireDriverAuth, async (req, res) => {
  try {
    const driverId = req.driverId;
    const { orderId } = req.params;

    const order = await factureController.getOrderForDriver(driverId, orderId);
    if (!order) {
      return res.status(404).json({
        success: false,
        message: 'Commande introuvable pour ce livreur'
      });
    }

    const result = await factureController.generateDriverOrderInvoice(driverId, order);

    if (result.success) {
      return res.json({ success: true, data: result });
    } else {
      return res.status(500).json({ success: false, message: 'Erreur génération facture', error: result.error });
    }
  } catch (error) {
    console.error('Error generating order invoice:', error);
    res.status(500).json({ success: false, message: 'Erreur interne lors de la génération de la facture' });
  }
});

// Route originale pour la compatibilité session (si nécessaire)
router.get('/generate-invoice', async (req, res) => {
  try {
    // Vérifier d'abord la session
    if (!req.session?.driver) {
      return res.status(401).json({ 
        success: false, 
        message: 'Authentification requise' 
      });
    }
    
    const driverId = req.session.driver.id;
    const deliveries = await factureController.getDriverDeliveries(driverId);
    
    if (deliveries.length === 0) {
      return res.status(400).json({ 
        success: false, 
        message: 'Aucune livraison trouvée' 
      });
    }
    
    const result = await factureController.generateDriverInvoice(driverId, deliveries);
    
    if (result.success) {
      res.json({
        success: true,
        message: 'Facture générée avec succès',
        data: result
      });
    } else {
      res.status(500).json({
        success: false,
        message: 'Erreur lors de la génération de la facture',
        error: result.error
      });
    }
  } catch (error) {
    console.error('Error generating invoice (session):', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la génération de la facture'
    });
  }
});

// Télécharger un fichier de facture
router.get('/invoices/:fileName', (req, res) => {
  try {
    const { fileName } = req.params;
    const filePath = path.join(__dirname, '../invoices', fileName);
    
    res.download(filePath, (err) => {
      if (err) {
        console.error('Error downloading file:', err);
        res.status(404).json({
          success: false,
          message: 'Fichier de facture introuvable'
        });
      }
    });
  } catch (error) {
    console.error('Error accessing invoice file:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de l\'accès au fichier de facture'
    });
  }
});

// Statistiques du livreur
router.get('/driver/:driverId/stats', requireDriverAuth, async (req, res) => {
  try {
    const driverId = req.driverId;
    const { dateFrom, dateTo } = req.query;
    
    const stats = await factureController.getDriverStats(driverId, dateFrom, dateTo);
    
    res.json({
      success: true,
      data: stats
    });
  } catch (error) {
    console.error('Error fetching driver stats:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des statistiques'
    });
  }
});

// ===== ROUTES POUR LE SERVICE AUTOMATIQUE =====

// Démarrer le service automatique
router.post('/auto-invoice/start', async (req, res) => {
  try {
    autoInvoiceService.start();
    res.json({
      success: true,
      message: 'Service de facturation automatique démarré',
      status: autoInvoiceService.getStatus()
    });
  } catch (error) {
    console.error('Error starting auto-invoice service:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors du démarrage du service automatique'
    });
  }
});

// Arrêter le service automatique
router.post('/auto-invoice/stop', async (req, res) => {
  try {
    autoInvoiceService.stop();
    res.json({
      success: true,
      message: 'Service de facturation automatique arrêté',
      status: autoInvoiceService.getStatus()
    });
  } catch (error) {
    console.error('Error stopping auto-invoice service:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de l\'arrêt du service automatique'
    });
  }
});

// Obtenir le statut du service automatique
router.get('/auto-invoice/status', async (req, res) => {
  try {
    const status = autoInvoiceService.getStatus();
    res.json({
      success: true,
      data: status
    });
  } catch (error) {
    console.error('Error getting auto-invoice status:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération du statut'
    });
  }
});

// Déclencher manuellement la génération automatique
router.post('/auto-invoice/trigger', async (req, res) => {
  try {
    await autoInvoiceService.triggerManualGeneration();
    res.json({
      success: true,
      message: 'Génération automatique déclenchée manuellement',
      status: autoInvoiceService.getStatus()
    });
  } catch (error) {
    console.error('Error triggering manual generation:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors du déclenchement manuel'
    });
  }
});

// Générer automatiquement les factures pour un livreur spécifique
router.post('/auto-invoice/driver/:driverId', requireDriverAuth, async (req, res) => {
  try {
    const driverId = req.driverId;
    
    // Récupérer les livraisons en attente
    const pendingDeliveries = await autoInvoiceService.getPendingDeliveriesForDriver(driverId);
    
    if (pendingDeliveries.length === 0) {
      return res.json({
        success: true,
        message: 'Aucune livraison en attente de facturation',
        data: { deliveries: 0, invoiceGenerated: false }
      });
    }

    // Générer la facture
    const result = await factureController.generateDriverInvoice(driverId, pendingDeliveries);
    
    if (result.success) {
      // Marquer les commandes comme facturées
      await autoInvoiceService.markOrdersAsInvoiced(pendingDeliveries.map(d => d.order_id));
      
      res.json({
        success: true,
        message: 'Facture générée automatiquement avec succès',
        data: {
          invoiceNumber: result.invoiceNumber,
          totalAmount: result.totalAmount,
          deliveries: pendingDeliveries.length,
          invoiceGenerated: true
        }
      });
      } else {
        res.status(500).json({
          success: false,
          message: 'Erreur lors de la génération automatique',
          error: result.error
        });
      }
    } catch (error) {
      console.error('Error auto-generating invoice for driver:', error);
      res.status(500).json({
        success: false,
        message: 'Erreur lors de la génération automatique'
      });
    }
  });

// Vérifier le statut de paiement d'une facture
router.get('/driver/:driverId/invoice/:invoiceNumber/status', 
  [
    param('driverId').isInt().toInt(),
    param('invoiceNumber').isString().trim().notEmpty()
  ],
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    try {
      const { driverId, invoiceNumber } = req.params;
      const result = await factureController.checkInvoicePaymentStatus(invoiceNumber, driverId);
      
      if (!result.success) {
        return res.status(404).json(result);
      }
      
      res.json(result);
    } catch (error) {
      console.error('Error checking invoice status:', error);
      res.status(500).json({
        success: false,
        message: 'Erreur lors de la vérification du statut de la facture'
      });
    }
  }
);

// Enregistrer un paiement pour une facture
router.post('/driver/:driverId/invoice/:invoiceNumber/pay',
  [
    param('driverId').isInt().toInt(),
    param('invoiceNumber').isString().trim().notEmpty(),
    body('amount').isFloat({ min: 0 }),
    body('paymentMethod').optional().isString().trim(),
    body('transactionId').optional().isString().trim()
  ],
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    try {
      const { driverId, invoiceNumber } = req.params;
      const { amount, paymentMethod = 'bank_transfer', transactionId = null } = req.body;
      
      const result = await factureController.recordInvoicePayment(
        invoiceNumber,
        driverId,
        amount,
        paymentMethod,
        transactionId
      );
      
      if (!result.success) {
        return res.status(400).json(result);
      }
      
      res.json(result);
    } catch (error) {
      console.error('Error recording payment:', error);
      res.status(500).json({
        success: false,
        message: 'Erreur lors de l\'enregistrement du paiement'
      });
    }
  }
);

// Obtenir l'historique des paiements d'un livreur
router.get('/driver/:driverId/payments', 
  [param('driverId').isInt().toInt()],
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    try {
      const { driverId } = req.params;
      const { startDate, endDate, status } = req.query;
      
      const connection = await pool.getConnection();
      let query = `
        SELECT 
          ip.id,
          ip.invoice_number,
          ip.amount,
          ip.status,
          ip.payment_date,
          ip.payment_method,
          ip.transaction_id,
          ip.created_at,
          o.order_date
        FROM cdb_invoice_payments ip
        JOIN cdb_add_order o ON ip.invoice_number = o.invoice_number
        WHERE ip.driver_id = ?
      `;
      
      const params = [driverId];
      
      // Filtres optionnels
      if (startDate) {
        query += ' AND DATE(ip.payment_date) >= ?';
        params.push(startDate);
      }
      
      if (endDate) {
        query += ' AND DATE(ip.payment_date) <= ?';
        params.push(endDate);
      }
      
      if (status) {
        query += ' AND ip.status = ?';
        params.push(status);
      }
      
      query += ' ORDER BY ip.payment_date DESC';
      
      const [payments] = await connection.execute(query, params);
      connection.release();
      
      res.json({
        success: true,
        data: payments.map(p => ({
          id: p.id,
          invoice_number: p.invoice_number,
          amount: parseFloat(p.amount),
          status: p.status,
          payment_date: p.payment_date,
          payment_method: p.payment_method,
          transaction_id: p.transaction_id,
          order_date: p.order_date
        }))
      });
      
    } catch (error) {
      console.error('Error fetching payment history:', error);
      res.status(500).json({
        success: false,
        message: 'Erreur lors de la récupération de l\'historique des paiements'
      });
    }
  }
);

// Mettre à jour le statut d'une facture

// Mettre à jour le statut d'une facture
router.put('/driver/:driverId/invoices/:invoiceNumber/status', requireDriverAuth, [
  param('driverId').isInt().toInt(),
  param('invoiceNumber').isString().trim().notEmpty(),
  body('status').isString().trim().notEmpty()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Erreur de validation',
        errors: errors.array()
      });
    }

    const { driverId, invoiceNumber } = req.params;
    const { status } = req.body;

    const result = await factureController.updateInvoiceStatus(invoiceNumber, driverId, status);
    
    if (!result.success) {
      return res.status(400).json({
        success: false,
        message: result.error || 'Erreur lors de la mise à jour du statut de la facture'
      });
    }

    res.json({
      success: true,
      message: result.message,
      data: {
        invoiceNumber: result.invoiceNumber,
        status: result.status
      }
    });
  } catch (error) {
    console.error('Error updating invoice status:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur serveur lors de la mise à jour du statut de la facture',
      error: error.message
    });
  }
});

module.exports = router;