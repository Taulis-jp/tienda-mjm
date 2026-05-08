package cl.triskeledu.usuarios;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;
import org.springframework.cloud.openfeign.EnableFeignClients;

@EnableDiscoveryClient
@EnableFeignClients(basePackages = "cl.triskeledu.usuarios.client")
@SpringBootApplication
public class TiendaUsuariosApplication {

	public static void main(String[] args) {
		SpringApplication.run(TiendaUsuariosApplication.class, args);
	}

}
