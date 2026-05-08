-- ============================================================
-- MJM | ECOSISTEMA DIGITAL DE COMERCIO ELECTRONICO
-- Script       : 10-devolucion.sql
-- Microservicio: ms-devolucion
-- Base de datos: devolucion
-- Tablas propias     : devolucion, motivo, reembolso
-- Proyecciones recibe: pedido_proy {codigo_pedido, total}
--   Topico Kafka     : pedido-confirmado
--   Origen           : ms-pedido
-- Proyecciones emite : ninguna
-- Nota REST          : GET /pedidos/{codigo} para validar
--                      si el pedido existe y esta en plazo
-- ============================================================

\c devolucion

-- ============================================================
-- BLOQUE 1: ELIMINACION EN ORDEN INVERSO (hijas primero)
-- ============================================================

DROP TABLE IF EXISTS reembolso;
DROP TABLE IF EXISTS motivo;
DROP TABLE IF EXISTS devolucion;
DROP TABLE IF EXISTS pedido_proy;

-- ============================================================
-- BLOQUE 2: CREACION DE TABLAS (maximo 5 campos por tabla)
-- ============================================================

-- PROYECCION recibida desde ms-pedido via Kafka
-- Solo codigo_pedido y total para gestionar reembolsos
-- Clave alterna: codigo_pedido (evita sincronizar IDs internos)
CREATE TABLE pedido_proy (
    codigo_pedido VARCHAR(50)   NOT NULL UNIQUE,
    total         DECIMAL(10,2) NOT NULL,
    sincronizado  TIMESTAMP     NOT NULL DEFAULT NOW()
);

-- Tabla maestra de solicitudes de devolucion
-- estado: 'solicitada', 'en_revision', 'aprobada', 'rechazada'
-- email del cliente se guarda para autonomia del microservicio
CREATE TABLE devolucion (
    id            SERIAL       PRIMARY KEY,
    codigo_pedido VARCHAR(50)  NOT NULL UNIQUE
                               REFERENCES pedido_proy(codigo_pedido),
    email         VARCHAR(100) NOT NULL,
    estado        VARCHAR(15)  NOT NULL DEFAULT 'solicitada'
                               CHECK (estado IN ('solicitada','en_revision','aprobada','rechazada')),
    fecha         TIMESTAMP    NOT NULL DEFAULT NOW()
);

-- Motivo de la devolucion declarado por el cliente
-- tipo: 'talla_incorrecta', 'defecto', 'no_corresponde', 'arrepentimiento'
CREATE TABLE motivo (
    id            SERIAL       PRIMARY KEY,
    codigo_pedido VARCHAR(50)  NOT NULL UNIQUE
                               REFERENCES devolucion(codigo_pedido) ON DELETE CASCADE,
    tipo          VARCHAR(25)  NOT NULL
                               CHECK (tipo IN ('talla_incorrecta','defecto','no_corresponde','arrepentimiento')),
    descripcion   VARCHAR(255),
    fecha         TIMESTAMP    NOT NULL DEFAULT NOW()
);

-- Reembolso generado una vez aprobada la devolucion
-- estado: 'pendiente', 'procesado', 'fallido'
-- metodo: como se devuelve el dinero al cliente
CREATE TABLE reembolso (
    id            SERIAL        PRIMARY KEY,
    codigo_pedido VARCHAR(50)   NOT NULL UNIQUE
                                REFERENCES devolucion(codigo_pedido) ON DELETE CASCADE,
    monto         DECIMAL(10,2) NOT NULL CHECK (monto > 0),
    metodo        VARCHAR(30)   NOT NULL
                                CHECK (metodo IN ('tarjeta_origen','transferencia','credito_tienda')),
    estado        VARCHAR(15)   NOT NULL DEFAULT 'pendiente'
                                CHECK (estado IN ('pendiente','procesado','fallido'))
);

-- ============================================================
-- BLOQUE 3: INDICES
-- ============================================================

CREATE INDEX idx_devolucion_pedido   ON devolucion(codigo_pedido);
CREATE INDEX idx_devolucion_email    ON devolucion(email);
CREATE INDEX idx_devolucion_estado   ON devolucion(estado);
CREATE INDEX idx_motivo_pedido       ON motivo(codigo_pedido);
CREATE INDEX idx_reembolso_pedido    ON reembolso(codigo_pedido);
CREATE INDEX idx_reembolso_estado    ON reembolso(estado);
CREATE INDEX idx_pedido_proy_codigo  ON pedido_proy(codigo_pedido);

-- ============================================================
-- BLOQUE 4: DATOS DE PRUEBA
-- ============================================================

-- Proyeccion de pedidos recibida via Kafka desde ms-pedido
INSERT INTO pedido_proy (codigo_pedido, total) VALUES
    ('PED-2024-001', 79980),
    ('PED-2024-002', 49990),
    ('PED-2024-003', 35991);

-- Caso normal  : devolucion aprobada (ciclo completo)
-- Caso normal  : devolucion en revision (proceso activo)
-- Caso de borde: devolucion rechazada (fuera de plazo o sin motivo valido)
INSERT INTO devolucion (codigo_pedido, email, estado, fecha) VALUES
    ('PED-2024-001', 'ana.gomez@gmail.com',  'aprobada',    NOW() - INTERVAL '5 days'),
    ('PED-2024-002', 'luis.perez@gmail.com', 'en_revision', NOW() - INTERVAL '2 days'),
    ('PED-2024-003', 'carla.vega@gmail.com', 'rechazada',   NOW() - INTERVAL '1 day');

-- Motivos declarados por cada cliente
-- Caso de borde: descripcion opcional (NULL cuando el tipo es autoexplicativo)
INSERT INTO motivo (codigo_pedido, tipo, descripcion) VALUES
    ('PED-2024-001', 'talla_incorrecta', 'La camisa talla M me queda grande, necesito S'),
    ('PED-2024-002', 'defecto',          'El pantalon tiene una costura rota en la pierna derecha'),
    ('PED-2024-003', 'arrepentimiento',   NULL);

-- Caso normal  : reembolso procesado a tarjeta de origen
-- Caso normal  : reembolso pendiente (esperando aprobacion bancaria)
-- Caso de borde: reembolso rechazado: no aplica para devolucion rechazada
INSERT INTO reembolso (codigo_pedido, monto, metodo, estado) VALUES
    ('PED-2024-001', 79980, 'tarjeta_origen', 'procesado'),
    ('PED-2024-002', 49990, 'transferencia',  'pendiente');
-- PED-2024-003 rechazado: no genera reembolso

-- ============================================================
-- BLOQUE 5: VERIFICACION FINAL
-- ============================================================

SELECT
    d.codigo_pedido,
    d.email,
    d.estado          AS estado_devolucion,
    m.tipo            AS motivo,
    r.monto           AS monto_reembolso,
    r.estado          AS estado_reembolso
FROM devolucion d
LEFT JOIN motivo    m ON m.codigo_pedido = d.codigo_pedido
LEFT JOIN reembolso r ON r.codigo_pedido = d.codigo_pedido
ORDER BY d.fecha;

-- ============================================================
-- KAFKA | INTERACCION DE ESTE MICROSERVICIO
-- Recibe : pedido-confirmado   → crea entrada en pedido_proy
-- Emite  : devolucion-aprobada → notifica a ms-stock para
--          reponer unidades y a ms-pagos para procesar reembolso
-- Payload: { "codigo_pedido": "...", "monto": ..., "metodo": "..." }
-- REST   : GET /pedidos/{codigo_pedido} → ms-pedido
--          Valida que el pedido exista y este dentro del plazo
--          de devolucion (ej: 30 dias desde la entrega)
-- ============================================================
