package org.eu.smileyik.ocae.simplebackend.config;

import org.eu.smileyik.ocae.simplebackend.controller.BaseController;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.scheduling.annotation.Scheduled;

import java.util.List;

@Configuration
@EnableScheduling
public class ControllerSaverConfig {
    private List<BaseController> list;

    @Autowired
    public void setList(List<BaseController> list) {
        this.list = list;
    }

    @Scheduled(fixedDelay = 60000)
    public void saveTask() {
        System.out.println("start save controller data ...");
        for (BaseController controller : list) {
            controller.store();
            System.out.println("stored " + controller.getFileName());
        }
    }
}
