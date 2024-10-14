package org.eu.smileyik.ocae.simplebackend.config;

import org.eu.smileyik.ocae.simplebackend.controller.BaseController;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.scheduling.annotation.Scheduled;

import java.util.List;
import java.util.concurrent.locks.ReentrantReadWriteLock;

@Configuration
@EnableScheduling
public class ControllerSaverConfig {

    private List<BaseController> list;
    private ReentrantReadWriteLock lock;

    @Autowired
    public void setList(List<BaseController> list) {
        this.list = list;
    }

    @Autowired
    public void setLock(@Qualifier("baseControllerLock") ReentrantReadWriteLock lock) {
        this.lock = lock;
    }

    @Scheduled(fixedDelay = 600000)
    public void saveTask() {
        System.out.println("start save controller data ...");
        lock.readLock().lock();
        try {
            for (BaseController controller : list) {
                controller.store();
                System.out.println("stored " + controller.getFileName());
            }
        } finally {
            lock.readLock().unlock();
        }
    }
}
