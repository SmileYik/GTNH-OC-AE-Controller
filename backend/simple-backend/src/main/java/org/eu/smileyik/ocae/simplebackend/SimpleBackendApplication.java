package org.eu.smileyik.ocae.simplebackend;

import com.google.gson.Gson;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;

@SpringBootApplication
public class SimpleBackendApplication {

	public static void main(String[] args) throws IOException {
		Gson gson = new Gson();
		if (args.length == 0) {
			System.out.println("Usage: \n  java -jar simple-backend.jar [config file]");
			return;
		} else {
			String configFile = args[0];
			Config.instance = gson.fromJson(new String(Files.readAllBytes(new File(configFile).toPath())), Config.class);
		}

		System.setProperty("server.port", Config.instance.getPort() + "");
		System.setProperty("spring.jackson.serialization.indent_output", "true");
		SpringApplication.run(SimpleBackendApplication.class, args);
	}

}
