// fix_and_test.js
const pool = require('./config/db');
const autoInvoiceService = require('./services/autoInvoiceService');

async function fixAndTest() {
    console.log("🔧 Correction des données et test du système...");
    
    const connection = await pool.getConnection();
    
    try {
        console.log("\n=== 1. CORRECTION DES DONNÉES ===");
        
        // Mettre à jour la commande 000001 avec une date récente et un prix correct
        console.log("🔧 Mise à jour de la commande 000001...");
        const [updateResult] = await connection.execute(`
            UPDATE cdb_add_order 
            SET order_date = NOW(), 
                price_afterfee = '200',
                price = '200'
            WHERE order_no = '000001' AND driver_id = 57
        `);
        console.log(`✅ ${updateResult.affectedRows} commande mise à jour`);

        // Vérifier la mise à jour
        const [updatedOrder] = await connection.execute(`
            SELECT order_no, status_courier, is_invoiced, price_afterfee, order_date
            FROM cdb_add_order 
            WHERE order_no = '000001' AND driver_id = 57
        `);
        
        if (updatedOrder.length > 0) {
            const order = updatedOrder[0];
            console.log(`📋 Commande mise à jour: ${order.order_no} - statut=${order.status_courier}, facturé=${order.is_invoiced}, prix=${order.price_afterfee} MAD, date=${order.order_date}`);
        }

        console.log("\n=== 2. TEST DU SYSTÈME CORRIGÉ ===");
        
        // Tester la récupération des livraisons en attente
        console.log("🔍 Test de getPendingDeliveriesForDriver(57)...");
        const pendingDeliveries = await autoInvoiceService.getPendingDeliveriesForDriver(57);
        console.log(`📦 ${pendingDeliveries.length} livraisons en attente trouvées`);

        if (pendingDeliveries.length > 0) {
            console.log("\n=== 3. GÉNÉRATION DE FACTURE ===");
            console.log("🔄 Génération manuelle de factures...");
            await autoInvoiceService.triggerManualGeneration();
        } else {
            console.log("⚠️ Aucune livraison en attente - vérification des critères...");
            
            // Debug: vérifier les critères un par un
            const [debugQuery] = await connection.execute(`
                SELECT 
                    order_no,
                    driver_id,
                    status_courier,
                    is_invoiced,
                    price_afterfee,
                    order_date,
                    DATEDIFF(NOW(), order_date) as days_old
                FROM cdb_add_order 
                WHERE driver_id = 57
                ORDER BY order_date DESC
            `);
            
            console.log("🔍 Debug des critères:");
            debugQuery.forEach(order => {
                console.log(`  - ${order.order_no}: driver_id=${order.driver_id}, status=${order.status_courier}, invoiced=${order.is_invoiced}, price=${order.price_afterfee}, days_old=${order.days_old}`);
            });
        }

    } catch (error) {
        console.error("❌ Erreur:", error);
    } finally {
        connection.release();
        await pool.end();
    }
}

fixAndTest();
