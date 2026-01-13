-- Désactiver temporairement les vérifications de clés étrangères
SET FOREIGN_KEY_CHECKS=0;

-- Table pour suivre les paiements des factures
CREATE TABLE IF NOT EXISTS `cdb_invoice_payments` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `invoice_number` varchar(50) NOT NULL,
  `driver_id` int(11) NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `status` enum('pending','paid','cancelled') NOT NULL DEFAULT 'pending',
  `payment_date` datetime DEFAULT NULL,
  `payment_method` varchar(50) DEFAULT NULL,
  `transaction_id` varchar(100) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `invoice_number` (`invoice_number`),
  KEY `driver_id` (`driver_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Ajouter la contrainte de clé étrangère après la création de la table
ALTER TABLE `cdb_invoice_payments`
ADD CONSTRAINT `fk_payment_driver` FOREIGN KEY (`driver_id`) REFERENCES `cdb_users` (`id`) ON DELETE CASCADE;

-- Réactiver les vérifications de clés étrangères
SET FOREIGN_KEY_CHECKS=1;

-- Ajouter une colonne pour stocker le statut de paiement dans la table des commandes
ALTER TABLE `cdb_add_order` 
ADD COLUMN IF NOT EXISTS `payment_status` ENUM('pending', 'paid', 'cancelled') NOT NULL DEFAULT 'pending' AFTER `status_courier`,
ADD COLUMN IF NOT EXISTS `invoice_number` VARCHAR(50) NULL AFTER `payment_status`,
ADD INDEX `idx_payment_status` (`payment_status`);
