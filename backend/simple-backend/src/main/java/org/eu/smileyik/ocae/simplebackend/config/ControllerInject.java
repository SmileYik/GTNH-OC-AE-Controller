package org.eu.smileyik.ocae.simplebackend.config;

import org.eu.smileyik.ocae.simplebackend.controller.BaseController;
import org.springframework.beans.BeansException;
import org.springframework.context.ApplicationContext;
import org.springframework.context.ApplicationContextAware;
import org.springframework.stereotype.Component;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.method.RequestMappingInfo;
import org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerMapping;

import java.lang.reflect.Method;

@Component
public class ControllerInject implements ApplicationContextAware {
    private ApplicationContext applicationContext;

    public void inject(String path, BaseController handler) {
        RequestMappingHandlerMapping requestMappingHandlerMapping = (RequestMappingHandlerMapping) applicationContext.getBean("requestMappingHandlerMapping");
        for (Method method : handler.getClass().getDeclaredMethods()) {
            String[] methodPath = new String[] { path };
            RequestMethod[] methods;

            if (method.isAnnotationPresent(RequestMapping.class)) {
                RequestMapping mapping = method.getAnnotation(RequestMapping.class);
                if (mapping.value().length > 0) {
                    methodPath[0] = methodPath[0] + mapping.value()[0];
                }
                methods = mapping.method();
            } else if (method.isAnnotationPresent(GetMapping.class)) {
                GetMapping mapping = method.getAnnotation(GetMapping.class);
                if (mapping.value().length > 0) {
                    methodPath[0] = methodPath[0] + mapping.value()[0];
                }
                methods = new RequestMethod[] { RequestMethod.GET };
            } else if (method.isAnnotationPresent(PutMapping.class)) {
                PutMapping mapping = method.getAnnotation(PutMapping.class);
                if (mapping.value().length > 0) {
                    methodPath[0] = methodPath[0] + mapping.value()[0];
                }
                methods = new RequestMethod[] { RequestMethod.PUT };
            } else if (method.isAnnotationPresent(PostMapping.class)) {
                PostMapping mapping = method.getAnnotation(PostMapping.class);
                if (mapping.value().length > 0) {
                    methodPath[0] = methodPath[0] + mapping.value()[0];
                }
                methods = new RequestMethod[] { RequestMethod.POST };
            } else if (method.isAnnotationPresent(DeleteMapping.class)) {
                DeleteMapping mapping = method.getAnnotation(DeleteMapping.class);
                if (mapping.value().length > 0) {
                    methodPath[0] = methodPath[0] + mapping.value()[0];
                }
                methods = new RequestMethod[] { RequestMethod.DELETE };
            } else if (method.isAnnotationPresent(PatchMapping.class)) {
                PatchMapping mapping = method.getAnnotation(PatchMapping.class);
                if (mapping.value().length > 0) {
                    methodPath[0] = methodPath[0] + mapping.value()[0];
                }
                methods = new RequestMethod[] { RequestMethod.PATCH };
            } else {
                continue;
            }

            RequestMappingInfo mappingInfo = RequestMappingInfo
                    .paths(methodPath)
                    .methods(methods)
                    .build();
            requestMappingHandlerMapping.registerMapping(mappingInfo, handler, method);
        }
    }

    @Override
    public void setApplicationContext(ApplicationContext applicationContext) throws BeansException {
        this.applicationContext = applicationContext;
    }
}
