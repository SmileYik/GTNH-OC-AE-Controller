package org.eu.smileyik.ocae.simplebackend.config;

import org.eu.smileyik.ocae.simplebackend.Config;
import org.eu.smileyik.ocae.simplebackend.controller.BaseController;
import org.eu.smileyik.ocae.simplebackend.controller.SimpleArrayController;
import org.eu.smileyik.ocae.simplebackend.controller.SimpleObjectController;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.concurrent.locks.ReentrantReadWriteLock;

@Configuration
public class ControllerConfig {
    private ControllerInject inject;

    @Autowired
    public void setInject(ControllerInject inject) {
        this.inject = inject;
    }

    @Bean("baseControllerLock")
    public ReentrantReadWriteLock baseControllerLock() {
        return new ReentrantReadWriteLock();
    }

    @Bean
    public List<BaseController> injectAll(@Qualifier("baseControllerLock") ReentrantReadWriteLock lock) {
        lock.writeLock().lock();
        try {
            if (Config.instance.isEnableMultiuser()) {
                return new ArrayList<BaseController>();
            }

            System.out.println("Start inject controller ...");
            List<BaseController> controllers = new ArrayList<>();
            Config.instance.getPaths().forEach((key, value) -> {
                BaseController baseController = null;
                String fileName = key.replaceAll("[\\\\/]", ".");
                while (fileName.startsWith(".")) fileName = fileName.substring(1);
                fileName += ".json";

                if (Objects.equals("Object", value)) {
                    baseController = new SimpleObjectController(fileName);
                } else if (Objects.equals("Array", value)) {
                    baseController = new SimpleArrayController(fileName);
                }
                if (baseController != null) {
                    try {
                        baseController.load();
                        System.out.println("Start inject " + value + " to path " + key);
                        inject.inject(key, baseController);
                        System.out.println("End inject " + value + " to path " + key);
                        controllers.add(baseController);
                    } catch (Exception e) {
                        System.out.println("Failed inject " + value + " to path " + key);
                        e.printStackTrace();
                    }
                }
            });
            return controllers;
        } finally {
            lock.writeLock().unlock();
        }
    }
}
