-- Asegurar el uso de la base de datos correcta
USE db_sistema;

-- =====================================================================
-- 1. CREACIÓN DE LA TABLA DE VENTAS (Mapeado de Venta.java)
-- =====================================================================
CREATE TABLE IF NOT EXISTS venta (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    nombre_cliente VARCHAR(255) NOT NULL,
    monto_total DOUBLE NOT NULL,
    fecha_venta DATETIME NOT NULL,
    estado_venta VARCHAR(50) NOT NULL
);

-- =====================================================================
-- 2. CREACIÓN DE LA TABLA DE DESPACHOS (Mapeado de Despacho.java)
-- =====================================================================
CREATE TABLE IF NOT EXISTS despacho (
    id_despacho BIGINT AUTO_INCREMENT PRIMARY KEY,
    id_compra BIGINT NOT NULL, -- Hace alusión a tu id_venta/compra
    direccion_compra VARCHAR(255) NOT NULL,
    comuna VARCHAR(100) NOT NULL,
    fecha_despacho DATETIME NULL,
    patente_camion VARCHAR(20) NULL,
    entregado BOOLEAN NOT NULL DEFAULT FALSE,
    intento INT NOT NULL DEFAULT 0
);

-- =====================================================================
-- 3. CARGA DE DATOS DEMO POR DEFECTO (Para visualizar en el Frontend)
-- =====================================================================

-- Insertar Ventas de prueba
INSERT INTO venta (id, nombre_cliente, monto_total, fecha_venta, estado_venta) VALUES
(1, 'Alejandro San Martín', 45500.0, '2026-06-01 10:30:00', 'PAGADO'),
(2, 'Constanza Silva', 128900.0, '2026-06-03 14:15:00', 'PAGADO'),
(3, 'Mauricio Araya', 23500.0, '2026-06-05 18:45:00', 'PENDIENTE'),
(4, 'Gabriela Tapia', 67000.0, '2026-06-08 11:00:00', 'PAGADO');

-- Insertar Despachos de prueba de acuerdo al nuevo esquema
INSERT INTO despacho (id_despacho, id_compra, direccion_compra, comuna, fecha_despacho, patente_camion, entregado, intento) VALUES
(1, 1, 'Av. Concha y Toro 543', 'Puente Alto', '2026-06-02 09:00:00', 'AA-BB-11', TRUE, 1),
(2, 2, 'Pasaje Los Alerces 1120', 'La Florida', '2026-06-04 11:30:00', 'CC-DD-22', FALSE, 2),
(3, 4, 'Calle Nueva York 88', 'Santiago Centro', NULL, NULL, FALSE, 0);
