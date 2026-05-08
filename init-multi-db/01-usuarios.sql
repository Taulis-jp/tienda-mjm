-- ============================================================
-- MJM | ECOSISTEMA DIGITAL DE COMERCIO ELECTRONICO
-- Script       : 01-usuarios.sql
-- Microservicio: ms-usuarios
-- Base de datos: usuarios
-- Tablas propias     : usuario, perfil, direccion
-- Proyecciones recibe: ninguna (es fuente maestra)
-- Proyecciones emite : usuario_proy {email, nombre, rol}
--   Topico Kafka     : usuario-actualizado
--   Destino          : ms-pedido, ms-carrito
-- ============================================================

\c usuarios

-- ============================================================
-- BLOQUE 1: ELIMINACION EN ORDEN INVERSO (hijas primero)
-- ============================================================

DROP TABLE IF EXISTS direccion;
DROP TABLE IF EXISTS perfil;
DROP TABLE IF EXISTS usuario;

-- ============================================================
-- BLOQUE 2: CREACION DE TABLAS (maximo 5 campos por tabla)
-- ============================================================

-- Tabla maestra de acceso al sistema
-- Clave alterna Kafka: email (evita sincronizar IDs internos)
-- Campo rol: define permisos y accesos del usuario
CREATE TABLE usuario (
    id         SERIAL       PRIMARY KEY,
    email      VARCHAR(100) NOT NULL UNIQUE,
    contrasena VARCHAR(255) NOT NULL,
    rol        VARCHAR(20)  NOT NULL DEFAULT 'cliente'
                            CHECK (rol IN ('cliente','admin','bodeguero','soporte')),
    activo     BOOLEAN      NOT NULL DEFAULT TRUE
);

-- Datos personales del usuario
-- Vinculado por email para facilitar sincronizacion con Kafka
CREATE TABLE perfil (
    id         SERIAL       PRIMARY KEY,
    email      VARCHAR(100) NOT NULL UNIQUE
                            REFERENCES usuario(email) ON DELETE CASCADE,
    nombre     VARCHAR(100) NOT NULL,
    telefono   VARCHAR(20),
    avatar_url VARCHAR(255)
);

-- Direcciones de despacho registradas por el usuario
-- Un usuario puede tener multiples direcciones
CREATE TABLE direccion (
    id        SERIAL       PRIMARY KEY,
    email     VARCHAR(100) NOT NULL
                           REFERENCES usuario(email) ON DELETE CASCADE,
    alias     VARCHAR(50)  NOT NULL,
    direccion VARCHAR(255) NOT NULL,
    ciudad    VARCHAR(100) NOT NULL
);

-- ============================================================
-- BLOQUE 3: INDICES
-- ============================================================

CREATE INDEX idx_usuario_email   ON usuario(email);
CREATE INDEX idx_usuario_rol     ON usuario(rol);
CREATE INDEX idx_perfil_email    ON perfil(email);
CREATE INDEX idx_direccion_email ON direccion(email);

-- ============================================================
-- BLOQUE 4: DATOS DE PRUEBA
-- ============================================================

-- Caso normal  : clientes activos con datos completos
-- Caso normal  : usuarios internos (admin, bodeguero, soporte)
-- Caso de borde: usuario inactivo (baja logica del sistema)
-- Caso de borde: usuario registrado sin perfil ni direccion
INSERT INTO usuario (email, contrasena, rol, activo) VALUES
    ('ana.gomez@gmail.com',   'hashed_pass_001', 'cliente',   TRUE),
    ('luis.perez@gmail.com',  'hashed_pass_002', 'cliente',   TRUE),
    ('carla.vega@gmail.com',  'hashed_pass_003', 'cliente',   TRUE),
    ('jorge.rios@gmail.com',  'hashed_pass_004', 'admin',     TRUE),
    ('bodega.uno@gmail.com',  'hashed_pass_005', 'bodeguero', TRUE),
    ('soporte.one@gmail.com', 'hashed_pass_006', 'soporte',   TRUE),
    ('inactivo@gmail.com',    'hashed_pass_007', 'cliente',   FALSE),
    ('sinperfil@gmail.com',   'hashed_pass_008', 'cliente',   TRUE);

-- Caso de borde: campos opcionales (telefono, avatar) en NULL
INSERT INTO perfil (email, nombre, telefono, avatar_url) VALUES
    ('ana.gomez@gmail.com',   'Ana Gomez',       '+56912345678', 'https://cdn.modaviva.cl/avatars/ana.jpg'),
    ('luis.perez@gmail.com',  'Luis Perez',      '+56987654321', 'https://cdn.modaviva.cl/avatars/luis.jpg'),
    ('carla.vega@gmail.com',  'Carla Vega',      '+56911112222',  NULL),
    ('jorge.rios@gmail.com',  'Jorge Rios',      '+56933334444', 'https://cdn.modaviva.cl/avatars/jorge.jpg'),
    ('bodega.uno@gmail.com',  'Bodeguero Uno',   '+56955556666',  NULL),
    ('soporte.one@gmail.com', 'Soporte One',      NULL,           NULL),
    ('inactivo@gmail.com',    'Usuario Inactivo', NULL,           NULL);
-- sinperfil@gmail.com: sin perfil, representa usuario recien registrado

-- Caso normal  : multiples direcciones por usuario (ana tiene 2)
-- Caso de borde: sinperfil e inactivo sin direccion registrada
INSERT INTO direccion (email, alias, direccion, ciudad) VALUES
    ('ana.gomez@gmail.com',  'Casa',    'Av. Los Leones 123, Dpto 4B', 'Santiago'),
    ('ana.gomez@gmail.com',  'Trabajo', 'Paseo Bulnes 456, Piso 3',    'Santiago'),
    ('luis.perez@gmail.com', 'Casa',    'Calle Larga 789',             'Valparaiso'),
    ('carla.vega@gmail.com', 'Casa',    'Av. Libertad 321',            'Vina del Mar'),
    ('jorge.rios@gmail.com', 'Oficina', 'Av. Providencia 1000',        'Santiago');

-- ============================================================
-- BLOQUE 5: VERIFICACION FINAL
-- ============================================================

SELECT
    u.email,
    u.rol,
    u.activo,
    p.nombre,
    COUNT(d.id) AS total_direcciones
FROM usuario u
LEFT JOIN perfil    p ON p.email = u.email
LEFT JOIN direccion d ON d.email = u.email
GROUP BY u.email, u.rol, u.activo, p.nombre
ORDER BY u.rol, u.email;

-- ============================================================
-- KAFKA | EVENTO QUE EMITE ESTE MICROSERVICIO
-- Topico  : usuario-actualizado
-- Payload : { "email": "...", "nombre": "...", "rol": "..." }
-- Destino : ms-pedido  → crea/actualiza tabla usuario_proy
--         : ms-carrito → crea/actualiza tabla usuario_proy
-- Nota    : rol permite filtrar usuarios internos vs clientes
-- ============================================================
