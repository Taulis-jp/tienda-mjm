-- ============================================================
-- MJM | ECOSISTEMA DIGITAL DE COMERCIO ELECTRONICO
-- Script       : 06-ofertas.sql
-- Microservicio: ms-ofertas
-- Base de datos: ofertas
-- Tablas propias     : oferta, cupon, regla
-- Proyecciones recibe: producto_proy {sku, nombre, precio}
--   Topico Kafka     : producto-actualizado
--   Origen           : ms-catalogo
-- Proyecciones emite : oferta_proy {codigo_oferta, descuento}
--   Topico Kafka     : oferta-actualizada
--   Destino          : ms-carrito
-- ============================================================

\c ofertas

-- ============================================================
-- BLOQUE 1: ELIMINACION EN ORDEN INVERSO (hijas primero)
-- ============================================================

DROP TABLE IF EXISTS regla;
DROP TABLE IF EXISTS cupon;
DROP TABLE IF EXISTS oferta;
DROP TABLE IF EXISTS producto_proy;

-- ============================================================
-- BLOQUE 2: CREACION DE TABLAS (maximo 5 campos por tabla)
-- ============================================================

-- PROYECCION recibida desde ms-catalogo via Kafka
-- Solo sku, nombre y precio_base para calcular descuentos
CREATE TABLE producto_proy (
    sku          VARCHAR(50)   NOT NULL UNIQUE,
    nombre       VARCHAR(100)  NOT NULL,
    precio       DECIMAL(10,2) NOT NULL,
    sincronizado TIMESTAMP     NOT NULL DEFAULT NOW()
);

-- Tabla maestra de ofertas del sistema
-- Clave alterna Kafka: codigo_oferta
-- tipo_descuento: 'porcentaje' (20%) o 'monto_fijo' ($5000)
CREATE TABLE oferta (
    id             SERIAL        PRIMARY KEY,
    codigo_oferta  VARCHAR(50)   NOT NULL UNIQUE,
    descripcion    VARCHAR(150)  NOT NULL,
    descuento      DECIMAL(10,2) NOT NULL CHECK (descuento > 0),
    activa         BOOLEAN       NOT NULL DEFAULT TRUE
);

-- Cupones asociados a una oferta
-- Un cupon es el codigo que ingresa el cliente en el carrito
CREATE TABLE cupon (
    id             SERIAL      PRIMARY KEY,
    codigo_cupon   VARCHAR(50) NOT NULL UNIQUE,
    codigo_oferta  VARCHAR(50) NOT NULL REFERENCES oferta(codigo_oferta) ON DELETE CASCADE,
    usos_max       INT         NOT NULL DEFAULT 1 CHECK (usos_max > 0),
    usos_actuales  INT         NOT NULL DEFAULT 0 CHECK (usos_actuales >= 0)
);

-- Reglas que definen a que productos aplica la oferta
-- Una oferta puede aplicar a multiples SKUs con distintas condiciones
CREATE TABLE regla (
    id            SERIAL        PRIMARY KEY,
    codigo_oferta VARCHAR(50)   NOT NULL REFERENCES oferta(codigo_oferta) ON DELETE CASCADE,
    sku           VARCHAR(50)   NOT NULL REFERENCES producto_proy(sku),
    precio_minimo DECIMAL(10,2) NOT NULL DEFAULT 0,
    tipo_regla    VARCHAR(20)   NOT NULL DEFAULT 'directo'
                                CHECK (tipo_regla IN ('directo','condicional'))
);

-- ============================================================
-- BLOQUE 3: INDICES
-- ============================================================

CREATE INDEX idx_oferta_codigo       ON oferta(codigo_oferta);
CREATE INDEX idx_oferta_activa       ON oferta(activa);
CREATE INDEX idx_cupon_codigo        ON cupon(codigo_cupon);
CREATE INDEX idx_cupon_oferta        ON cupon(codigo_oferta);
CREATE INDEX idx_regla_oferta        ON regla(codigo_oferta);
CREATE INDEX idx_regla_sku           ON regla(sku);
CREATE INDEX idx_producto_proy_sku   ON producto_proy(sku);

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

-- Caso normal  : oferta activa con descuento porcentual
-- Caso normal  : oferta activa con descuento monto fijo
-- Caso de borde: oferta inactiva (vencida o desactivada)
INSERT INTO oferta (codigo_oferta, descripcion, descuento, activa) VALUES
    ('VERANO25',  'Descuento 25% en ropa de temporada',      25.00, TRUE),
    ('DESC5000',  'Descuento fijo de $5000 en tu compra',  5000.00, TRUE),
    ('BFRIDAY50', 'Black Friday 50% en toda la tienda',       50.00, FALSE);

-- Caso normal  : cupon con multiples usos disponibles
-- Caso de borde: cupon agotado (usos_actuales = usos_max)
-- Caso de borde: cupon de un solo uso
INSERT INTO cupon (codigo_cupon, codigo_oferta, usos_max, usos_actuales) VALUES
    ('VERANO-2024',  'VERANO25',  100,  45),
    ('PROMO5000',    'DESC5000',   50,  50),
    ('BF-VIP-001',   'BFRIDAY50',   1,   0);

-- Caso normal  : regla directa (aplica siempre al producto)
-- Caso de borde: regla condicional con precio minimo requerido
INSERT INTO regla (codigo_oferta, sku, precio_minimo, tipo_regla) VALUES
    ('VERANO25',  'CAM-001', 0,     'directo'),
    ('VERANO25',  'VES-001', 0,     'directo'),
    ('DESC5000',  'PAN-001', 30000, 'condicional'),
    ('DESC5000',  'POL-001', 30000, 'condicional'),
    ('BFRIDAY50', 'CAM-001', 0,     'directo'),
    ('BFRIDAY50', 'PAN-001', 0,     'directo');

-- ============================================================
-- BLOQUE 5: VERIFICACION FINAL
-- ============================================================

SELECT
    o.codigo_oferta,
    o.descripcion,
    o.descuento,
    o.activa,
    COUNT(DISTINCT c.id) AS total_cupones,
    COUNT(DISTINCT r.id) AS productos_aplicables
FROM oferta o
LEFT JOIN cupon c ON c.codigo_oferta = o.codigo_oferta
LEFT JOIN regla r ON r.codigo_oferta = o.codigo_oferta
GROUP BY o.codigo_oferta, o.descripcion, o.descuento, o.activa
ORDER BY o.activa DESC, o.codigo_oferta;

-- ============================================================
-- KAFKA | EVENTO QUE EMITE ESTE MICROSERVICIO
-- Topico  : oferta-actualizada
-- Payload : { "codigo_oferta": "...", "descuento": ... }
-- Destino : ms-carrito → crea/actualiza tabla oferta_proy
-- Recibe  : producto-actualizado → actualiza producto_proy
-- ============================================================
