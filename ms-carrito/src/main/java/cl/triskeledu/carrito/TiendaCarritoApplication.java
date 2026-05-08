package cl.triskeledu.carrito;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;
import org.springframework.cloud.openfeign.EnableFeignClients;

@EnableDiscoveryClient
@EnableFeignClients(basePackages = "cl.triskeledu.carrito.client")
@SpringBootApplication
public class TiendaCarritoApplication {

	public static void main(String[] args) {
		SpringApplication.run(TiendaCarritoApplication.class, args);
	}

}
