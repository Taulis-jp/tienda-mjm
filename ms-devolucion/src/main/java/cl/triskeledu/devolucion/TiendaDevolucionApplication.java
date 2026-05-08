package cl.triskeledu.devolucion;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;
import org.springframework.cloud.openfeign.EnableFeignClients;

@EnableDiscoveryClient
@EnableFeignClients(basePackages = "cl.triskeledu.devolucion.client")
@SpringBootApplication
public class TiendaDevolucionApplication {

	public static void main(String[] args) {
		SpringApplication.run(TiendaDevolucionApplication.class, args);
	}

}
