-- Base de datos Paquexpress
CREATE DATABASE IF NOT EXISTS paquexpress;
USE paquexpress;

CREATE TABLE agents (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    is_active BOOLEAN DEFAULT TRUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_login DATETIME
);

CREATE TABLE packages (
    id INT AUTO_INCREMENT PRIMARY KEY,
    unique_id VARCHAR(50) UNIQUE NOT NULL,
    destination_address VARCHAR(255) NOT NULL,
    destination_latitude DECIMAL(10,8),
    destination_longitude DECIMAL(11,8),
    recipient_name VARCHAR(100) NOT NULL,
    status ENUM('pending', 'delivered') DEFAULT 'pending',
    agent_id INT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (agent_id) REFERENCES agents(id)
);

CREATE TABLE deliveries (
    id INT AUTO_INCREMENT PRIMARY KEY,
    package_id INT NOT NULL,
    agent_id INT NOT NULL,
    delivery_photo VARCHAR(255),
    delivery_latitude DECIMAL(10,8),
    delivery_longitude DECIMAL(11,8),
    delivery_timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    notes TEXT,
    status VARCHAR(50) DEFAULT 'completed',
    FOREIGN KEY (package_id) REFERENCES packages(id),
    FOREIGN KEY (agent_id) REFERENCES agents(id)
);

CREATE TABLE sessions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    agent_id INT NOT NULL,
    token VARCHAR(100) UNIQUE NOT NULL,
    expires_at DATETIME NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (agent_id) REFERENCES agents(id)
);

-- Agente de prueba (password: admin123)
INSERT INTO agents (username, email, password_hash, full_name, phone)
VALUES ('admin', 'admin@paquexpress.com', '$2b$12$r.nSiflRBo/F2PDjThiA2uNiDtQH0.MbrVkq.JyGQCOrWC0QlH3eS', 'Administrador', '4421234567');

-- Paquetes de prueba
INSERT INTO packages (unique_id, destination_address, destination_latitude, destination_longitude, recipient_name, agent_id)
VALUES 
('PKG-001', 'Av. Constituyentes 100, Querétaro', 20.5888, -100.3899, 'Juan Pérez', 1),
('PKG-002', 'Blvd. Bernardo Quintana 200, Querétaro', 20.6022, -100.4058, 'María García', 1),
('PKG-003', 'Calle Corregidora 50, Querétaro', 20.5972, -100.3867, 'Carlos López', 1),
('PKG-004', 'Av. 5 de Febrero 300, Querétaro', 20.5912, -100.3921, 'Ana Martínez', 1),
('PKG-005', 'Calle Hidalgo 45, Querétaro', 20.5945, -100.3876, 'Roberto Sánchez', 1),
('PKG-006', 'Blvd. Juárez 150, Querétaro', 20.5867, -100.3934, 'Laura Torres', 1),
('PKG-007', 'Calle Allende 78, Querétaro', 20.5934, -100.3912, 'Pedro Ramírez', 1),
('PKG-008', 'Av. Tecnológico 220, Querétaro', 20.5876, -100.4012, 'Sofía Hernández', 1),
('PKG-009', 'Calle Morelos 33, Querétaro', 20.5998, -100.3845, 'Diego Flores', 1);