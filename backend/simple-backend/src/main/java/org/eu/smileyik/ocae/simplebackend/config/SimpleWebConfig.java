package org.eu.smileyik.ocae.simplebackend.config;

import org.eu.smileyik.ocae.simplebackend.Config;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class SimpleWebConfig implements WebMvcConfigurer {
    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        WebMvcConfigurer.super.addInterceptors(registry);
        if (!Config.instance.isEnableMultiuser()) {
            registry.addInterceptor(new SimpleTokenInterceptor());
        } else {
            registry.addInterceptor(new MultiuserTokenInterceptor());
        }
    }

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        WebMvcConfigurer.super.addCorsMappings(registry);
        registry.addMapping("/**")
                .allowedOrigins("*")
                .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH")
                .maxAge(3600);
    }
}
