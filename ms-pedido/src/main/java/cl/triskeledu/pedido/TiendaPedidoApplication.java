package cl.triskeledu.pedido;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;
import org.springframework.cloud.openfeign.EnableFeignClients;

@EnableDiscoveryClient
@EnableFeignClients(basePackages = "cl.triskeledu.pedido.client")
@SpringBootApplication
public class TiendaPedidoApplication {

	public static void main(String[] args) {
		SpringApplication.run(TiendaPedidoApplication.class, args);
	}

}
