-- ============================================================
-- MJM | ECOSISTEMA DIGITAL DE COMERCIO ELECTRONICO
-- Script       : 07-pedido.sql
-- Microservicio: ms-pedido
-- Base de datos: pedido
-- Tablas propias     : pedido, item_pedido, estado_pedido
-- Proyecciones recibe: usuario_proy {email, nombre, rol}
--                      producto_proy {sku, nombre, precio}
--   Topico Kafka     : usuario-actualizado, producto-actualizado
--   Origen           : ms-usuarios, ms-catalogo
-- Proyecciones emite : pedido_proy {codigo_pedido, total}
--   Topico Kafka     : pedido-confirmado
--   Destino          : ms-pagos, ms-envios, ms-devolucion
-- ============================================================

\c pedido

-- ============================================================
-- BLOQUE 1: ELIMINACION EN ORDEN INVERSO (hijas primero)
-- ============================================================

DROP TABLE IF EXISTS estado_pedido;
DROP TABLE IF EXISTS item_pedido;
DROP TABLE IF EXISTS pedido;
DROP TABLE IF EXISTS usuario_proy;
DROP TABLE IF EXISTS producto_proy;

-- ============================================================
-- BLOQUE 2: CREACION DE TABLAS (maximo 5 campos por tabla)
-- ============================================================

-- PROYECCION 1: recibida desde ms-usuarios via Kafka
-- Solo campos minimos para identificar al comprador del pedido
CREATE TABLE usuario_proy (
    email        VARCHAR(100) NOT NULL UNIQUE,
    nombre       VARCHAR(100) NOT NULL,
    rol          VARCHAR(20)  NOT NULL,
    sincronizado TIMESTAMP    NOT NULL DEFAULT NOW()
);

-- PROYECCION 2: recibida desde ms-catalogo via Kafka
-- Solo sku, nombre y precio para registrar los items del pedido
CREATE TABLE producto_proy (
    sku          VARCHAR(50)   NOT NULL UNIQUE,
    nombre       VARCHAR(100)  NOT NULL,
    precio       DECIMAL(10,2) NOT NULL,
    sincronizado TIMESTAMP     NOT NULL DEFAULT NOW()
);

-- Tabla maestra de pedidos del sistema
-- Clave alterna Kafka: codigo_pedido (UUID legible de negocio)
-- total: monto final pagado incluido descuentos
CREATE TABLE pedido (
    id            SERIAL        PRIMARY KEY,
    codigo_pedido VARCHAR(50)   NOT NULL UNIQUE,
    email         VARCHAR(100)  NOT NULL REFERENCES usuario_proy(email),
    total         DECIMAL(10,2) NOT NULL CHECK (total >= 0),
    fecha         TIMESTAMP     NOT NULL DEFAULT NOW()
);

-- Detalle de productos incluidos en el pedido
-- precio_unitario: snapshot del precio al momento de la compra
CREATE TABLE item_pedido (
    id              SERIAL        PRIMARY KEY,
    codigo_pedido   VARCHAR(50)   NOT NULL REFERENCES pedido(codigo_pedido) ON DELETE CASCADE,
    sku             VARCHAR(50)   NOT NULL REFERENCES producto_proy(sku),
    cantidad        INT           NOT NULL CHECK (cantidad > 0),
    precio_unitario DECIMAL(10,2) NOT NULL CHECK (precio_unitario > 0)
);

-- Historial de estados del pedido (trazabilidad completa)
-- estado: 'pendiente','confirmado','en_despacho','entregado','cancelado'
CREATE TABLE estado_pedido (
    id            SERIAL       PRIMARY KEY,
    codigo_pedido VARCHAR(50)  NOT NULL REFERENCES pedido(codigo_pedido) ON DELETE CASCADE,
    estado        VARCHAR(20)  NOT NULL
                               CHECK (estado IN ('pendiente','confirmado','en_despacho','entregado','cancelado')),
    observacion   VARCHAR(255),
    fecha         TIMESTAMP    NOT NULL DEFAULT NOW()
);

-- ============================================================
-- BLOQUE 3: INDICES
-- ============================================================

CREATE INDEX idx_pedido_codigo        ON pedido(codigo_pedido);
CREATE INDEX idx_pedido_email         ON pedido(email);
CREATE INDEX idx_item_pedido_codigo   ON item_pedido(codigo_pedido);
CREATE INDEX idx_item_pedido_sku      ON item_pedido(sku);
CREATE INDEX idx_estado_pedido_codigo ON estado_pedido(codigo_pedido);
CREATE INDEX idx_estado_pedido_estado ON estado_pedido(estado);
CREATE INDEX idx_usuario_proy_email   ON usuario_proy(email);
CREATE INDEX idx_producto_proy_sku    ON producto_proy(sku);

-- ============================================================
-- BLOQUE 4: DATOS DE PRUEBA
-- ============================================================

-- Proyeccion de usuarios recibida via Kafka desde ms-usuarios
INSERT INTO usuario_proy (email, nombre, rol) VALUES
    ('ana.gomez@gmail.com',  'Ana Gomez',  'cliente'),
    ('luis.perez@gmail.com', 'Luis Perez', 'cliente'),
    ('carla.vega@gmail.com', 'Carla Vega', 'cliente');

-- Proyeccion de productos recibida via Kafka desde ms-catalogo
INSERT INTO producto_proy (sku, nombre, precio) VALUES
    ('CAM-001', 'Camisa Lino Blanca',     29990),
    ('PAN-001', 'Pantalon Cargo Beige',   49990),
    ('VES-001', 'Vestido Floral Verano',  39990),
    ('POL-001', 'Poleron Oversize Negro', 34990);

-- Caso normal  : pedido completado (entregado)
-- Caso normal  : pedido en proceso (confirmado)
-- Caso de borde: pedido cancelado
-- Caso de borde: pedido con descuento aplicado (total menor al precio suma)
INSERT INTO pedido (codigo_pedido, email, total, fecha) VALUES
    ('PED-2024-001', 'ana.gomez@gmail.com',  79980, NOW() - INTERVAL '10 days'),
    ('PED-2024-002', 'luis.perez@gmail.com', 49990, NOW() - INTERVAL '5 days'),
    ('PED-2024-003', 'carla.vega@gmail.com', 35991, NOW() - INTERVAL '2 days'),
    ('PED-2024-004', 'ana.gomez@gmail.com',   0,    NOW() - INTERVAL '1 day');

-- Items de cada pedido con snapshot de precio
INSERT INTO item_pedido (codigo_pedido, sku, cantidad, precio_unitario) VALUES
    ('PED-2024-001', 'CAM-001', 2, 29990),
    ('PED-2024-001', 'PAN-001', 1, 49990),
    ('PED-2024-002', 'PAN-001', 1, 49990),
    ('PED-2024-003', 'VES-001', 1, 35991);
-- PED-2024-004 cancelado: sin items

-- Historial de estados de cada pedido
-- Caso normal  : pedido con ciclo completo de estados
-- Caso de borde: pedido cancelado con observacion
INSERT INTO estado_pedido (codigo_pedido, estado, observacion, fecha) VALUES
    ('PED-2024-001', 'pendiente',    NULL,                               NOW() - INTERVAL '10 days'),
    ('PED-2024-001', 'confirmado',   NULL,                               NOW() - INTERVAL '9 days'),
    ('PED-2024-001', 'en_despacho',  NULL,                               NOW() - INTERVAL '8 days'),
    ('PED-2024-001', 'entregado',    'Entregado en porteria del edificio',NOW() - INTERVAL '7 days'),
    ('PED-2024-002', 'pendiente',    NULL,                               NOW() - INTERVAL '5 days'),
    ('PED-2024-002', 'confirmado',   NULL,                               NOW() - INTERVAL '4 days'),
    ('PED-2024-003', 'pendiente',    NULL,                               NOW() - INTERVAL '2 days'),
    ('PED-2024-004', 'pendiente',    NULL,                               NOW() - INTERVAL '1 day'),
    ('PED-2024-004', 'cancelado',    'Cancelado por cliente via soporte', NOW() - INTERVAL '12 hours');

-- ============================================================
-- BLOQUE 5: VERIFICACION FINAL
-- ============================================================

SELECT
    p.codigo_pedido,
    up.nombre             AS cliente,
    p.total,
    ep.estado             AS estado_actual,
    COUNT(ip.id)          AS total_items
FROM pedido p
JOIN usuario_proy up ON up.email = p.email
JOIN item_pedido  ip ON ip.codigo_pedido = p.codigo_pedido
JOIN estado_pedido ep ON ep.codigo_pedido = p.codigo_pedido
WHERE ep.fecha = (
    SELECT MAX(ep2.fecha)
    FROM estado_pedido ep2
    WHERE ep2.codigo_pedido = p.codigo_pedido
)
GROUP BY p.codigo_pedido, up.nombre, p.total, ep.estado
ORDER BY p.codigo_pedido;

-- ============================================================
-- KAFKA | EVENTO QUE EMITE ESTE MICROSERVICIO
-- Topico  : pedido-confirmado
-- Payload : { "codigo_pedido": "...", "total": ... }
-- Destino : ms-pagos     → crea/actualiza tabla pedido_proy
--         : ms-envios    → crea/actualiza tabla pedido_proy
--         : ms-devolucion→ crea/actualiza tabla pedido_proy
-- REST    : GET /stock/disponibilidad?sku=... (antes de confirmar)
--           POST /pagos/cobrar (para iniciar transaccion de pago)
-- ============================================================
