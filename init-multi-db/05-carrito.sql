-- ============================================================
-- MJM | ECOSISTEMA DIGITAL DE COMERCIO ELECTRONICO
-- Script       : 05-carrito.sql
-- Microservicio: ms-carrito
-- Base de datos: carrito
-- Tablas propias     : carrito, item_carrito, sesion
-- Proyecciones recibe: producto_proy {sku, nombre, precio}
--                      usuario_proy  {email, nombre, rol}
--   Topico Kafka     : producto-actualizado, usuario-actualizado
--   Origen           : ms-catalogo, ms-usuarios
-- Proyecciones emite : ninguna
-- ============================================================

\c carrito

-- ============================================================
-- BLOQUE 1: ELIMINACION EN ORDEN INVERSO (hijas primero)
-- ============================================================

DROP TABLE IF EXISTS item_carrito;
DROP TABLE IF EXISTS sesion;
DROP TABLE IF EXISTS carrito;
DROP TABLE IF EXISTS producto_proy;
DROP TABLE IF EXISTS usuario_proy;

-- ============================================================
-- BLOQUE 2: CREACION DE TABLAS (maximo 5 campos por tabla)
-- ============================================================

-- PROYECCION 1: recibida desde ms-usuarios via Kafka
-- Solo email, nombre y rol para identificar al comprador
CREATE TABLE usuario_proy (
    email        VARCHAR(100) NOT NULL UNIQUE,
    nombre       VARCHAR(100) NOT NULL,
    rol          VARCHAR(20)  NOT NULL,
    sincronizado TIMESTAMP    NOT NULL DEFAULT NOW()
);

-- PROYECCION 2: recibida desde ms-catalogo via Kafka
-- Solo sku, nombre y precio para mostrar el resumen del carrito
CREATE TABLE producto_proy (
    sku          VARCHAR(50)   NOT NULL UNIQUE,
    nombre       VARCHAR(100)  NOT NULL,
    precio       DECIMAL(10,2) NOT NULL,
    sincronizado TIMESTAMP     NOT NULL DEFAULT NOW()
);

-- Carrito de compras por usuario
-- estado: 'activo', 'abandonado', 'convertido' (cuando se genera pedido)
CREATE TABLE carrito (
    id     SERIAL       PRIMARY KEY,
    email  VARCHAR(100) NOT NULL REFERENCES usuario_proy(email),
    estado VARCHAR(15)  NOT NULL DEFAULT 'activo'
                        CHECK (estado IN ('activo','abandonado','convertido')),
    total  DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (total >= 0)
);

-- Productos agregados al carrito
-- precio_unitario se guarda al momento de agregar (snapshot de precio)
CREATE TABLE item_carrito (
    id              SERIAL        PRIMARY KEY,
    carrito_id      INT           NOT NULL REFERENCES carrito(id) ON DELETE CASCADE,
    sku             VARCHAR(50)   NOT NULL REFERENCES producto_proy(sku),
    cantidad        INT           NOT NULL CHECK (cantidad > 0),
    precio_unitario DECIMAL(10,2) NOT NULL CHECK (precio_unitario > 0)
);

-- Sesion activa del usuario en la tienda
-- Permite mantener el carrito entre sesiones
CREATE TABLE sesion (
    id        SERIAL       PRIMARY KEY,
    email     VARCHAR(100) NOT NULL REFERENCES usuario_proy(email),
    token     VARCHAR(255) NOT NULL UNIQUE,
    expira_at TIMESTAMP    NOT NULL,
    activa    BOOLEAN      NOT NULL DEFAULT TRUE
);

-- ============================================================
-- BLOQUE 3: INDICES
-- ============================================================

CREATE INDEX idx_carrito_email       ON carrito(email);
CREATE INDEX idx_carrito_estado      ON carrito(estado);
CREATE INDEX idx_item_carrito_id     ON item_carrito(carrito_id);
CREATE INDEX idx_item_sku            ON item_carrito(sku);
CREATE INDEX idx_sesion_email        ON sesion(email);
CREATE INDEX idx_sesion_token        ON sesion(token);
CREATE INDEX idx_usuario_proy_email  ON usuario_proy(email);
CREATE INDEX idx_producto_proy_sku   ON producto_proy(sku);

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

-- Caso normal  : carrito activo con productos
-- Caso normal  : carrito convertido (ya se genero un pedido)
-- Caso de borde: carrito abandonado (usuario no completo la compra)
INSERT INTO carrito (email, estado, total) VALUES
    ('ana.gomez@gmail.com',  'activo',     79980),
    ('luis.perez@gmail.com', 'convertido', 49990),
    ('carla.vega@gmail.com', 'abandonado',  0);

-- Caso normal  : multiples items en un carrito
-- Caso de borde: carrito con cantidad mayor a 1 de un producto
INSERT INTO item_carrito (carrito_id, sku, cantidad, precio_unitario) VALUES
    (1, 'CAM-001', 2, 29990),
    (1, 'PAN-001', 1, 49990),
    (2, 'PAN-001', 1, 49990);
-- carrito 3 (abandonado) no tiene items

-- Caso normal  : sesion activa
-- Caso de borde: sesion inactiva (cerrada por el usuario)
INSERT INTO sesion (email, token, expira_at, activa) VALUES
    ('ana.gomez@gmail.com',  'tok_abc123xyz', NOW() + INTERVAL '24 hours', TRUE),
    ('luis.perez@gmail.com', 'tok_def456uvw', NOW() - INTERVAL '1 hour',  FALSE),
    ('carla.vega@gmail.com', 'tok_ghi789rst', NOW() + INTERVAL '12 hours', TRUE);

-- ============================================================
-- BLOQUE 5: VERIFICACION FINAL
-- ============================================================

SELECT
    c.id      AS carrito_id,
    up.email,
    up.nombre,
    c.estado,
    COUNT(ic.id)    AS total_items,
    SUM(ic.cantidad * ic.precio_unitario) AS total_calculado
FROM carrito c
JOIN usuario_proy up ON up.email = c.email
LEFT JOIN item_carrito ic ON ic.carrito_id = c.id
GROUP BY c.id, up.email, up.nombre, c.estado
ORDER BY c.id;

-- ============================================================
-- KAFKA | INTERACCION DE ESTE MICROSERVICIO
-- Recibe : usuario-actualizado  → actualiza usuario_proy
-- Recibe : producto-actualizado → actualiza producto_proy
-- Nota   : si el precio de un producto cambia, el campo
--          precio_unitario en item_carrito NO se actualiza
--          (es un snapshot del precio al momento de agregar)
-- ============================================================
