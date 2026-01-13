// test_livreur_57.js
const pool = require('./config/db');

async function testLivreur57() {
    console.log("🔍 Test spécifique pour le livreur ID 57...");
    
    const connection = await pool.getConnection();
    
    try {
        // 1. Vérifier le livreur 57
        const [livreur] = await connection.execute(`
            SELECT id, username, fname, lname, userlevel, phone, active 
            FROM cdb_users 
            WHERE id = 57 AND userlevel > 5 AND active = 1
        `);
        console.log("📋 Livreur 57 trouvé:", livreur.length > 0);
        if (livreur.length > 0) {
            console.log("Détails:", livreur[0]);
        }

        // 2. Commandes pour le livreur 57
        const [commandes] = await connection.execute(`
            SELECT COUNT(*) as total,
                   SUM(CASE WHEN status_courier = 28 THEN 1 ELSE 0 END) as livrees,
                   SUM(CASE WHEN is_invoiced = 0 THEN 1 ELSE 0 END) as non_facturees
            FROM cdb_add_order 
            WHERE driver_id = 57
        `);
        console.log("📦 Commandes pour livreur 57:");
        console.log("   Total:", commandes[0].total);
        console.log("   Livrées (statut 28):", commandes[0].livrees);
        console.log("   Non facturées:", commandes[0].non_facturees);

        // 3. Détails des commandes livrées non facturées
        const [commandesDetails] = await connection.execute(`
            SELECT order_id, order_no, status_courier, is_invoiced, price, price_afterfee
            FROM cdb_add_order 
            WHERE driver_id = 57 
              AND status_courier = 28 
              AND is_invoiced = 0
            LIMIT 10
        `);
        console.log("🔍 Détails des commandes livrées non facturées:", commandesDetails.length);
        commandesDetails.forEach(cmd => {
            console.log(`   - ${cmd.order_no}: ${cmd.price} MAD (facturé: ${cmd.is_invoiced})`);
        });

    } catch (error) {
        console.error("Erreur test:", error);
    } finally {
        connection.release();
        await pool.end();
    }
}

testLivreur57();