-- ============================================================
-- MJM  | ECOSISTEMA DIGITAL DE COMERCIO ELECTRONICO
-- Script       : 04-proveedor.sql
-- Microservicio: ms-proveedor
-- Base de datos: proveedor
-- Tablas propias     : proveedor, contacto, orden_compra
-- Proyecciones recibe: ninguna (es fuente maestra)
-- Proyecciones emite : proveedor_proy {rut_proveedor, nombre}
--   Topico Kafka     : proveedor-actualizado
--   Destino          : ms-catalogo
-- ============================================================

\c proveedor

-- ============================================================
-- BLOQUE 1: ELIMINACION EN ORDEN INVERSO (hijas primero)
-- ============================================================

DROP TABLE IF EXISTS orden_compra;
DROP TABLE IF EXISTS contacto;
DROP TABLE IF EXISTS proveedor;

-- ============================================================
-- BLOQUE 2: CREACION DE TABLAS (maximo 5 campos por tabla)
-- ============================================================

-- Tabla maestra de proveedores de ropa
-- Clave alterna Kafka: rut_proveedor (identificador tributario)
CREATE TABLE proveedor (
    id            SERIAL       PRIMARY KEY,
    rut_proveedor VARCHAR(12)  NOT NULL UNIQUE,
    nombre        VARCHAR(100) NOT NULL,
    email         VARCHAR(100) NOT NULL UNIQUE,
    activo        BOOLEAN      NOT NULL DEFAULT TRUE
);

-- Persona de contacto por proveedor
-- Un proveedor puede tener multiples contactos (comercial, logistica)
CREATE TABLE contacto (
    id            SERIAL       PRIMARY KEY,
    rut_proveedor VARCHAR(12)  NOT NULL
                               REFERENCES proveedor(rut_proveedor) ON DELETE CASCADE,
    nombre        VARCHAR(100) NOT NULL,
    telefono      VARCHAR(20)  NOT NULL,
    cargo         VARCHAR(50)
);

-- Ordenes de compra emitidas al proveedor
-- estado: 'pendiente', 'confirmada', 'recibida', 'cancelada'
CREATE TABLE orden_compra (
    id            SERIAL        PRIMARY KEY,
    rut_proveedor VARCHAR(12)   NOT NULL
                                REFERENCES proveedor(rut_proveedor),
    sku_producto  VARCHAR(50)   NOT NULL,
    cantidad      INT           NOT NULL CHECK (cantidad > 0),
    estado        VARCHAR(15)   NOT NULL DEFAULT 'pendiente'
                                CHECK (estado IN ('pendiente','confirmada','recibida','cancelada'))
);

-- ============================================================
-- BLOQUE 3: INDICES
-- ============================================================

CREATE INDEX idx_proveedor_rut        ON proveedor(rut_proveedor);
CREATE INDEX idx_contacto_rut         ON contacto(rut_proveedor);
CREATE INDEX idx_orden_rut            ON orden_compra(rut_proveedor);
CREATE INDEX idx_orden_estado         ON orden_compra(estado);

-- ============================================================
-- BLOQUE 4: DATOS DE PRUEBA
-- ============================================================

-- Caso normal  : proveedores activos con email registrado
-- Caso de borde: proveedor inactivo (contrato vencido)
INSERT INTO proveedor (rut_proveedor, nombre, email, activo) VALUES
    ('76.123.456-7', 'Textiles del Sur',   'ventas@textilesdelsur.cl', TRUE),
    ('77.234.567-8', 'Moda Andina Ltda',   'pedidos@modaandina.cl',    TRUE),
    ('78.345.678-9', 'Importaciones MV',   'contacto@importmv.cl',     TRUE),
    ('79.456.789-0', 'Proveedor Inactivo', 'info@inactivo.cl',         FALSE);

-- Caso normal  : contactos con cargo definido
-- Caso de borde: contacto sin cargo registrado (campo opcional)
INSERT INTO contacto (rut_proveedor, nombre, telefono, cargo) VALUES
    ('76.123.456-7', 'Maria Torres',   '+56922223333', 'Ejecutiva Comercial'),
    ('76.123.456-7', 'Pedro Salinas',  '+56944445555', 'Logistica'),
    ('77.234.567-8', 'Rosa Fuentes',   '+56966667777', 'Gerente de Ventas'),
    ('78.345.678-9', 'Carlos Mendez',  '+56988889999', NULL),
    ('79.456.789-0', 'Sin Contacto',   '+56900000000', NULL);

-- Caso normal  : ordenes en distintos estados del ciclo
-- Caso de borde: orden cancelada
INSERT INTO orden_compra (rut_proveedor, sku_producto, cantidad, estado) VALUES
    ('76.123.456-7', 'CAM-001', 100, 'recibida'),
    ('76.123.456-7', 'PAN-001',  50, 'confirmada'),
    ('77.234.567-8', 'VES-001',  30, 'pendiente'),
    ('78.345.678-9', 'POL-001',  25, 'recibida'),
    ('79.456.789-0', 'CAL-001', 200, 'cancelada');

-- ============================================================
-- BLOQUE 5: VERIFICACION FINAL
-- ============================================================

SELECT
    p.rut_proveedor,
    p.nombre,
    p.activo,
    COUNT(DISTINCT c.id) AS total_contactos,
    COUNT(DISTINCT o.id) AS total_ordenes
FROM proveedor p
LEFT JOIN contacto    c ON c.rut_proveedor = p.rut_proveedor
LEFT JOIN orden_compra o ON o.rut_proveedor = p.rut_proveedor
GROUP BY p.rut_proveedor, p.nombre, p.activo
ORDER BY p.nombre;

-- ============================================================
-- KAFKA | EVENTO QUE EMITE ESTE MICROSERVICIO
-- Topico  : proveedor-actualizado
-- Payload : { "rut_proveedor": "...", "nombre": "..." }
-- Destino : ms-catalogo → crea/actualiza tabla proveedor_proy
-- ============================================================
