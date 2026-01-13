const mysql = require('mysql2/promise');

// Récupération des variables d'environnement
const DB_HOST = process.env.DB_HOST || 'localhost';
const DB_USER = process.env.DB_USER || 'root';
const DB_PASSWORD = process.env.DB_PASSWORD || '';
const DB_NAME = process.env.DB_NAME || 'yanship';

// Création du pool de connexions
const pool = mysql.createPool({
  host: DB_HOST,
  user: DB_USER,
  password: DB_PASSWORD,
  database: DB_NAME,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  timezone: '+00:00'
});

// Test de la connexion
pool.getConnection()
  .then(connection => {
    console.log('Connexion à MySQL établie avec succès');
    connection.release();
  })
  .catch(err => {
    console.error('Erreur de connexion à MySQL:', err);
  });

module.exports = pool;