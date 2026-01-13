-- Client Management System with Blacklisting
-- Run these SQL commands to add client management to your database

-- 1. Create clients table
CREATE TABLE IF NOT EXISTS cdb_clients (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE,
    phone VARCHAR(20),
    company_name VARCHAR(255),
    address TEXT,
    city VARCHAR(100),
    country VARCHAR(100) DEFAULT 'Morocco',
    
    -- Blacklist status
    is_blacklisted BOOLEAN DEFAULT FALSE,
    blacklist_reason TEXT,
    blacklisted_date TIMESTAMP NULL,
    blacklisted_by INT, -- Reference to admin who blacklisted
    
    -- Client statistics
    total_orders INT DEFAULT 0,
    successful_orders INT DEFAULT 0,
    cancelled_orders INT DEFAULT 0,
    total_revenue DECIMAL(10,2) DEFAULT 0.00,
    
    -- Rating system
    rating DECIMAL(2,1) DEFAULT 0.0, -- 0.0 to 5.0
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Foreign key constraints
    FOREIGN KEY (blacklisted_by) REFERENCES cdb_users(id) ON DELETE SET NULL,
    
    -- Indexes for performance
    INDEX idx_email (email),
    INDEX idx_phone (phone),
    INDEX idx_blacklisted (is_blacklisted),
    INDEX idx_created_at (created_at)
);

-- 2. Create client blacklist history table
CREATE TABLE IF NOT EXISTS cdb_client_blacklist_history (
    id INT PRIMARY KEY AUTO_INCREMENT,
    client_id INT NOT NULL,
    action ENUM('BLACKLISTED', 'UNBLACKLISTED') NOT NULL,
    reason TEXT,
    admin_id INT, -- Who performed the action
    action_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    notes TEXT,
    
    FOREIGN KEY (client_id) REFERENCES cdb_clients(id) ON DELETE CASCADE,
    FOREIGN KEY (admin_id) REFERENCES cdb_users(id) ON DELETE SET NULL,
    
    INDEX idx_client_id (client_id),
    INDEX idx_action_date (action_date)
);

-- 3. Add client_id to existing orders table
ALTER TABLE cdb_add_order 
ADD COLUMN client_id INT,
ADD FOREIGN KEY (client_id) REFERENCES cdb_clients(id) ON DELETE SET NULL,
ADD INDEX idx_client_id (client_id);

-- 4. Create client notes table for additional tracking
CREATE TABLE IF NOT EXISTS cdb_client_notes (
    id INT PRIMARY KEY AUTO_INCREMENT,
    client_id INT NOT NULL,
    note TEXT NOT NULL,
    admin_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (client_id) REFERENCES cdb_clients(id) ON DELETE CASCADE,
    FOREIGN KEY (admin_id) REFERENCES cdb_users(id) ON DELETE SET NULL,
    
    INDEX idx_client_id (client_id),
    INDEX idx_created_at (created_at)
);

-- 5. Create view for client analytics
CREATE VIEW client_analytics AS
SELECT 
    c.id,
    c.name,
    c.email,
    c.phone,
    c.company_name,
    c.is_blacklisted,
    c.rating,
    COUNT(o.id) as total_orders,
    COUNT(CASE WHEN o.status_courier = 28 THEN 1 END) as delivered_orders,
    COUNT(CASE WHEN o.status_courier IN (29, 30) THEN 1 END) as cancelled_orders,
    SUM(CASE WHEN o.status_courier = 28 THEN o.price ELSE 0 END) as total_revenue,
    AVG(CASE WHEN o.status_courier = 28 THEN o.price ELSE NULL END) as avg_order_value,
    (COUNT(CASE WHEN o.status_courier = 28 THEN 1 END) / NULLIF(COUNT(o.id), 0)) * 100 as success_rate,
    MAX(o.created_at) as last_order_date,
    c.created_at as client_since
FROM cdb_clients c
LEFT JOIN cdb_add_order o ON c.id = o.client_id
GROUP BY c.id, c.name, c.email, c.phone, c.company_name, c.is_blacklisted, c.rating, c.created_at;
