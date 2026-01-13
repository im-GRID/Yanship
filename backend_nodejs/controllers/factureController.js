const pool = require('../config/db');
const path = require('path');
const fs = require('fs').promises;
const fss = require('fs');
const PDFDocument = require('pdfkit');
const { v4: uuidv4 } = require('uuid');

// Configuration Yan Ship
const COMPANY_INFO = {
  name: "Yan Ship S.A.R.L",
  address: "Maroc",
  phone: "+212 661 421 738",
  email: "contact@yanship.ma",
  website: "yanship.ma"
};

// Path to company logo (PNG/JPG). Place your file at backend_nodejs/assets/logo.png
const LOGO_PATH = path.join(__dirname, '../assets/logo.png');

// Configuration des produits
const PRODUCTS = {
  'TR-40': { price: 33.33, description: '[TR-40] COLIS' },
  'TR-45': { price: 37.50, description: '[TR-45] COLIS' },
  'TR-60': { price: 50.00, description: '[TR-60] COLIS' }
};

class FactureController {
  constructor() {
    this.invoiceCounter = this.loadInvoiceCounter();
  }

  // Récupérer le taux de TVA depuis la configuration (cdb_settings.tax), défaut 20%
  async getVatRate() {
    const connection = await pool.getConnection();
    try {
      const [rows] = await connection.execute('SELECT tax FROM cdb_settings LIMIT 1');
      if (rows.length && rows[0].tax != null) {
        const v = parseFloat(rows[0].tax);
        if (!isNaN(v) && v >= 0) return v; // pourcentage ex: 20
      }
      return 20; // fallback Maroc 20%
    } catch (e) {
      console.warn('TVA non trouvée, utilisation du défaut 20%');
      return 20;
    } finally {
      connection.release();
    }
  }


  // Récupérer les factures d'un livreur avec statut de paiement
  async getDriverInvoices(driverId) {
    const connection = await pool.getConnection();
    try {
      const [rows] = await connection.execute(`
        SELECT 
          o.order_id,
          o.order_no,
          o.driver_id,
          CASE 
            WHEN o.price_afterfee > 0 THEN o.price_afterfee 
            ELSE o.price 
          END AS amount,
          o.order_date,
          o.payment_status,
          o.invoice_number,
          ip.payment_date,
          ip.payment_method,
          ip.transaction_id
        FROM cdb_add_order o
        LEFT JOIN cdb_invoice_payments ip ON o.invoice_number = ip.invoice_number
        WHERE o.driver_id = ? AND o.status_courier = 28
        ORDER BY o.order_date DESC
        LIMIT 200
      `, [driverId]);

      return rows.map(row => ({
        id: row.order_id,
        invoice_no: row.invoice_number || `INV-${row.order_no}`,
        driver_id: row.driver_id,
        amount: Number(row.amount || 0).toFixed(2),
        status: row.payment_status || 'pending',
        payment_date: row.payment_date || null,
        payment_method: row.payment_method || null,
        transaction_id: row.transaction_id || null,
        invoice_date: row.order_date || null,
        created_at: row.order_date || null
      }));
    } catch (error) {
      console.error('Erreur récupération factures:', error);
      return [];
    } finally {
      connection.release();
    }
  }

  // Ne pas écrire en base: retourner simplement un succès et laisser
  // cdb_add_order.is_invoiced gérer l'état côté missionsController
  async saveInvoiceRecord(driverId, invoiceData) {
    try {
      return { success: true, invoiceId: null };
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  // Authentifier UNIQUEMENT un livreur
  // Authentifier UNIQUEMENT un livreur (userlevel > 5)
  async authenticateDriver(username, password) {
    const connection = await pool.getConnection();
    
    try {
      // Vérifier dans cdb_users avec userlevel > 5 (livreur)
      const [userRows] = await connection.execute(`
        SELECT id, username, fname, lname, userlevel, password, phone, email
        FROM cdb_users 
        WHERE (username = ? OR email = ? OR phone = ?) 
          AND active = 1 
          AND userlevel = 3
      `, [username, username, username]);

      if (userRows.length > 0) {
        const user = userRows[0];
        // Vérification simple du mot de passe
        if (password === user.password) {
          return {
            id: user.id,
            nom: user.lname,
            prenom: user.fname,
            fullName: `${user.fname} ${user.lname}`,
            telephone: user.phone || '',
            email: user.email || '',
            type: 'driver'
          };
        }
      }

      return null;

    } catch (error) {
      console.error("Erreur authentification livreur:", error);
      return null;
    } finally {
      connection.release();
    }
  }


  // Récupérer UNIQUEMENT les livraisons d'un livreur spécifique
// factureController.js - Corriger getDriverDeliveries()
async getDriverDeliveries(driverId, dateFrom = null, dateTo = null) {
  const connection = await pool.getConnection();
  
  try {
    let dateFilter = '';
    let params = [driverId];
    
    if (dateFrom && dateTo) {
      dateFilter = 'AND DATE(o.order_date) BETWEEN ? AND ?';
      params.push(dateFrom, dateTo);
    } else {
      dateFilter = 'AND DATE(o.order_date) >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)';
    }

    // Version simplifiée sans dépendre de cdb_courier_track.driver_id
    const [rows] = await connection.execute(`
      SELECT 
        u.fname as client_name,
        u.ice as ice_number,
        o.order_no as order_number,
        o.order_prefix as order_prefix,
        o.receiver_name,
        o.phone,
        o.city,
        o.price,
        o.price_afterfee,
        o.order_date,
        o.status_courier,
        d.fname as driver_firstname,
        d.lname as driver_name
      FROM cdb_add_order o
      JOIN cdb_users u ON o.user_id = u.id
      LEFT JOIN cdb_users d ON o.driver_id = d.id
      WHERE o.driver_id = ? ${dateFilter}
        AND o.status_courier = 28  -- Commandes livrées
      ORDER BY o.order_date DESC
      LIMIT 1000
    `, params);

    return rows;
    
  } catch (error) {
    console.error("Erreur récupération livraisons livreur:", error);
    return [];
  } finally {
    connection.release();
  }
}

  // Récupérer une commande précise appartenant à un livreur
   // Récupérer une commande précise appartenant à un livreur
   async getOrderForDriver(driverId, orderId) {
    const connection = await pool.getConnection();
    try {
      const [rows] = await connection.execute(`
        SELECT 
          o.order_id,
          o.order_no,
          o.order_prefix,
          o.user_id,
          o.receiver_name,
          o.address,
          o.phone,
          o.city,
          o.price,
          o.price_afterfee,
          o.order_date,
          u.fname as client_name,
          u.ice as ice_number,
          d.fname as driver_firstname,
          d.lname as driver_name,
          d.phone as driver_phone
        FROM cdb_add_order o
        JOIN cdb_users u ON o.user_id = u.id
        LEFT JOIN cdb_users d ON o.driver_id = d.id
        WHERE o.order_id = ? AND o.driver_id = ?
      `, [orderId, driverId]);

      return rows.length ? rows[0] : null;
    } catch (error) {
      console.error('Erreur récupération commande pour facture:', error);
      return null;
    } finally {
      connection.release();
    }
  }

  // Statistiques pour un livreur spécifique
  async getDriverStats(driverId, dateFrom = null, dateTo = null) {
    const [deliveries, commissionRate] = await Promise.all([
      this.getDriverDeliveries(driverId, dateFrom, dateTo),
      this.getDriverCommission(driverId)
    ]);
    
    const totalRevenue = deliveries.reduce((sum, delivery) => 
      sum + parseFloat(delivery.price || 0), 0
    );
    
    const deliveredDeliveries = deliveries.filter(d => d.status_courier == 28);
    const deliveredAmount = deliveredDeliveries.reduce((sum, delivery) => 
      sum + parseFloat(delivery.price || 0), 0
    );
    
    // Calcul des gains du livreur : commission fixe par commande moins le coût des commandes
    const totalCommission = deliveredDeliveries.length * commissionRate;
    const totalCost = deliveredDeliveries.reduce((sum, delivery) => 
      sum + parseFloat(delivery.price || 0), 0
    );
    const driverEarnings = Math.max(0, totalCommission - totalCost).toFixed(2); // S'assurer que le gain n'est pas négatif
    
    const deliveriesByStatus = deliveries.reduce((acc, delivery) => {
      const status = delivery.status_courier;
      acc[status] = (acc[status] || 0) + 1;
      return acc;
    }, {});

    return {
      totalDeliveries: deliveries.length,
      deliveredCount: deliveredDeliveries.length,
      deliveredAmount: parseFloat(driverEarnings), // Gain du livreur = nombre de livraisons * commission fixe
      totalRevenue: totalRevenue.toFixed(2),
      deliveredCount: deliveriesByStatus[28] || 0, // Statut 28 = livré
      canceledCount: deliveriesByStatus[9] || 0,
      returnedCount: deliveriesByStatus[10] || 0,
      deliveries: deliveries
    };
  }
  // Récupérer la commission d'un livreur basée sur sa ville
  async getDriverCommission(driverId) {
    const connection = await pool.getConnection();
    try {
      // Récupérer la ville du livreur et sa commission
      const [rows] = await connection.execute(`
        SELECT cc.commission_amount, u.city
        FROM cdb_users u
        LEFT JOIN cdb_city_commissions cc ON u.city = cc.city
        WHERE u.id = ? AND u.userlevel = 3
      `, [driverId]);

      if (rows.length === 0 || !rows[0].commission_amount) {
        console.log(`Aucune commission trouvée pour le livreur ${driverId} ou ville non configurée`);
        return 0; // Retourne 0 si pas de commission configurée
      }

      return parseFloat(rows[0].commission_amount);
    } catch (error) {
      console.error('Erreur lors de la récupération de la commission:', error);
      return 0; // En cas d'erreur, on considère qu'il n'y a pas de commission
    } finally {
      connection.release();
    }
  }

  // Enregistrer le paiement d'une facture
  async recordInvoicePayment(invoiceNumber, driverId, amount, paymentMethod = 'bank_transfer', transactionId = null) {
    const connection = await pool.getConnection();
    try {
      await connection.beginTransaction();
      
      // Vérifier si la facture existe et appartient au livreur
      const [invoice] = await connection.execute(
        'SELECT * FROM cdb_add_order WHERE invoice_number = ? AND driver_id = ?',
        [invoiceNumber, driverId]
      );

      if (invoice.length === 0) {
        throw new Error('Facture introuvable ou accès non autorisé');
      }

      // Mettre à jour le statut de paiement de la commande
      await connection.execute(
        'UPDATE cdb_add_order SET payment_status = ? WHERE invoice_number = ?',
        ['paid', invoiceNumber]
      );

      // Enregistrer le paiement
      await connection.execute(
        'INSERT INTO cdb_invoice_payments (invoice_number, driver_id, amount, status, payment_date, payment_method, transaction_id) VALUES (?, ?, ?, ?, NOW(), ?, ?)',
        [invoiceNumber, driverId, amount, 'paid', paymentMethod, transactionId]
      );

      await connection.commit();
      return { success: true, message: 'Paiement enregistré avec succès' };
    } catch (error) {
      await connection.rollback();
      console.error('Erreur lors de l\'enregistrement du paiement:', error);
      return { success: false, error: error.message };
    } finally {
      connection.release();
    }
  }




  // Mettre à jour le statut d'une facture
  async updateInvoiceStatus(invoiceNumber, driverId, newStatus) {
    const connection = await pool.getConnection();
    try {
      console.log(`Recherche de la facture: ${invoiceNumber} pour le driver: ${driverId}`);
      
      // Vérifier que la facture appartient bien au livreur et a le bon statut
      const cleanInvoiceNumber = invoiceNumber.replace('INV-', '');
      const [invoice] = await connection.execute(
        `SELECT order_id, order_no, payment_status 
         FROM cdb_add_order 
         WHERE ((invoice_number = ? AND invoice_number IS NOT NULL) OR order_no = ?) 
         AND driver_id = ? AND status_courier = 28`,
        [invoiceNumber, cleanInvoiceNumber, driverId]
      );
      
      console.log('Requête SQL exécutée:', {
        query: `SELECT order_id, order_no, payment_status FROM cdb_add_order 
               WHERE ((invoice_number = ? AND invoice_number IS NOT NULL) OR order_no = ?) 
               AND driver_id = ? AND status_courier = 28`,
        params: [invoiceNumber, cleanInvoiceNumber, driverId]
      });

      console.log('Résultat de la recherche:', { invoice });

      if (invoice.length === 0) {
        // Vérifier si la facture existe mais pas pour ce driver
        const [otherInvoice] = await connection.execute(
          'SELECT order_id, driver_id FROM cdb_add_order WHERE invoice_number = ?',
          [invoiceNumber]
        );
        
        if (otherInvoice.length > 0) {
          return { 
            success: false, 
            error: `Accès refusé: La facture ${invoiceNumber} appartient à un autre livreur` 
          };
        }
        
        return { 
          success: false, 
          error: `Facture non trouvée: ${invoiceNumber} pour le livreur ${driverId}` 
        };
      }

      // Mettre à jour le statut de la facture
      await connection.execute(
        `UPDATE cdb_add_order 
         SET payment_status = ? 
         WHERE ((invoice_number = ? AND invoice_number IS NOT NULL) OR order_no = ?) 
         AND driver_id = ?`,
        [newStatus, invoiceNumber, cleanInvoiceNumber, driverId]
      );
      
      // Récupérer les informations mises à jour de la facture, y compris le montant
      const [updatedInvoice] = await connection.execute(
        `SELECT order_id, order_no, invoice_number, price_afterfee as amount, payment_status 
         FROM cdb_add_order 
         WHERE ((invoice_number = ? AND invoice_number IS NOT NULL) OR order_no = ?) 
         AND driver_id = ?`,
        [invoiceNumber, cleanInvoiceNumber, driverId]
      );
      
      console.log('Statut de la facture mis à jour avec succès:', {
        invoiceNumber,
        orderNo: cleanInvoiceNumber,
        driverId,
        newStatus,
        amount: updatedInvoice[0]?.amount
      });

      return { 
        success: true, 
        message: 'Statut de la facture mis à jour avec succès',
        invoiceNumber: updatedInvoice[0]?.invoice_number || invoiceNumber,
        status: newStatus,
        amount: updatedInvoice[0]?.amount ? Number(updatedInvoice[0].amount).toFixed(2) : '0.00'
      };
    } catch (error) {
      console.error('Erreur lors de la mise à jour du statut de la facture:', error);
      return { 
        success: false, 
        error: 'Erreur lors de la mise à jour du statut: ' + error.message 
      };
    } finally {
      connection.release();
    }
  }

  // Vérifier le statut de paiement d'une facture
  async checkInvoicePaymentStatus(invoiceNumber, driverId) {
    const connection = await pool.getConnection();
    try {
      const [result] = await connection.execute(
        `SELECT o.invoice_number, o.payment_status, o.order_date, o.price_afterfee as amount,
                p.payment_date, p.payment_method, p.transaction_id
         FROM cdb_add_order o
         LEFT JOIN cdb_invoice_payments p ON o.invoice_number = p.invoice_number
         WHERE o.invoice_number = ? AND o.driver_id = ?`,
        [invoiceNumber, driverId]
      );

      if (result.length === 0) {
        return { success: false, error: 'Facture introuvable ou accès non autorisé' };
      }

      return { 
        success: true, 
        data: {
          invoice_number: result[0].invoice_number,
          status: result[0].payment_status,
          amount: result[0].amount,
          order_date: result[0].order_date,
          payment_date: result[0].payment_date,
          payment_method: result[0].payment_method,
          transaction_id: result[0].transaction_id
        }
      };
    } catch (error) {
      console.error('Erreur lors de la vérification du statut de paiement:', error);
      return { success: false, error: error.message };
    } finally {
      connection.release();
    }
  }

  // Générer facture pour un livreur (période)
  async generateDriverInvoice(driverId, deliveries) {
    const invoiceNumber = this.generateInvoiceNumber();
    const currentDate = new Date().toISOString().split('T')[0];
    const vatRate = await this.getVatRate();
    
    // Grouper les livraisons par type
    const groupedDeliveries = this.groupDeliveriesByPrice(deliveries);
    const items = Object.entries(groupedDeliveries).map(([type, orders]) => {
      const product = PRODUCTS[type];
      const qty = orders.length;
      const lineTotal = product.price * qty;
      return {
        code: type,
        name: `${product.description}`,
        quantity: qty,
        unit_cost: product.price,
        total: lineTotal
      };
    });

    const sousTotal = items.reduce((sum, it) => sum + it.total, 0);
    const tvaAmount = parseFloat((sousTotal * (vatRate / 100)).toFixed(2));
    const totalTTC = parseFloat((sousTotal + tvaAmount).toFixed(2));

    try {
      const invoicesDir = path.join(__dirname, '../invoices');
      await fs.mkdir(invoicesDir, { recursive: true });
      
      const doc = new PDFDocument({ margin: 50 });
      const fileName = `facture_${invoiceNumber}.pdf`;
      const filePath = path.join(__dirname, '../invoices', fileName);
      
      const writeStream = fss.createWriteStream(filePath);
      doc.pipe(writeStream);

      // Header avec logo
      doc.save();
      doc.rect(0, 0, doc.page.width, 80).fill('white');
      try {
        if (fss.existsSync(LOGO_PATH)) {
          doc.image(LOGO_PATH, 50, 18, { fit: [180, 44], align: 'left' });
        }
      } catch (_) { /* ignore logo errors */ }
      doc.restore();

      // Titre et numéro de facture
      doc.fillColor('#1A202C').fontSize(26).text('Facture', 50, 140);
      doc.moveDown(0.5);
      doc.fontSize(18).fillColor('#2D3748').text(invoiceNumber, 50);

      // Bloc date et client à droite
      const rightX = doc.page.width - 260;
      doc.fontSize(10).fillColor('#2D3748');
      doc.text('Date de la facture :', rightX, 140);
      doc.text(currentDate, rightX, 155);
      doc.moveDown(1);
      doc.text(deliveries[0]?.client_name || 'Client', rightX, 185);
      doc.text(`ICE ${deliveries[0]?.ice_number || '000000000'}`, rightX, 200);

      // Ligne de séparation
      doc.moveTo(50, 220).lineTo(550, 220).stroke();

      // En-tête tableau avec espacement réduit
      let tableY = 300;
      doc.font('Helvetica-Bold').fontSize(11);
      doc.text('Description', 50, tableY);
      doc.text('Quantité', 250, tableY, { width: 90, align: 'right' });
      doc.text('Prix unitaire Taxes', 340, tableY, { width: 140, align: 'right' });
      doc.text('Prix Total', 480, tableY, { width: 70, align: 'right' });
      doc.moveTo(50, tableY + 18).lineTo(doc.page.width - 50, tableY + 18).stroke('#CBD5E0');

      // Lignes de commande
      let y = tableY + 30;
      doc.font('Helvetica').fontSize(10).fillColor('#2D3748');
      items.forEach((it) => {
        const unitLabel = `${it.unit_cost.toFixed(2)} TVA ${vatRate}% VENTES`;
        doc.text(it.name, 50, y);
        doc.text(`${it.quantity} Unité(s)`, 250, y, { width: 90, align: 'right' });
        doc.text(unitLabel, 340, y, { width: 140, align: 'right' });
        doc.text(`${it.total.toFixed(2)} MAD`, 480, y, { width: 70, align: 'right' });
        y += 22;
      });

      // Totaux avec espacement réduit
      const totalsY = y + 20;
      doc.moveTo(50, totalsY).lineTo(doc.page.width - 50, totalsY).stroke('#CBD5E0');
      doc.font('Helvetica').fontSize(10).fillColor('#2D3748');
      doc.text('Sous-total', 350, totalsY + 15, { width: 120, align: 'right' });
      doc.text(`${sousTotal.toFixed(2)} MAD`, 480, totalsY + 15, { width: 70, align: 'right' });
      doc.text(`TVA ${vatRate}%`, 350, totalsY + 35, { width: 120, align: 'right' });
      doc.text(`${tvaAmount.toFixed(2)} MAD`, 480, totalsY + 35, { width: 70, align: 'right' });
      doc.font('Helvetica-Bold').text('Total', 350, totalsY + 60, { width: 120, align: 'right' });
      doc.font('Helvetica-Bold').text(`${totalTTC.toFixed(2)} MAD`, 480, totalsY + 60, { width: 70, align: 'right' });

      doc.end();
      await new Promise((resolve, reject) => {
        writeStream.on('finish', resolve);
        writeStream.on('error', reject);
      });

      await this.saveInvoiceCounter();
      return { success: true, invoiceNumber, fileName, filePath, totalAmount: totalTTC };
    } catch (error) {
      console.error('Erreur génération PDF:', error.message);
      return { success: false, error: error.message };
    }
}

  // Générer une facture pour une commande précise d'un livreur
  async generateDriverOrderInvoice(driverId, order) {
    const invoiceNumber = this.generateInvoiceNumber();
    const currentDate = new Date().toISOString().split('T')[0];
    
    // Client-style invoice: show the client total (price_afterfee) on the PDF
    const clientAmount = parseFloat(order.price || 0); // Utiliser directement price au lieu de price_afterfee
    const vatRate = await this.getVatRate(); // ex: 20 => 20%
    const vatDecimal = (vatRate || 0) / 100;
    const htAmount = clientAmount; // Le montant HT est le montant brut
    const vatAmount = 0; // TVA à 0 comme dans les autres factures
    const items = [
      {
        name: `Commande ${order.order_no}`,
        quantity: 1,
        unit_cost: clientAmount,
      },
    ];

    // Local PDF generation to avoid remote 401s
    try {
      const invoicesDir = path.join(__dirname, '../invoices');
      await fs.mkdir(invoicesDir, { recursive: true });
      
      const safeOrder = String(order.order_no || order.order_id).replace(/\//g, '-');
      const fileName = `LIVREUR-ORDER-${safeOrder}-${invoiceNumber.replace(/\//g, '-')}.pdf`;
      const filePath = path.join('./invoices', fileName);

      const writeStream = fss.createWriteStream(filePath);
      const doc = new PDFDocument({ margin: 50 });
      doc.pipe(writeStream);

      // Header avec logo
      doc.save();
      doc.rect(0, 0, doc.page.width, 80).fill('white');
      try {
        if (fss.existsSync(LOGO_PATH)) {
          doc.image(LOGO_PATH, 50, 18, { fit: [180, 44], align: 'left' });
        }
      } catch (_) { /* ignore logo errors */ }
      doc.restore();

      // Titre et numéro de facture
      doc.fillColor('#1A202C').fontSize(26).text('Facture', 50, 140);
      doc.moveDown(0.5);
      doc.fontSize(18).fillColor('#2D3748').text(invoiceNumber, 50);

      // Bloc date et client à droite
      const rightX = doc.page.width - 260;
      doc.fontSize(10).fillColor('#2D3748');
      doc.text('Date de la facture :', rightX, 140);
      doc.text(currentDate, rightX, 155);
      doc.moveDown(1);
      doc.text(order.client_name || 'Client', rightX, 185);
      doc.text(`ICE ${order.ice_number || '000000000'}`, rightX, 200);
      if (order.order_no) {
        doc.text('Origine :', rightX, 225);
        doc.text(order.order_no, rightX, 240);
      }

      // Ligne de séparation
      doc.moveTo(50, 220).lineTo(550, 220).stroke();

      // En-tête tableau avec espacement réduit
      let tableY = 300;
      doc.font('Helvetica-Bold').fontSize(11);
      doc.text('Description', 50, tableY);
      doc.text('Quantité', 250, tableY, { width: 90, align: 'right' }); // Déplacé vers la gauche
      doc.text('Prix unitaire Taxes', 340, tableY, { width: 140, align: 'right' }); // Déplacé vers la gauche
      doc.text('Prix Total', 480, tableY, { width: 70, align: 'right' }); // Déplacé vers la gauche
      doc.moveTo(50, tableY + 18).lineTo(doc.page.width - 50, tableY + 18).stroke('#CBD5E0');

      // Ligne de la commande avec espacement réduit
      let y = tableY + 30;
      doc.font('Helvetica').fontSize(10).fillColor('#2D3748');
      const unitLabel = `${htAmount.toFixed(2)} TVA ${vatRate}% VENTES`;
      doc.text(`Commande ${order.order_no}`, 50, y);
      doc.text('1 Unité(s)', 250, y, { width: 90, align: 'right' }); // Déplacé vers la gauche
      doc.text(unitLabel, 340, y, { width: 140, align: 'right' }); // Déplacé vers la gauche
      doc.text(`${clientAmount.toFixed(2)} MAD`, 480, y, { width: 70, align: 'right' }); // Déplacé vers la gauche

      // Ajuster aussi les totaux pour aligner avec les nouvelles positions
      const totalsY = y + 40;
      doc.moveTo(50, totalsY).lineTo(doc.page.width - 50, totalsY).stroke('#CBD5E0');
      doc.font('Helvetica').fontSize(10).fillColor('#2D3748');
      doc.text('Sous-total', 350, totalsY + 15, { width: 120, align: 'right' });
      doc.text(`${htAmount.toFixed(2)} MAD`, 480, totalsY + 15, { width: 70, align: 'right' });
      doc.text(`TVA ${vatRate}%`, 350, totalsY + 35, { width: 120, align: 'right' });
      doc.text(`${vatAmount.toFixed(2)} MAD`, 480, totalsY + 35, { width: 70, align: 'right' });
      doc.font('Helvetica-Bold').text('Total', 350, totalsY + 60, { width: 120, align: 'right' });
      doc.font('Helvetica-Bold').text(`${clientAmount.toFixed(2)} MAD`, 480, totalsY + 60, { width: 70, align: 'right' });

      doc.end();
      await new Promise((resolve, reject) => {
        writeStream.on('finish', resolve);
        writeStream.on('error', reject);
      });

      // Compute driver's commission (city-based) without displaying it on the PDF
      const commission = await this.getDriverCommission(driverId);

      await this.saveInvoiceCounter();
      return { 
        success: true, 
        invoiceNumber, 
        fileName, 
        filePath, 
        totalAmount: clientAmount,
        meta: {
          commission,                 // driver commission (hidden on PDF)
          driverPayout: Math.max(0, commission || 0),
          merchantNet: Math.max(0, clientAmount - (commission || 0))
        }
      };
    } catch (error) {
      console.error('Erreur génération PDF locale (commande):', error.message);
      return { success: false, error: error.message };
    }
  }

  // Grouper les livraisons par prix pour déterminer le type
  groupDeliveriesByPrice(deliveries) {
    return deliveries.reduce((groups, delivery) => {
      const price = parseFloat(delivery.price || delivery.price_afterfee || 0);
      let type = 'TR-40'; // Par défaut
      
      if (price <= 35) type = 'TR-40';
      else if (price <= 40) type = 'TR-45';
      else type = 'TR-60';
      
      if (!groups[type]) groups[type] = [];
      groups[type].push(delivery);
      return groups;
    }, {});
  }
  // Utilitaires
  loadInvoiceCounter() {
    try {
      const data = require('./driver-invoice-counter.json');
      return data.counter || 1;
    } catch (error) {
      return 1;
    }
  }

  async saveInvoiceCounter() {
    await fs.writeFile('./driver-invoice-counter.json', 
      JSON.stringify({ counter: this.invoiceCounter }));
  }

  generateInvoiceNumber() {
    const now = new Date();
    const year = now.getFullYear();
    const month = String(now.getMonth() + 1).padStart(2, '0');
    const number = String(this.invoiceCounter).padStart(5, '0');
    
    this.invoiceCounter++;
    return `LIVREUR/${year}/${month}/${number}`;
  }

  calculateTotal(items) {
    return items.reduce((sum, item) => 
      sum + (item.quantity * item.unit_cost), 0);
  }
}

module.exports = new FactureController();