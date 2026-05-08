-- ============================================================
-- MJM | ECOSISTEMA DIGITAL DE COMERCIO ELECTRONICO
-- Script       : 03-stock.sql
-- Microservicio: ms-stock
-- Base de datos: stock
-- Tablas propias     : inventario, movimiento, bodega
-- Proyecciones recibe: producto_proy {sku, nombre, precio}
--   Topico Kafka     : producto-actualizado
--   Origen           : ms-catalogo
-- Proyecciones emite : ninguna directa
--   Nota: ms-pedido consulta disponibilidad via REST sincrono
-- ============================================================

\c stock

-- ============================================================
-- BLOQUE 1: ELIMINACION EN ORDEN INVERSO (hijas primero)
-- ============================================================

DROP TABLE IF EXISTS movimiento;
DROP TABLE IF EXISTS inventario;
DROP TABLE IF EXISTS bodega;
DROP TABLE IF EXISTS producto_proy;

-- ============================================================
-- BLOQUE 2: CREACION DE TABLAS (maximo 5 campos por tabla)
-- ============================================================

-- PROYECCION recibida desde ms-catalogo via Kafka
-- Solo campos minimos para operar el inventario sin depender del catalogo
-- Clave alterna: sku (evita sincronizar IDs internos)
CREATE TABLE producto_proy (
    sku          VARCHAR(50)   NOT NULL UNIQUE,
    nombre       VARCHAR(100)  NOT NULL,
    precio       DECIMAL(10,2) NOT NULL,
    sincronizado TIMESTAMP     NOT NULL DEFAULT NOW()
);

-- Bodegas fisicas donde se almacena la ropa
-- codigo_bodega es la clave alterna usada para vincular inventario
CREATE TABLE bodega (
    id            SERIAL       PRIMARY KEY,
    codigo_bodega VARCHAR(20)  NOT NULL UNIQUE,
    nombre        VARCHAR(100) NOT NULL,
    ciudad        VARCHAR(100) NOT NULL,
    activa        BOOLEAN      NOT NULL DEFAULT TRUE
);

-- Stock actual por producto y bodega
-- Vinculado por claves alternas: sku y codigo_bodega
CREATE TABLE inventario (
    id            SERIAL      PRIMARY KEY,
    sku           VARCHAR(50) NOT NULL REFERENCES producto_proy(sku),
    codigo_bodega VARCHAR(20) NOT NULL REFERENCES bodega(codigo_bodega),
    unidades      INT         NOT NULL DEFAULT 0 CHECK (unidades >= 0),
    reservadas    INT         NOT NULL DEFAULT 0 CHECK (reservadas >= 0)
);

-- Registro de cada entrada o salida de stock
-- tipo: 'entrada' (compra proveedor), 'salida' (venta), 'ajuste' (correccion)
CREATE TABLE movimiento (
    id            SERIAL      PRIMARY KEY,
    sku           VARCHAR(50) NOT NULL REFERENCES producto_proy(sku),
    codigo_bodega VARCHAR(20) NOT NULL REFERENCES bodega(codigo_bodega),
    tipo          VARCHAR(10) NOT NULL CHECK (tipo IN ('entrada','salida','ajuste')),
    cantidad      INT         NOT NULL CHECK (cantidad <> 0),
    fecha         TIMESTAMP   NOT NULL DEFAULT NOW()
);

-- ============================================================
-- BLOQUE 3: INDICES
-- ============================================================

CREATE INDEX idx_inventario_sku      ON inventario(sku);
CREATE INDEX idx_inventario_bodega   ON inventario(codigo_bodega);
CREATE INDEX idx_movimiento_sku      ON movimiento(sku);
CREATE INDEX idx_movimiento_fecha    ON movimiento(fecha);
CREATE INDEX idx_producto_proy_sku   ON producto_proy(sku);

-- RESTRICCION: un producto solo puede tener un registro por bodega
ALTER TABLE inventario
    ADD CONSTRAINT uq_inventario_sku_bodega UNIQUE (sku, codigo_bodega);

-- ============================================================
-- BLOQUE 4: DATOS DE PRUEBA
-- ============================================================

-- Proyeccion de productos recibida via Kafka desde ms-catalogo
INSERT INTO producto_proy (sku, nombre, precio) VALUES
    ('CAM-001', 'Camisa Lino Blanca',     29990),
    ('PAN-001', 'Pantalon Cargo Beige',   49990),
    ('VES-001', 'Vestido Floral Verano',  39990),
    ('POL-001', 'Poleron Oversize Negro', 34990),
    ('CAL-001', 'Calcetines Pack x3',      9990);

-- Caso normal: bodegas activas en distintas ciudades
-- Caso de borde: bodega inactiva (cerrada temporalmente)
INSERT INTO bodega (codigo_bodega, nombre, ciudad, activa) VALUES
    ('BOD-SCL', 'Bodega Central Santiago', 'Santiago',    TRUE),
    ('BOD-VAL', 'Bodega Valparaiso',       'Valparaiso',  TRUE),
    ('BOD-VIN', 'Bodega Vina del Mar',     'Vina del Mar',FALSE);

-- Caso normal : productos con stock suficiente
-- Caso de borde: producto sin stock (unidades = 0)
-- Caso de borde: producto con unidades reservadas (pedidos en curso)
INSERT INTO inventario (sku, codigo_bodega, unidades, reservadas) VALUES
    ('CAM-001', 'BOD-SCL', 50, 5),
    ('PAN-001', 'BOD-SCL', 30, 2),
    ('VES-001', 'BOD-SCL',  0, 0),
    ('POL-001', 'BOD-SCL', 20, 8),
    ('CAL-001', 'BOD-SCL', 100, 0),
    ('CAM-001', 'BOD-VAL', 15, 0),
    ('PAN-001', 'BOD-VAL',  8, 3);

-- Caso normal  : entrada de mercaderia (cantidad positiva)
-- Caso normal  : salida por venta (cantidad negativa)
-- Caso de borde: ajuste por inventario fisico
INSERT INTO movimiento (sku, codigo_bodega, tipo, cantidad) VALUES
    ('CAM-001', 'BOD-SCL', 'entrada',  100),
    ('CAM-001', 'BOD-SCL', 'salida',   -50),
    ('PAN-001', 'BOD-SCL', 'entrada',   50),
    ('PAN-001', 'BOD-SCL', 'salida',   -20),
    ('VES-001', 'BOD-SCL', 'entrada',   30),
    ('VES-001', 'BOD-SCL', 'salida',   -30),
    ('POL-001', 'BOD-SCL', 'entrada',   25),
    ('CAM-001', 'BOD-SCL', 'ajuste',    -5);

-- ============================================================
-- BLOQUE 5: VERIFICACION FINAL
-- ============================================================

SELECT
    i.sku,
    pp.nombre,
    b.nombre           AS bodega,
    i.unidades,
    i.reservadas,
    (i.unidades - i.reservadas) AS disponibles_reales
FROM inventario i
JOIN producto_proy pp ON pp.sku = i.sku
JOIN bodega        b  ON b.codigo_bodega = i.codigo_bodega
ORDER BY i.sku, b.codigo_bodega;

-- ============================================================
-- KAFKA | INTERACCION DE ESTE MICROSERVICIO
-- Recibe : producto-actualizado → actualiza producto_proy
-- Emite  : stock-actualizado (cuando cambia inventario)
-- Payload: { "sku": "...", "unidades": ..., "reservadas": ... }
-- REST   : GET /stock/disponibilidad?sku=...
--          Consultado por ms-pedido antes de confirmar una orden
-- ============================================================
