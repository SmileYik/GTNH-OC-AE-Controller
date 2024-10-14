package org.eu.smileyik.ocae.simplebackend.config;

import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import org.eu.smileyik.ocae.simplebackend.Config;
import org.eu.smileyik.ocae.simplebackend.entity.User;
import org.eu.smileyik.ocae.simplebackend.pojo.UserPojo;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.scheduling.annotation.Scheduled;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.StandardOpenOption;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;

@Configuration
@EnableScheduling
public class ReentTableConfig {

    private UserPojo userPojo;

    @Autowired
    public void setUserPojo(UserPojo userPojo) {
        this.userPojo = userPojo;
    }

    @Bean
    public Map<String, Long> reentTable() {
        String reentTableFile = Config.instance.getReentTableFile();
        File file = new File(reentTableFile);
        if (!file.exists()) {
            return new HashMap<>();
        }
        Map<String, Long> o = null;
        try {
            o = new Gson().fromJson(new FileReader(file), new TypeToken<Map<String, Long>>() {}.getType());
        } catch (FileNotFoundException e) {
            return new HashMap<>();
        }
        return o;
    }

    @Scheduled(fixedDelay = 600000)
    public void saveTask() throws IOException {
        Files.writeString(
                new File(Config.instance.getReentTableFile()).toPath(),
                new Gson().toJson(reentTable()),
                StandardCharsets.UTF_8,
                StandardOpenOption.CREATE, StandardOpenOption.WRITE, StandardOpenOption.TRUNCATE_EXISTING
        );
    }

    @Scheduled(fixedDelay = 600000)
    public void cleanUser() throws FileNotFoundException {
        long current = System.currentTimeMillis();
        Set<String> set = new HashSet<>();
        Map<String, Long> table = reentTable();
        table.forEach((key, value) -> {
            if (current - value > Config.instance.getMaxReentFreeTime()) {
                System.out.println("7 天未活跃，移出用户 " + key);
                User user = new User();
                user.setToken(key);
                userPojo.removeUser(user);
                set.add(key);
            }
        });
        set.forEach(table::remove);
    }
}
