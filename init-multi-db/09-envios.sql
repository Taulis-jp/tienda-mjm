-- ============================================================
-- MJM | ECOSISTEMA DIGITAL DE COMERCIO ELECTRONICO
-- Script       : 09-envios.sql
-- Microservicio: ms-envios
-- Base de datos: envios
-- Tablas propias     : envio, seguimiento, direccion_envio
-- Proyecciones recibe: pedido_proy {codigo_pedido, total}
--   Topico Kafka     : pedido-confirmado
--   Origen           : ms-pedido
-- Proyecciones emite : ninguna
-- ============================================================

\c envios

-- ============================================================
-- BLOQUE 1: ELIMINACION EN ORDEN INVERSO (hijas primero)
-- ============================================================

DROP TABLE IF EXISTS seguimiento;
DROP TABLE IF EXISTS direccion_envio;
DROP TABLE IF EXISTS envio;
DROP TABLE IF EXISTS pedido_proy;

-- ============================================================
-- BLOQUE 2: CREACION DE TABLAS (maximo 5 campos por tabla)
-- ============================================================

-- PROYECCION recibida desde ms-pedido via Kafka
-- Solo codigo_pedido y total para gestionar el despacho
-- Clave alterna: codigo_pedido (evita sincronizar IDs internos)
CREATE TABLE pedido_proy (
    codigo_pedido VARCHAR(50)   NOT NULL UNIQUE,
    total         DECIMAL(10,2) NOT NULL,
    sincronizado  TIMESTAMP     NOT NULL DEFAULT NOW()
);

-- Envio asociado a cada pedido confirmado
-- courier: empresa de despacho (Chilexpress, Starken, etc.)
-- estado: 'preparando', 'en_ruta', 'entregado', 'devuelto'
CREATE TABLE envio (
    id              SERIAL       PRIMARY KEY,
    codigo_pedido   VARCHAR(50)  NOT NULL UNIQUE
                                 REFERENCES pedido_proy(codigo_pedido),
    estado          VARCHAR(15)  NOT NULL DEFAULT 'preparando'
                                 CHECK (estado IN ('preparando','en_ruta','entregado','devuelto')),
    courier         VARCHAR(50)  NOT NULL,
    fecha_estimada  DATE         NOT NULL
);

-- Historial de actualizaciones del envio (tracking)
-- Cada fila es un evento de ubicacion del paquete
CREATE TABLE seguimiento (
    id            SERIAL       PRIMARY KEY,
    codigo_pedido VARCHAR(50)  NOT NULL REFERENCES pedido_proy(codigo_pedido),
    estado        VARCHAR(15)  NOT NULL,
    descripcion   VARCHAR(255) NOT NULL,
    fecha         TIMESTAMP    NOT NULL DEFAULT NOW()
);

-- Direccion de destino del envio
-- Se guarda en esta BD para que envios sea autonomo
CREATE TABLE direccion_envio (
    id            SERIAL       PRIMARY KEY,
    codigo_pedido VARCHAR(50)  NOT NULL UNIQUE
                               REFERENCES pedido_proy(codigo_pedido),
    direccion     VARCHAR(255) NOT NULL,
    ciudad        VARCHAR(100) NOT NULL,
    codigo_postal VARCHAR(10)
);

-- ============================================================
-- BLOQUE 3: INDICES
-- ============================================================

CREATE INDEX idx_envio_pedido         ON envio(codigo_pedido);
CREATE INDEX idx_envio_estado         ON envio(estado);
CREATE INDEX idx_seguimiento_pedido   ON seguimiento(codigo_pedido);
CREATE INDEX idx_seguimiento_fecha    ON seguimiento(fecha);
CREATE INDEX idx_direccion_pedido     ON direccion_envio(codigo_pedido);
CREATE INDEX idx_pedido_proy_codigo   ON pedido_proy(codigo_pedido);

-- ============================================================
-- BLOQUE 4: DATOS DE PRUEBA
-- ============================================================

-- Proyeccion de pedidos recibida via Kafka desde ms-pedido
INSERT INTO pedido_proy (codigo_pedido, total) VALUES
    ('PED-2024-001', 79980),
    ('PED-2024-002', 49990),
    ('PED-2024-003', 35991);
-- PED-2024-004 cancelado: no genera envio

-- Caso normal  : envio entregado (ciclo completo)
-- Caso normal  : envio en ruta (proceso activo)
-- Caso de borde: envio en preparacion (aun no despacha)
-- Caso de borde: envio devuelto (nadie en casa)
INSERT INTO envio (codigo_pedido, estado, courier, fecha_estimada) VALUES
    ('PED-2024-001', 'entregado',   'Chilexpress', CURRENT_DATE - INTERVAL '7 days'),
    ('PED-2024-002', 'en_ruta',     'Starken',     CURRENT_DATE + INTERVAL '1 day'),
    ('PED-2024-003', 'preparando',  'Chilexpress', CURRENT_DATE + INTERVAL '3 days');

-- Historial de seguimiento (tracking) de cada envio
-- Caso de borde: envio con multiple intento de entrega
INSERT INTO seguimiento (codigo_pedido, estado, descripcion, fecha) VALUES
    ('PED-2024-001', 'preparando', 'Pedido recibido en bodega',              NOW() - INTERVAL '9 days'),
    ('PED-2024-001', 'en_ruta',    'Paquete en camion de reparto',           NOW() - INTERVAL '8 days'),
    ('PED-2024-001', 'entregado',  'Entregado en porteria',                  NOW() - INTERVAL '7 days'),
    ('PED-2024-002', 'preparando', 'Pedido recibido en bodega',              NOW() - INTERVAL '4 days'),
    ('PED-2024-002', 'en_ruta',    'Paquete en centro de distribucion',      NOW() - INTERVAL '3 days'),
    ('PED-2024-002', 'en_ruta',    'Primer intento fallido, nadie en casa',  NOW() - INTERVAL '1 day'),
    ('PED-2024-003', 'preparando', 'Pedido en preparacion en bodega',        NOW() - INTERVAL '2 days');

-- Direccion de destino de cada envio
-- Caso de borde: sin codigo postal (campo opcional en algunos sectores)
INSERT INTO direccion_envio (codigo_pedido, direccion, ciudad, codigo_postal) VALUES
    ('PED-2024-001', 'Av. Los Leones 123, Dpto 4B', 'Santiago',    '7500000'),
    ('PED-2024-002', 'Calle Larga 789',             'Valparaiso',   NULL),
    ('PED-2024-003', 'Av. Libertad 321',            'Vina del Mar', '2520000');

-- ============================================================
-- BLOQUE 5: VERIFICACION FINAL
-- ============================================================

SELECT
    e.codigo_pedido,
    e.courier,
    e.estado,
    e.fecha_estimada,
    de.ciudad,
    COUNT(s.id) AS eventos_tracking
FROM envio e
JOIN direccion_envio de ON de.codigo_pedido = e.codigo_pedido
LEFT JOIN seguimiento  s  ON s.codigo_pedido = e.codigo_pedido
GROUP BY e.codigo_pedido, e.courier, e.estado, e.fecha_estimada, de.ciudad
ORDER BY e.codigo_pedido;

-- ============================================================
-- KAFKA | INTERACCION DE ESTE MICROSERVICIO
-- Recibe : pedido-confirmado → crea entrada en pedido_proy
--          y genera automaticamente el registro de envio
-- Emite  : envio-actualizado (cuando cambia el estado del envio)
-- Payload: { "codigo_pedido": "...", "estado": "entregado" }
-- ============================================================
