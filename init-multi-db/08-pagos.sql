-- ============================================================
-- MJM | ECOSISTEMA DIGITAL DE COMERCIO ELECTRONICO
-- Script       : 08-pagos.sql
-- Microservicio: ms-pagos
-- Base de datos: pagos
-- Tablas propias     : pago, metodo_pago, transaccion
-- Proyecciones recibe: pedido_proy {codigo_pedido, total}
--   Topico Kafka     : pedido-confirmado
--   Origen           : ms-pedido
-- Proyecciones emite : ninguna
-- ============================================================

\c pagos

-- ============================================================
-- BLOQUE 1: ELIMINACION EN ORDEN INVERSO (hijas primero)
-- ============================================================

DROP TABLE IF EXISTS transaccion;
DROP TABLE IF EXISTS pago;
DROP TABLE IF EXISTS metodo_pago;
DROP TABLE IF EXISTS pedido_proy;

-- ============================================================
-- BLOQUE 2: CREACION DE TABLAS (maximo 5 campos por tabla)
-- ============================================================

-- PROYECCION recibida desde ms-pedido via Kafka
-- Solo codigo_pedido y total para procesar el cobro
-- Clave alterna: codigo_pedido (evita sincronizar IDs internos)
CREATE TABLE pedido_proy (
    codigo_pedido VARCHAR(50)   NOT NULL UNIQUE,
    total         DECIMAL(10,2) NOT NULL,
    sincronizado  TIMESTAMP     NOT NULL DEFAULT NOW()
);

-- Metodos de pago disponibles en la tienda
-- tipo: 'tarjeta', 'transferencia', 'efectivo', 'wallet'
CREATE TABLE metodo_pago (
    id        SERIAL        PRIMARY KEY,
    nombre    VARCHAR(50)   NOT NULL UNIQUE,
    tipo      VARCHAR(20)   NOT NULL
                            CHECK (tipo IN ('tarjeta','transferencia','efectivo','wallet')),
    comision  DECIMAL(5,2)  NOT NULL DEFAULT 0 CHECK (comision >= 0),
    activo    BOOLEAN       NOT NULL DEFAULT TRUE
);

-- Registro del pago asociado a un pedido
-- estado: 'pendiente', 'aprobado', 'rechazado', 'reembolsado'
CREATE TABLE pago (
    id            SERIAL        PRIMARY KEY,
    codigo_pedido VARCHAR(50)   NOT NULL REFERENCES pedido_proy(codigo_pedido),
    monto         DECIMAL(10,2) NOT NULL CHECK (monto > 0),
    estado        VARCHAR(15)   NOT NULL DEFAULT 'pendiente'
                                CHECK (estado IN ('pendiente','aprobado','rechazado','reembolsado')),
    fecha         TIMESTAMP     NOT NULL DEFAULT NOW()
);

-- Transaccion generada por la pasarela de pago
-- codigo_transaccion: ID externo retornado por la pasarela (ej: Webpay)
CREATE TABLE transaccion (
    id                  SERIAL       PRIMARY KEY,
    codigo_pedido       VARCHAR(50)  NOT NULL REFERENCES pedido_proy(codigo_pedido),
    codigo_transaccion  VARCHAR(100) NOT NULL UNIQUE,
    estado              VARCHAR(15)  NOT NULL
                                     CHECK (estado IN ('exitosa','fallida','timeout','reversada')),
    fecha               TIMESTAMP    NOT NULL DEFAULT NOW()
);

-- ============================================================
-- BLOQUE 3: INDICES
-- ============================================================

CREATE INDEX idx_pago_pedido          ON pago(codigo_pedido);
CREATE INDEX idx_pago_estado          ON pago(estado);
CREATE INDEX idx_transaccion_pedido   ON transaccion(codigo_pedido);
CREATE INDEX idx_transaccion_codigo   ON transaccion(codigo_transaccion);
CREATE INDEX idx_pedido_proy_codigo   ON pedido_proy(codigo_pedido);

-- ============================================================
-- BLOQUE 4: DATOS DE PRUEBA
-- ============================================================

-- Proyeccion de pedidos recibida via Kafka desde ms-pedido
INSERT INTO pedido_proy (codigo_pedido, total) VALUES
    ('PED-2024-001', 79980),
    ('PED-2024-002', 49990),
    ('PED-2024-003', 35991),
    ('PED-2024-004',     0);

-- Metodos de pago disponibles con distintas comisiones
-- Caso de borde: metodo inactivo (no disponible para nuevos pagos)
INSERT INTO metodo_pago (nombre, tipo, comision, activo) VALUES
    ('Webpay Plus',     'tarjeta',       1.50, TRUE),
    ('Transferencia',   'transferencia', 0.00, TRUE),
    ('MercadoPago',     'wallet',        2.99, TRUE),
    ('Efectivo Tienda', 'efectivo',      0.00, FALSE);

-- Caso normal  : pago aprobado (flujo exitoso)
-- Caso normal  : pago pendiente (en proceso)
-- Caso de borde: pago rechazado (fondos insuficientes)
-- Caso de borde: pago reembolsado (pedido cancelado)
INSERT INTO pago (codigo_pedido, monto, estado, fecha) VALUES
    ('PED-2024-001', 79980, 'aprobado',    NOW() - INTERVAL '9 days'),
    ('PED-2024-002', 49990, 'aprobado',    NOW() - INTERVAL '4 days'),
    ('PED-2024-003', 35991, 'pendiente',   NOW() - INTERVAL '2 days'),
    ('PED-2024-004',     0, 'rechazado',   NOW() - INTERVAL '1 day');

-- Transacciones de pasarela de pago externa
-- Caso de borde: transaccion fallida (timeout de conexion)
INSERT INTO transaccion (codigo_pedido, codigo_transaccion, estado, fecha) VALUES
    ('PED-2024-001', 'WP-TXN-AA112233', 'exitosa',  NOW() - INTERVAL '9 days'),
    ('PED-2024-002', 'WP-TXN-BB445566', 'exitosa',  NOW() - INTERVAL '4 days'),
    ('PED-2024-004', 'WP-TXN-CC778899', 'fallida',  NOW() - INTERVAL '1 day'),
    ('PED-2024-004', 'WP-TXN-CC778900', 'timeout',  NOW() - INTERVAL '23 hours');

-- ============================================================
-- BLOQUE 5: VERIFICACION FINAL
-- ============================================================

SELECT
    pp.codigo_pedido,
    pp.total,
    p.estado        AS estado_pago,
    t.codigo_transaccion,
    t.estado        AS estado_transaccion
FROM pedido_proy pp
LEFT JOIN pago        p ON p.codigo_pedido = pp.codigo_pedido
LEFT JOIN transaccion t ON t.codigo_pedido = pp.codigo_pedido
ORDER BY pp.codigo_pedido, t.fecha;

-- ============================================================
-- KAFKA | INTERACCION DE ESTE MICROSERVICIO
-- Recibe : pedido-confirmado → crea entrada en pedido_proy
-- Emite  : pago-procesado (cuando se aprueba o rechaza el pago)
-- Payload: { "codigo_pedido": "...", "estado": "aprobado" }
-- REST   : POST /pagos/cobrar (llamado sincrono desde ms-pedido)
-- ============================================================
