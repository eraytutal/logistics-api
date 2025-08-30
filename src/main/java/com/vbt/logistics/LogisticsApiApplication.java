package com.vbt.logistics;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.domain.EntityScan;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;

//@EntityScan(basePackages = {"com.vbt"})
//@EnableJpaRepositories(basePackages = {"com.vbt"})
//@ComponentScan("com.vbt")
@SpringBootApplication
public class LogisticsApiApplication {

	public static void main(String[] args) {
		SpringApplication.run(LogisticsApiApplication.class, args);
	}

}
