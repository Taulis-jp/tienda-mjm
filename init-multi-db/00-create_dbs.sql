-- ============================================================
-- MJM | ECOSISTEMA DIGITAL DE COMERCIO ELECTRONICO
-- Script  : 00-create_dbs.sql
-- Objetivo: Crear las 10 bases de datos independientes,
--           una por cada microservicio de la arquitectura.
-- Nota    : Ejecutar SIEMPRE antes que los demas scripts.
--           \gexec permite que psql ejecute el SELECT
--           resultante como un comando DDL dinamico.
-- Verificar: SELECT datname FROM pg_database ORDER BY datname;
-- ============================================================

-- 01 | ms-usuarios
SELECT 'CREATE DATABASE usuarios'
WHERE NOT EXISTS (
    SELECT FROM pg_database WHERE datname = 'usuarios'
) \gexec

-- 02 | ms-catalogo
SELECT 'CREATE DATABASE catalogo'
WHERE NOT EXISTS (
    SELECT FROM pg_database WHERE datname = 'catalogo'
) \gexec

-- 03 | ms-stock
SELECT 'CREATE DATABASE stock'
WHERE NOT EXISTS (
    SELECT FROM pg_database WHERE datname = 'stock'
) \gexec

-- 04 | ms-proveedor
SELECT 'CREATE DATABASE proveedor'
WHERE NOT EXISTS (
    SELECT FROM pg_database WHERE datname = 'proveedor'
) \gexec

-- 05 | ms-carrito
SELECT 'CREATE DATABASE carrito'
WHERE NOT EXISTS (
    SELECT FROM pg_database WHERE datname = 'carrito'
) \gexec

-- 06 | ms-ofertas
SELECT 'CREATE DATABASE ofertas'
WHERE NOT EXISTS (
    SELECT FROM pg_database WHERE datname = 'ofertas'
) \gexec

-- 07 | ms-pedido
SELECT 'CREATE DATABASE pedido'
WHERE NOT EXISTS (
    SELECT FROM pg_database WHERE datname = 'pedido'
) \gexec

-- 08 | ms-pagos
SELECT 'CREATE DATABASE pagos'
WHERE NOT EXISTS (
    SELECT FROM pg_database WHERE datname = 'pagos'
) \gexec

-- 09 | ms-envios
SELECT 'CREATE DATABASE envios'
WHERE NOT EXISTS (
    SELECT FROM pg_database WHERE datname = 'envios'
) \gexec

-- 10 | ms-devolucion
SELECT 'CREATE DATABASE devolucion'
WHERE NOT EXISTS (
    SELECT FROM pg_database WHERE datname = 'devolucion'
) \gexec

-- ============================================================
-- FIN DEL SCRIPT
-- ============================================================
