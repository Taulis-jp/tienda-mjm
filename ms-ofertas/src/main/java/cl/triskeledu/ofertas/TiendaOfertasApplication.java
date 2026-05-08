package cl.triskeledu.ofertas;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;
import org.springframework.cloud.openfeign.EnableFeignClients;

@EnableDiscoveryClient
@EnableFeignClients(basePackages = "cl.triskeledu.ofertas.client")
@SpringBootApplication
public class TiendaOfertasApplication {

	public static void main(String[] args) {
		SpringApplication.run(TiendaOfertasApplication.class, args);
	}

}
