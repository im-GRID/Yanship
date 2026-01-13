-- Création de la base de données si elle n'existe pas
CREATE DATABASE IF NOT EXISTS yanshipDB;
USE yanshipDB;

-- Table for users (drivers)
CREATE TABLE IF NOT EXISTS cdb_users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    fname VARCHAR(50),
    lname VARCHAR(50),
    email VARCHAR(100),
    phone VARCHAR(20),
    address TEXT,
    city VARCHAR(50),
    enrollment VARCHAR(50),
    vehiclecode VARCHAR(50),
    avatar VARCHAR(255),
    created TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    lastlogin TIMESTAMP,
    userlevel INT DEFAULT 3,
    INDEX idx_userlevel (userlevel)
);

-- Table for orders
CREATE TABLE IF NOT EXISTS cdb_add_order (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    order_no VARCHAR(50) NOT NULL,
    order_encoded VARCHAR(50),
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    driver_id INT,
    person_receives VARCHAR(100),
    address TEXT,
    receiver_name VARCHAR(100),
    city VARCHAR(50),
    phone VARCHAR(20),
    price DECIMAL(10,2),
    price_afterfee DECIMAL(10,2),
    photo_delivered VARCHAR(255),
    status_courier INT DEFAULT 24,
    notes TEXT,
    sender_address_id INT,
    FOREIGN KEY (driver_id) REFERENCES cdb_users(id),
    FOREIGN KEY (sender_address_id) REFERENCES cdb_users_multiple_addresses(id_addresses),
    INDEX idx_driver (driver_id),
    INDEX idx_status (status_courier),
    INDEX idx_sender_address (sender_address_id)
);

-- Table for order tracking
CREATE TABLE IF NOT EXISTS cdb_courier_track (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_track VARCHAR(50),
    comments TEXT,
    t_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status_courier INT,
    user_id INT,
    FOREIGN KEY (user_id) REFERENCES cdb_users(id),
    INDEX idx_order (order_track)
);

-- Table for cities
CREATE TABLE IF NOT EXISTS cdb_cities (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    comm TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    status ENUM('active', 'inactive') DEFAULT 'active',
    INDEX idx_status (status),
    INDEX idx_name (name)
);

-- Insert sample cities data
INSERT IGNORE INTO cdb_cities (id, name, comm, status) VALUES 
(1, 'Casablanca', 'Economic capital of Morocco', 'active'),
(2, 'Rabat', 'Capital city of Morocco', 'active'),
(3, 'Marrakech', 'The Red City, major tourist destination', 'active'),
(4, 'Fez', 'Cultural and spiritual center', 'active'),
(5, 'Tangier', 'Gateway to Africa', 'active'),
(6, 'Agadir', 'Coastal city and resort destination', 'active'),
(7, 'Meknes', 'Imperial city with rich history', 'active'),
(8, 'Oujda', 'Eastern gateway city', 'active'),
(9, 'Kenitra', 'Port city north of Rabat', 'active'),
(10, 'Tetouan', 'Mountain city near Mediterranean', 'active'),
(11, 'Safi', 'Atlantic coastal city', 'active'),
(12, 'El Jadida', 'Portuguese influenced coastal city', 'active'),
(13, 'Beni Mellal', 'Agricultural center', 'active'),
(14, 'Errachidia', 'Gateway to the Sahara', 'active'),
(15, 'Taza', 'Historic city between Fez and Oujda', 'active');

-- Add sender_address_id column to existing orders table if it doesn't exist
ALTER TABLE cdb_add_order 
ADD COLUMN IF NOT EXISTS sender_address_id INT,
ADD INDEX IF NOT EXISTS idx_sender_address (sender_address_id),
ADD CONSTRAINT IF NOT EXISTS fk_sender_address 
  FOREIGN KEY (sender_address_id) REFERENCES cdb_users_multiple_addresses(id_addresses);
