package org.eu.smileyik.ocae.simplebackend.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.scheduling.annotation.Scheduled;

import java.util.HashSet;
import java.util.Set;

@Configuration
@EnableScheduling
public class IpCacheConfig {

    @Bean
    public Set<String> ipCache() {
        return new HashSet<String>();
    }

    @Scheduled(cron = "0 0 0 * * *")
    public void clearCache() {
        ipCache().clear();
    }
}
