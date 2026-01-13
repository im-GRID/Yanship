-- Création de la table des commissions par ville
CREATE TABLE IF NOT EXISTS `cdb_city_commissions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `city` varchar(100) NOT NULL,
  `commission_amount` decimal(10,2) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `city` (`city`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insertion de la commission pour Casablanca (500 DH)
INSERT INTO `cdb_city_commissions` (`city`, `commission_amount`) 
VALUES ('Casablanca', 500.00)
ON DUPLICATE KEY UPDATE `commission_amount` = VALUES(`commission_amount`);

@