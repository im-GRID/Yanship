const cron = require('node-cron');
const factureController = require('../controllers/factureController');
const pool = require('../config/db');
const config = require('../config/autoInvoice.config');

class AutoInvoiceService {
  constructor() {
    this.isRunning = false;
    this.lastRun = null;
    this.nextRun = null;
  }

  // Démarrer le service automatique
  start() {
    if (this.isRunning) {
      console.log('Service de facturation automatique déjà en cours d\'exécution');
      return;
    }

    // Planifier l'exécution toutes les 24 heures à 2h00 du matin
    cron.schedule(config.schedule.daily, async () => {
      console.log('🕐 Démarrage de la génération automatique de factures...');
      await this.generateInvoicesForAllDrivers();
    }, {
      scheduled: true,
      timezone: config.schedule.timezone
    });

    // Planifier aussi l'exécution toutes les heures pour les tests (optionnel)
    cron.schedule(config.schedule.hourly, async () => {
      console.log('🕐 Vérification horaire des commandes livrées...');
      await this.checkForNewDeliveries();
    }, {
      scheduled: true,
      timezone: config.schedule.timezone
    });

    this.isRunning = true;
    this.calculateNextRun();
    console.log('✅ Service de facturation automatique démarré');
    console.log(`📅 Prochaine exécution: ${this.nextRun}`);
  }

  // Arrêter le service
  stop() {
    if (!this.isRunning) {
      console.log('Service de facturation automatique déjà arrêté');
      return;
    }

    cron.getTasks().forEach(task => task.destroy());
    this.isRunning = false;
    console.log('⏹️ Service de facturation automatique arrêté');
  }

  // Générer des factures pour tous les livreurs
  async generateInvoicesForAllDrivers() {
    try {
      this.lastRun = new Date();
      console.log(`🚀 Début de la génération automatique: ${this.lastRun.toLocaleString()}`);

      // Récupérer tous les livreurs actifs
      const drivers = await this.getActiveDrivers();
      console.log(`👥 ${drivers.length} livreurs actifs trouvés`);

      let totalInvoicesGenerated = 0;
      let totalErrors = 0;

      for (const driver of drivers) {
        try {
          console.log(`📦 Traitement du livreur: ${driver.fname} ${driver.lname} (ID: ${driver.id})`);
          
          // Vérifier s'il y a des commandes livrées non facturées
          const pendingDeliveries = await this.getPendingDeliveriesForDriver(driver.id);
          
          if (pendingDeliveries.length === 0) {
            console.log(`  ℹ️ Aucune livraison en attente de facturation pour ${driver.fname} ${driver.lname}`);
            continue;
          }

          console.log(`  📋 ${pendingDeliveries.length} livraisons en attente de facturation`);

          // Générer la facture pour ce livreur
          const result = await factureController.generateDriverInvoice(driver.id, pendingDeliveries);
          
          if (result.success) {
            // Marquer les commandes comme facturées
            await this.markOrdersAsInvoiced(pendingDeliveries.map(d => d.order_id));
            
            console.log(`  ✅ Facture générée: ${result.invoiceNumber} - ${result.totalAmount} MAD`);
            totalInvoicesGenerated++;
          } else {
            console.log(`  ❌ Erreur génération facture pour ${driver.fname} ${driver.lname}:`, result.error);
            totalErrors++;
          }

        } catch (error) {
          console.error(`  ❌ Erreur traitement livreur ${driver.id}:`, error.message);
          totalErrors++;
        }
      }

      console.log(`\n📊 Résumé de la génération automatique:`);
      console.log(`  ✅ Factures générées: ${totalInvoicesGenerated}`);
      console.log(`  ❌ Erreurs: ${totalErrors}`);
      console.log(`  🕐 Durée: ${Date.now() - this.lastRun.getTime()}ms`);

      this.calculateNextRun();

    } catch (error) {
      console.error('❌ Erreur critique dans la génération automatique:', error);
    }
  }

  // Vérifier les nouvelles livraisons (exécution horaire)
  async checkForNewDeliveries() {
    try {
      const drivers = await this.getActiveDrivers();
      
      for (const driver of drivers) {
        const pendingDeliveries = await this.getPendingDeliveriesForDriver(driver.id);
        
        if (pendingDeliveries.length >= config.thresholds.alertThreshold) {
          console.log(`🚨 Livreur ${driver.fname} ${driver.lname} a ${pendingDeliveries.length} livraisons en attente - Facturation recommandée`);
        }
      }
    } catch (error) {
      console.error('Erreur vérification livraisons:', error);
    }
  }

// Récupérer tous les livreurs actifs (cdb_users avec userlevel > 5)
async getActiveDrivers() {
  const connection = await pool.getConnection();
  try {
    console.log('🔍 Recherche des livreurs actifs...');
    
    // Récupérer tous les livreurs actifs d'abord
    const [allDrivers] = await connection.execute(`
      SELECT id, fname, lname, phone, email, userlevel, active
      FROM cdb_users 
      WHERE userlevel = 3
        AND active = 1
      ORDER BY lname, fname
    `);
    
    console.log(`📋 ${allDrivers.length} livreurs actifs trouvés dans cdb_users`);
    
    if (allDrivers.length === 0) {
      console.log('⚠️ Aucun livreur actif trouvé - vérifiez les conditions userlevel = 3 et active = 1');
      return [];
    }
    
    // Filtrer ceux qui ont des commandes
    const driversWithOrders = [];
    for (const driver of allDrivers) {
      const [orderCount] = await connection.execute(`
        SELECT COUNT(*) as count
        FROM cdb_add_order 
        WHERE driver_id = ?
      `, [driver.id]);
      
      if (orderCount[0].count > 0) {
        driversWithOrders.push(driver);
        console.log(`  ✅ Livreur ${driver.fname} ${driver.lname} (ID: ${driver.id}) - ${orderCount[0].count} commandes`);
      } else {
        console.log(`  ℹ️ Livreur ${driver.fname} ${driver.lname} (ID: ${driver.id}) - aucune commande`);
      }
    }
    
    console.log(`📦 ${driversWithOrders.length} livreurs avec des commandes`);
    return driversWithOrders;
    
  } catch (error) {
    console.error('❌ Erreur récupération livreurs actifs:', error);
    return [];
  } finally {
    connection.release();
  }
}

    // Récupérer les livraisons en attente de facturation pour un livreur
    async getPendingDeliveriesForDriver(driverId) {
      const connection = await pool.getConnection();
      try {
        console.log(`🔍 Recherche des livraisons en attente pour le livreur ${driverId}...`);
        
        // Utiliser directement cdb_add_order sans jointure complexe
        const [rows] = await connection.execute(`
          SELECT 
            order_id,
            order_no,
            price_afterfee,
            order_date,
            status_courier,
            is_invoiced
          FROM cdb_add_order 
          WHERE driver_id = ? 
            AND status_courier = 28    -- Livré
            AND is_invoiced = 0        -- Non facturé
            AND order_date >= DATE_SUB(NOW(), INTERVAL ? DAY)
          ORDER BY order_date ASC
        `, [driverId, config.thresholds.lookbackDays]);
        
        console.log(`  📦 ${rows.length} livraisons en attente trouvées`);
        if (rows.length > 0) {
          console.log('  📋 Détails:');
          rows.forEach(row => {
            console.log(`    - ${row.order_no}: ${row.price_afterfee} MAD (statut: ${row.status_courier}, facturé: ${row.is_invoiced})`);
          });
        }
        
        return rows;
      } catch (error) {
        console.error(`❌ Erreur récupération livraisons en attente pour livreur ${driverId}:`, error);
        return [];
      } finally {
        connection.release();
      }
    }
    
  // Marquer les commandes comme facturées
  async markOrdersAsInvoiced(orderIds) {
    if (orderIds.length === 0) return;

    const connection = await pool.getConnection();
    try {
      const placeholders = orderIds.map(() => '?').join(',');
      await connection.execute(`
        UPDATE cdb_add_order 
        SET is_invoiced = 1, 
            status_invoice = ?,
            notes = CONCAT(COALESCE(notes, ''), ' | Facturé automatiquement le ', NOW())
        WHERE order_id IN (${placeholders})
      `, [config.statuses.invoiced, ...orderIds]);

      console.log(`  📝 ${orderIds.length} commandes marquées comme facturées`);
    } catch (error) {
      console.error('Erreur marquage commandes facturées:', error);
    } finally {
      connection.release();
    }
  }

  // Calculer la prochaine exécution
  calculateNextRun() {
    const now = new Date();
    this.nextRun = new Date(now);
    this.nextRun.setHours(13, 10, 0, 0); // 13h00 (1:00 PM)
    
    if (this.nextRun <= now) {
      this.nextRun.setDate(this.nextRun.getDate() + 1); // Demain
    }
  }

  // Obtenir le statut du service
  getStatus() {
    return {
      isRunning: this.isRunning,
      lastRun: this.lastRun,
      nextRun: this.nextRun,
      uptime: this.lastRun ? Date.now() - this.lastRun.getTime() : null
    };
  }

  // Déclencher manuellement la génération
  async triggerManualGeneration() {
    console.log('🔄 Déclenchement manuel de la génération de factures...');
    await this.generateInvoicesForAllDrivers();
  }
}

module.exports = new AutoInvoiceService();
