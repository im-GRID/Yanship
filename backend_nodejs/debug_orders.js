// debug_orders.js
const pool = require('./config/db');

async function debugOrders() {
    console.log("🔍 Debug des commandes du livreur 57...");
    
    const connection = await pool.getConnection();
    
    try {
        // Vérifier toutes les commandes du livreur 57
        const [allOrders] = await connection.execute(`
            SELECT order_id, order_no, status_courier, is_invoiced, price, price_afterfee, order_date
            FROM cdb_add_order 
            WHERE driver_id = 57
            ORDER BY order_date DESC
        `);
        
        console.log(`📦 ${allOrders.length} commandes trouvées pour le livreur 57:`);
        allOrders.forEach(order => {
            console.log(`  - ${order.order_no}: statut=${order.status_courier}, facturé=${order.is_invoiced}, prix=${order.price_afterfee} MAD, date=${order.order_date}`);
        });

        // Vérifier les commandes livrées (statut 28)
        const [deliveredOrders] = await connection.execute(`
            SELECT order_id, order_no, status_courier, is_invoiced, price_afterfee, order_date
            FROM cdb_add_order 
            WHERE driver_id = 57 AND status_courier = 28
            ORDER BY order_date DESC
        `);
        
        console.log(`\n✅ ${deliveredOrders.length} commandes livrées (statut 28):`);
        deliveredOrders.forEach(order => {
            console.log(`  - ${order.order_no}: facturé=${order.is_invoiced}, prix=${order.price_afterfee} MAD, date=${order.order_date}`);
        });

        // Vérifier les commandes livrées non facturées
        const [pendingOrders] = await connection.execute(`
            SELECT order_id, order_no, status_courier, is_invoiced, price_afterfee, order_date
            FROM cdb_add_order 
            WHERE driver_id = 57 AND status_courier = 28 AND is_invoiced = 0
            ORDER BY order_date DESC
        `);
        
        console.log(`\n📋 ${pendingOrders.length} commandes livrées non facturées:`);
        pendingOrders.forEach(order => {
            console.log(`  - ${order.order_no}: prix=${order.price_afterfee} MAD, date=${order.order_date}`);
        });

        // Vérifier avec une période plus large (30 jours)
        const [recentOrders] = await connection.execute(`
            SELECT order_id, order_no, status_courier, is_invoiced, price_afterfee, order_date
            FROM cdb_add_order 
            WHERE driver_id = 57 
              AND status_courier = 28 
              AND is_invoiced = 0
              AND order_date >= DATE_SUB(NOW(), INTERVAL 30 DAY)
            ORDER BY order_date DESC
        `);
        
        console.log(`\n📅 ${recentOrders.length} commandes livrées non facturées (30 derniers jours):`);
        recentOrders.forEach(order => {
            console.log(`  - ${order.order_no}: prix=${order.price_afterfee} MAD, date=${order.order_date}`);
        });

        // Si aucune commande livrée, mettre à jour une commande pour le test
        if (deliveredOrders.length === 0) {
            console.log("\n🔧 Aucune commande livrée trouvée. Mise à jour d'une commande pour le test...");
            const [updateResult] = await connection.execute(`
                UPDATE cdb_add_order 
                SET status_courier = 28, order_date = NOW()
                WHERE driver_id = 57 
                LIMIT 1
            `);
            console.log(`✅ ${updateResult.affectedRows} commande mise à jour`);
        }

    } catch (error) {
        console.error("❌ Erreur debug:", error);
    } finally {
        connection.release();
        await pool.end();
    }
}

debugOrders();
