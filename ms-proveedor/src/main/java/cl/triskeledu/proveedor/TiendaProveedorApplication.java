package cl.triskeledu.proveedor;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;
import org.springframework.cloud.openfeign.EnableFeignClients;

@EnableDiscoveryClient
@EnableFeignClients(basePackages = "cl.triskeledu.proveedor.client")
@SpringBootApplication
public class TiendaProveedorApplication {

	public static void main(String[] args) {
		SpringApplication.run(TiendaProveedorApplication.class, args);
	}

}
