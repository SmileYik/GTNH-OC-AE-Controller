package org.eu.smileyik.ocae.simplebackend.controller;

import java.io.File;

public abstract class BaseController {
    private final String fileName;


    public BaseController(String fileName) {
        this.fileName = fileName;
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
}
