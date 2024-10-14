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
        onStore(new File(fileName));
    }

    protected abstract void onStore(File file);

    public String getFileName() {
        return fileName;
    }
}
