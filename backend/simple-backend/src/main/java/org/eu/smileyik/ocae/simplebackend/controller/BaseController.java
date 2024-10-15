package org.eu.smileyik.ocae.simplebackend.controller;

import com.github.houbb.sensitive.word.bs.SensitiveWordBs;
import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import org.eu.smileyik.ocae.simplebackend.config.ControllerInject;
import org.springframework.beans.BeansException;

import java.io.File;

public abstract class BaseController {
    private static final Gson GSON = new Gson();
    private final String fileName;
    private final SensitiveWordBs sensitiveWordBs;

    public BaseController(String fileName) {
        this.fileName = fileName;
        SensitiveWordBs target = null;
        try {
            target = ControllerInject.getApplicationContext().getBean(SensitiveWordBs.class);
        } catch (BeansException e) {

        }
        this.sensitiveWordBs = target;
    }

    public void load() {
        onLoad(new File(fileName));
    }

    protected abstract void onLoad(File file);

    public void store() {
        File file = new File(fileName);
        File parentFile = file.getParentFile();
        if (parentFile != null && !parentFile.exists()) {
            parentFile.mkdirs();
        }
        onStore(file);
    }

    protected abstract void onStore(File file);

    public String getFileName() {
        return fileName;
    }

    protected <T> T filter(T obj, TypeToken<T> typeToken, String path) {
        if (sensitiveWordBs == null) {
            return obj;
        }
        String json = GSON.toJson(obj);
        if (sensitiveWordBs.contains(json)) {
            System.out.println("find sensitive word from " + path + ": " + json);
            return GSON.fromJson(sensitiveWordBs.replace(json), typeToken.getType());
        }
        return obj;
    }
}
