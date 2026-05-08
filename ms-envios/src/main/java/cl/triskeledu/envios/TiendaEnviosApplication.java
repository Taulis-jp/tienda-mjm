package cl.triskeledu.envios;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;
import org.springframework.cloud.openfeign.EnableFeignClients;

@EnableDiscoveryClient
@EnableFeignClients(basePackages = "cl.triskeledu.envios.client")
@SpringBootApplication
public class TiendaEnviosApplication {

	public static void main(String[] args) {
		SpringApplication.run(TiendaEnviosApplication.class, args);
	}

}
