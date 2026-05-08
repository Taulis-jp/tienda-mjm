@echo off
echo ===== Iniciando Eureka Server =====
start "eureka" mvn -f eureka spring-boot:run

timeout /t 5 /nobreak > nul

echo ===== Iniciando Microservicios =====
start "ms-usuarios" mvn -f ms-usuarios spring-boot:run
start "ms-catalogo" mvn -f ms-catalogo spring-boot:run
start "ms-carrito" mvn -f ms-carrito spring-boot:run
start "ms-pedido" mvn -f ms-pedido spring-boot:run
start "ms-stock" mvn -f ms-stock spring-boot:run
start "ms-pagos" mvn -f ms-pagos spring-boot:run
start "ms-envios" mvn -f ms-envios spring-boot:run
start "ms-devolucion" mvn -f ms-devolucion spring-boot:run
start "ms-ofertas" mvn -f ms-ofertas spring-boot:run
start "ms-proveedor" mvn -f ms-proveedor spring-boot:run
rem Agrega aqui los demas microservicios si necesitas

echo Todos los servicios han sido lanzados.
