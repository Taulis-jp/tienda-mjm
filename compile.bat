@echo off
echo.
echo === COMPILANDO MICROSERVICIOS ===
echo.
call cd C:\tienda-test\ms-usuarios
call mvn clean install -U
call cd C:\tienda-test\ms-catalogo
call mvn clean install -U
call cd C:\tienda-test\ms-carrito
call mvn clean install -U
call cd C:\tienda-test\ms-pedido
call mvn clean install -U
call cd C:\tienda-test\ms-stock
call mvn clean install -U
call cd C:\tienda-test\ms-pagos
call mvn clean install -U
call cd C:\tienda-test\ms-envios
call mvn clean install -U
call cd C:\tienda-test\ms-devolucion
call mvn clean install -U
call cd C:\tienda-test\ms-ofertas
call mvn clean install -U
call cd C:\tienda-test\ms-proveedor
call mvn clean install -U
echo.
echo === COMPILACION COMPLETADA ===
pause
