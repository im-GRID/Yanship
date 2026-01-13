-- Additional tables for your existing cdb_clients table
-- Run these SQL commands to complete the client management system

-- 1. Your existing cdb_clients table is already created, so we'll add the missing tables

-- 2. Create client blacklist history table
CREATE TABLE IF NOT EXISTS cdb_client_blacklist_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    client_id INT NOT NULL,
    action ENUM('BLACKLISTED', 'UNBLACKLISTED') NOT NULL,
    reason TEXT,
    admin_id INT UNSIGNED DEFAULT NULL,
    action_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    notes TEXT,
    
    FOREIGN KEY (client_id) REFERENCES cdb_clients(id) ON DELETE CASCADE,
    INDEX idx_client_id (client_id),
    INDEX idx_action_date (action_date)
);

-- 3. Add client_id to existing orders table (if not already added)
ALTER TABLE cdb_add_order 
ADD COLUMN IF NOT EXISTS client_id INT DEFAULT NULL,
ADD INDEX IF NOT EXISTS idx_client_id (client_id);

-- Add foreign key constraint if it doesn't exist
-- ALTER TABLE cdb_add_order 
-- ADD CONSTRAINT fk_order_client 
-- FOREIGN KEY (client_id) REFERENCES cdb_clients(id) ON DELETE SET NULL;

-- 4. Create client notes table for additional tracking
CREATE TABLE IF NOT EXISTS cdb_client_notes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    client_id INT NOT NULL,
    note TEXT NOT NULL,
    admin_id INT UNSIGNED DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (client_id) REFERENCES cdb_clients(id) ON DELETE CASCADE,
    INDEX idx_client_id (client_id),
    INDEX idx_created_at (created_at)
);

-- 5. Create view for client analytics (updated for your table structure)
CREATE VIEW client_analytics AS
SELECT 
    c.id,
    c.name,
    c.phone,
    c.company_name,
    c.address,
    c.city,
    c.country,
    c.is_blacklisted,
    c.blacklisted_date,
    c.blacklisted_by,
    c.created_at as client_since,
    COUNT(o.id) as total_orders,
    COUNT(CASE WHEN o.status_courier = 28 THEN 1 END) as delivered_orders,
    COUNT(CASE WHEN o.status_courier IN (29, 30) THEN 1 END) as cancelled_orders,
    SUM(CASE WHEN o.status_courier = 28 THEN o.price ELSE 0 END) as total_revenue,
    AVG(CASE WHEN o.status_courier = 28 THEN o.price ELSE NULL END) as avg_order_value,
    (COUNT(CASE WHEN o.status_courier = 28 THEN 1 END) / NULLIF(COUNT(o.id), 0)) * 100 as success_rate,
    MAX(o.created_at) as last_order_date
FROM cdb_clients c
LEFT JOIN cdb_add_order o ON c.id = o.client_id
GROUP BY c.id, c.name, c.phone, c.company_name, c.address, c.city, c.country, 
         c.is_blacklisted, c.blacklisted_date, c.blacklisted_by, c.created_at;
