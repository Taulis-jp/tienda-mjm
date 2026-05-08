-- ============================================================
-- MJM | ECOSISTEMA DIGITAL DE COMERCIO ELECTRONICO
-- Script       : 02-catalogo.sql
-- Microservicio: ms-catalogo
-- Base de datos: catalogo
-- Tablas propias     : producto, talla, color
-- Proyecciones recibe: proveedor_proy {rut_proveedor, nombre}
--   Topico Kafka     : proveedor-actualizado
--   Origen           : ms-proveedor
-- Proyecciones emite : producto_proy {sku, nombre, precio}
--   Topico Kafka     : producto-actualizado
--   Destino          : ms-stock, ms-carrito, ms-ofertas, ms-pedido
-- ============================================================

\c catalogo

-- ============================================================
-- BLOQUE 1: ELIMINACION EN ORDEN INVERSO (hijas primero)
-- ============================================================

DROP TABLE IF EXISTS color;
DROP TABLE IF EXISTS talla;
DROP TABLE IF EXISTS producto;
DROP TABLE IF EXISTS proveedor_proy;

-- ============================================================
-- BLOQUE 2: CREACION DE TABLAS (maximo 5 campos por tabla)
-- ============================================================

-- PROYECCION recibida desde ms-proveedor via Kafka
-- Solo campos minimos para asociar productos a su proveedor
-- Clave alterna: rut_proveedor (no se usa ID interno)
CREATE TABLE proveedor_proy (
    rut_proveedor VARCHAR(12)  NOT NULL UNIQUE,
    nombre        VARCHAR(100) NOT NULL,
    sincronizado  TIMESTAMP    NOT NULL DEFAULT NOW()
);

-- Tabla maestra de productos de la tienda
-- Clave alterna Kafka: sku (codigo unico del producto)
-- Se vincula al proveedor por rut_proveedor (clave alterna)
CREATE TABLE producto (
    id            SERIAL        PRIMARY KEY,
    sku           VARCHAR(50)   NOT NULL UNIQUE,
    nombre        VARCHAR(100)  NOT NULL,
    precio        DECIMAL(10,2) NOT NULL CHECK (precio > 0),
    rut_proveedor VARCHAR(12)   REFERENCES proveedor_proy(rut_proveedor)
);

-- Tallas disponibles por producto
-- Vinculada por SKU (clave alterna del producto)
CREATE TABLE talla (
    id           SERIAL      PRIMARY KEY,
    sku          VARCHAR(50) NOT NULL REFERENCES producto(sku) ON DELETE CASCADE,
    nombre_talla VARCHAR(10) NOT NULL,
    disponible   BOOLEAN     NOT NULL DEFAULT TRUE
);

-- Colores disponibles por producto
-- hex_code es opcional (algunos colores son estampados/patrones)
CREATE TABLE color (
    id           SERIAL      PRIMARY KEY,
    sku          VARCHAR(50) NOT NULL REFERENCES producto(sku) ON DELETE CASCADE,
    nombre_color VARCHAR(50) NOT NULL,
    hex_code     VARCHAR(7)
);

-- ============================================================
-- BLOQUE 3: INDICES
-- ============================================================

CREATE INDEX idx_producto_sku       ON producto(sku);
CREATE INDEX idx_producto_proveedor ON producto(rut_proveedor);
CREATE INDEX idx_talla_sku          ON talla(sku);
CREATE INDEX idx_color_sku          ON color(sku);
CREATE INDEX idx_proveedor_proy_rut ON proveedor_proy(rut_proveedor);

-- ============================================================
-- BLOQUE 4: DATOS DE PRUEBA
-- ============================================================

-- Proyeccion de proveedores recibida via Kafka desde ms-proveedor
INSERT INTO proveedor_proy (rut_proveedor, nombre) VALUES
    ('76.123.456-7', 'Textiles del Sur'),
    ('77.234.567-8', 'Moda Andina Ltda'),
    ('78.345.678-9', 'Importaciones MV');

-- Caso normal  : productos con proveedor asociado
-- Caso de borde: producto sin proveedor (linea propia, rut = NULL)
INSERT INTO producto (sku, nombre, precio, rut_proveedor) VALUES
    ('CAM-001', 'Camisa Lino Blanca',     29990, '76.123.456-7'),
    ('PAN-001', 'Pantalon Cargo Beige',   49990, '76.123.456-7'),
    ('VES-001', 'Vestido Floral Verano',  39990, '77.234.567-8'),
    ('POL-001', 'Poleron Oversize Negro', 34990, '78.345.678-9'),
    ('CAL-001', 'Calcetines Pack x3',      9990,  NULL);

-- Caso de borde: talla agotada (disponible = FALSE)
INSERT INTO talla (sku, nombre_talla, disponible) VALUES
    ('CAM-001', 'S',  TRUE),
    ('CAM-001', 'M',  TRUE),
    ('CAM-001', 'L',  FALSE),
    ('PAN-001', '30', TRUE),
    ('PAN-001', '32', TRUE),
    ('VES-001', 'XS', TRUE),
    ('VES-001', 'M',  TRUE),
    ('POL-001', 'M',  TRUE),
    ('POL-001', 'XL', TRUE),
    ('CAL-001', 'U',  TRUE);

-- Caso de borde: color sin hex_code (estampado o patron)
INSERT INTO color (sku, nombre_color, hex_code) VALUES
    ('CAM-001', 'Blanco',    '#FFFFFF'),
    ('CAM-001', 'Celeste',   '#ADD8E6'),
    ('PAN-001', 'Beige',     '#F5F5DC'),
    ('PAN-001', 'Kaki',      '#C3B091'),
    ('VES-001', 'Floral',     NULL),
    ('POL-001', 'Negro',     '#000000'),
    ('POL-001', 'Gris',      '#808080'),
    ('CAL-001', 'Multicolor', NULL);

-- ============================================================
-- BLOQUE 5: VERIFICACION FINAL
-- ============================================================

SELECT
    p.sku,
    p.nombre,
    p.precio,
    pp.nombre            AS proveedor,
    COUNT(DISTINCT t.id) AS total_tallas,
    COUNT(DISTINCT c.id) AS total_colores
FROM producto p
LEFT JOIN proveedor_proy pp ON pp.rut_proveedor = p.rut_proveedor
LEFT JOIN talla           t  ON t.sku = p.sku
LEFT JOIN color           c  ON c.sku = p.sku
GROUP BY p.sku, p.nombre, p.precio, pp.nombre
ORDER BY p.sku;

-- ============================================================
-- KAFKA | EVENTO QUE EMITE ESTE MICROSERVICIO
-- Topico  : producto-actualizado
-- Payload : { "sku": "...", "nombre": "...", "precio": ... }
-- Destino : ms-stock   → crea/actualiza tabla producto_proy
--         : ms-carrito → crea/actualiza tabla producto_proy
--         : ms-ofertas → crea/actualiza tabla producto_proy
--         : ms-pedido  → crea/actualiza tabla producto_proy
-- ============================================================
