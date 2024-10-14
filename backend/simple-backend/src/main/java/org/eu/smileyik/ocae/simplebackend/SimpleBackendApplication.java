package org.eu.smileyik.ocae.simplebackend;

import com.google.gson.Gson;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardOpenOption;

@SpringBootApplication
public class SimpleBackendApplication {

	public static void main(String[] args) throws IOException {
		Gson gson = new Gson();
		String configFile = "./config.json";
		if (args.length == 0) {
			Path path = Paths.get(configFile);
			if (!Files.exists(path)) {
				try (InputStream resourceAsStream = SimpleBackendApplication.class.getResourceAsStream("/config-template.json")) {
					if (resourceAsStream != null) {
						Files.write(path, resourceAsStream.readAllBytes(), StandardOpenOption.CREATE_NEW, StandardOpenOption.WRITE);
					}
				}
			}
		} else {
			configFile = args[0];
		}
		Config.instance = gson.fromJson(new String(Files.readAllBytes(new File(configFile).toPath())), Config.class);

		System.setProperty("server.port", Config.instance.getPort() + "");
		System.setProperty("spring.jackson.serialization.indent_output", "true");
		SpringApplication.run(SimpleBackendApplication.class, args);
	}

}
