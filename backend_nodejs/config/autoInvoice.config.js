module.exports = {
  // Configuration de la planification
  schedule: {
    // Génération automatique toutes les 24h à 13h00 (1:00 PM)
    daily: '10 13 * * *',
    // Vérification horaire (optionnel, pour les tests)
    hourly: '0 * * * *',
    // Fuseau horaire
    timezone: 'Africa/Casablanca'
  },

  // Configuration des seuils
  thresholds: {
    // Nombre minimum de livraisons pour déclencher une facturation
    minDeliveriesForInvoice: 1,
    // Nombre de livraisons pour alerter (vérification horaire)
    alertThreshold: 5,
    // Période de rétrospection pour les livraisons (en jours)
    lookbackDays: 7
  },

  // Configuration des statuts
  statuses: {
    // Statut des commandes livrées
    delivered: 28,
    // Statut des commandes facturées
    invoiced: 1
  },

  // Configuration des notifications
  notifications: {
    // Activer les logs détaillés
    enableDetailedLogs: true,
    // Activer les alertes
    enableAlerts: true,
    // Format des logs
    logFormat: 'detailed' // 'simple' ou 'detailed'
  },

  // Configuration des fichiers
  files: {
    // Dossier des factures
    invoiceDirectory: './invoices',
    // Préfixe des factures automatiques
    autoInvoicePrefix: 'AUTO',
    // Format de date pour les noms de fichiers
    dateFormat: 'YYYY-MM-DD'
  },

  // Configuration de la base de données
  database: {
    // Timeout des connexions (en ms)
    connectionTimeout: 30000,
    // Nombre maximum de tentatives
    maxRetries: 3,
    // Délai entre les tentatives (en ms)
    retryDelay: 1000
  }
};
