package cl.triskeledu.stock;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;
import org.springframework.cloud.openfeign.EnableFeignClients;

@EnableDiscoveryClient
@EnableFeignClients(basePackages = "cl.triskeledu.stock.client")
@SpringBootApplication
public class TiendaStockApplication {

	public static void main(String[] args) {
		SpringApplication.run(TiendaStockApplication.class, args);
	}

}
