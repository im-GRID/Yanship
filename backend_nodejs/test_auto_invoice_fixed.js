// test_auto_invoice_fixed.js
const pool = require('./config/db');
const autoInvoiceService = require('./services/autoInvoiceService');

async function testAutoInvoiceSystem() {
    console.log("🔍 Test complet du système de facturation automatique...");
    
    const connection = await pool.getConnection();
    
    try {
        console.log("\n=== 1. VÉRIFICATION DES LIVREURS ===");
        
        // Vérifier tous les utilisateurs avec userlevel > 5
        const [allUsers] = await connection.execute(`
            SELECT id, username, fname, lname, userlevel, phone, active 
            FROM cdb_users 
            WHERE userlevel > 5
            ORDER BY id
        `);
        console.log(`📋 ${allUsers.length} utilisateurs avec userlevel > 5:`);
        allUsers.forEach(user => {
            console.log(`  - ID ${user.id}: ${user.fname} ${user.lname} (userlevel: ${user.userlevel}, active: ${user.active})`);
        });

        // Vérifier spécifiquement le livreur 57
        console.log("\n=== 2. VÉRIFICATION LIVREUR ID 57 ===");
        const [livreur57] = await connection.execute(`
            SELECT id, username, fname, lname, userlevel, phone, active 
            FROM cdb_users 
            WHERE id = 57
        `);
        
        if (livreur57.length > 0) {
            console.log("✅ Livreur 57 trouvé:", livreur57[0]);
            
            // Vérifier s'il est actif et a le bon userlevel
            const user = livreur57[0];
            if (user.active !== 1) {
                console.log("⚠️ Le livreur 57 n'est pas actif (active = 0)");
                console.log("🔧 Activation du livreur 57...");
                await connection.execute(`UPDATE cdb_users SET active = 1 WHERE id = 57`);
                console.log("✅ Livreur 57 activé");
            }
            
            if (user.userlevel <= 5) {
                console.log(`⚠️ Le livreur 57 a un userlevel trop bas (${user.userlevel})`);
                console.log("🔧 Mise à jour du userlevel à 6...");
                await connection.execute(`UPDATE cdb_users SET userlevel = 6 WHERE id = 57`);
                console.log("✅ Userlevel du livreur 57 mis à jour");
            }
        } else {
            console.log("❌ Livreur 57 non trouvé dans cdb_users");
            console.log("🔧 Création du livreur 57...");
            await connection.execute(`
                INSERT INTO cdb_users (id, username, fname, lname, userlevel, phone, active, email, created) 
                VALUES (57, 'driver57', 'Driver', 'Test', 6, '+212600000057', 1, 'driver57@test.com', NOW())
            `);
            console.log("✅ Livreur 57 créé");
        }

        console.log("\n=== 3. VÉRIFICATION DES COMMANDES ===");
        
        // Commandes pour le livreur 57
        const [commandes57] = await connection.execute(`
            SELECT COUNT(*) as total,
                   SUM(CASE WHEN status_courier = 28 THEN 1 ELSE 0 END) as livrees,
                   SUM(CASE WHEN is_invoiced = 0 THEN 1 ELSE 0 END) as non_facturees
            FROM cdb_add_order 
            WHERE driver_id = 57
        `);
        console.log("📦 Commandes pour livreur 57:");
        console.log("   Total:", commandes57[0].total);
        console.log("   Livrées (statut 28):", commandes57[0].livrees);
        console.log("   Non facturées:", commandes57[0].non_facturees);

        // Si pas de commandes, en créer une pour le test
        if (commandes57[0].total === 0) {
            console.log("🔧 Création d'une commande test pour le livreur 57...");
            await connection.execute(`
                INSERT INTO cdb_add_order 
                (user_id, order_no, order_date, driver_id, status_courier, is_invoiced, 
                 receiver_name, phone, city, price, price_afterfee, address) 
                VALUES 
                (1, '000001', NOW(), 57, 28, 0, 
                 'Client Test', '+212600000001', 'Casablanca', '200', '200', 'Test Address')
            `);
            console.log("✅ Commande test créée");
        }

        console.log("\n=== 4. TEST DU SERVICE AUTO-INVOICE ===");
        
        // Tester la récupération des livreurs actifs
        console.log("🔍 Test de getActiveDrivers()...");
        const activeDrivers = await autoInvoiceService.getActiveDrivers();
        console.log(`📋 ${activeDrivers.length} livreurs actifs trouvés par le service`);
        
        // Vérifier si le livreur 57 est dans la liste
        const driver57 = activeDrivers.find(d => d.id === 57);
        if (driver57) {
            console.log(`✅ Livreur 57 trouvé: ${driver57.fname} ${driver57.lname}`);
            
            // Tester la récupération des livraisons en attente
            console.log("🔍 Test de getPendingDeliveriesForDriver(57)...");
            const pendingDeliveries = await autoInvoiceService.getPendingDeliveriesForDriver(57);
            console.log(`📦 ${pendingDeliveries.length} livraisons en attente pour le livreur 57`);
            
            if (pendingDeliveries.length > 0) {
                console.log("📋 Détails des livraisons en attente:");
                pendingDeliveries.forEach(delivery => {
                    console.log(`  - ${delivery.order_no}: ${delivery.price_afterfee} MAD`);
                });
            }
        } else {
            console.log("❌ Livreur 57 non trouvé dans les livreurs actifs");
        }

        console.log("\n=== 5. TEST GÉNÉRATION MANUELLE ===");
        console.log("🔄 Test de génération manuelle de factures...");
        await autoInvoiceService.triggerManualGeneration();

    } catch (error) {
        console.error("❌ Erreur test:", error);
    } finally {
        connection.release();
        await pool.end();
    }
}

// Exécuter le test
testAutoInvoiceSystem().then(() => {
    console.log("\n✅ Test terminé");
    process.exit(0);
}).catch(error => {
    console.error("❌ Erreur fatale:", error);
    process.exit(1);
});
