package org.eu.smileyik.ocae.simplebackend.controller;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.reflect.TypeToken;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.web.bind.annotation.*;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.StandardOpenOption;
import java.util.HashMap;
import java.util.Map;

public class SimpleObjectController extends BaseController {
    private Map<String, Object> object = new HashMap<>();
    private long lastModified = System.currentTimeMillis();

    public SimpleObjectController(String fileName) {
        super(fileName);
    }

    @GetMapping
    @ResponseBody
    public Map<String, Object> get(HttpServletRequest req, HttpServletResponse resp) {
        long timestamp = req.getDateHeader("If-Modified-Since");
        if (lastModified < timestamp) {
            resp.setStatus(HttpServletResponse.SC_NOT_MODIFIED);
            return null;
        }

        resp.setDateHeader("Last-Modified", lastModified + 1000);
        return object;
    }

    @DeleteMapping
    @ResponseBody
    public Map<String, Object> delete() {
        Map<String, Object> result = object;
        object = new HashMap<>();
        lastModified = System.currentTimeMillis();
        return result;
    }

    @PutMapping
    @ResponseBody
    public Map<String, Object> put(@RequestBody Map<String, Object> object) {
        this.object = new HashMap<>(object);
        lastModified = System.currentTimeMillis();
        return this.object;
    }

    @PatchMapping
    @ResponseBody
    public Map<String, Object> patch(@RequestBody Map<String, Object> object) {
        this.object.putAll(object);
        lastModified = System.currentTimeMillis();
        return this.object;
    }

    @Override
    protected void onLoad(File file) {
        try {
            object = new Gson().fromJson(new FileReader(file), new TypeToken<HashMap<String, Object>>() {}.getType());
        } catch (FileNotFoundException e) {

        }
    }

    @Override
    protected void onStore(File file) {
        try {
            Files.writeString(
                    file.toPath(),
                    new GsonBuilder().setPrettyPrinting().create().toJson(object),
                    StandardCharsets.UTF_8,
                    StandardOpenOption.CREATE, StandardOpenOption.TRUNCATE_EXISTING, StandardOpenOption.WRITE);
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}
