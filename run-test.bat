@echo off
echo ===== Iniciando Eureka Server =====
start "EUREKA" java -jar eureka\target\cl.triskeledu-eureka-1.0-SNAPSHOT.jar --spring.profiles.active=test

timeout /t 5 /nobreak > nul

echo ===== Iniciando Microservicios =====
start "MS-USUARIOS" java -jar ms-usuarios\target\cl.triskeledu-usuarios-0.0.1-SNAPSHOT.jar --spring.profiles.active=test
start "MS-CATALOGO" java -jar ms-catalogo\target\cl.triskeledu-catalogo-0.0.1-SNAPSHOT.jar --spring.profiles.active=test
start "MS-CARRITO" java -jar ms-carrito\target\cl.triskeledu-carrito-0.0.1-SNAPSHOT.jar --spring.profiles.active=test
start "MS-PEDIDO" java -jar ms-pedido\target\cl.triskeledu-pedido-0.0.1-SNAPSHOT.jar --spring.profiles.active=test
start "MS-STOCK" java -jar ms-stock\target\cl.triskeledu-stock-0.0.1-SNAPSHOT.jar --spring.profiles.active=test
start "MS-PAGOS" java -jar ms-pagos\target\cl.triskeledu-pagos-0.0.1-SNAPSHOT.jar --spring.profiles.active=test
start "MS-ENVIOS" java -jar ms-envios\target\cl.triskeledu-envios-0.0.1-SNAPSHOT.jar --spring.profiles.active=test
start "MS-DEVOLUCION" java -jar ms-devolucion\target\cl.triskeledu-devolucion-0.0.1-SNAPSHOT.jar --spring.profiles.active=test
start "MS-OFERTAS" java -jar ms-ofertas\target\cl.triskeledu-ofertas-0.0.1-SNAPSHOT.jar --spring.profiles.active=test
start "MS-PROVEEDOR" java -jar ms-proveedor\target\cl.triskeledu-proveedor-0.0.1-SNAPSHOT.jar --spring.profiles.active=test
rem Agrega aqui los demas microservicios si necesitas

echo Todos los servicios han sido lanzados.
