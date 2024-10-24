package org.eu.smileyik.ocae.simplebackend.controller;

import com.github.houbb.sensitive.word.bs.SensitiveWordBs;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.reflect.TypeToken;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.StandardOpenOption;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Objects;

public class SimpleArrayController extends BaseController {
    private static final TypeToken<Map<String, Object>> TYPE_TOKEN = new TypeToken<Map<String, Object>>() {};
    private List<Map<String, Object>> array = new ArrayList<>();
    private long lastModified = System.currentTimeMillis();


    public SimpleArrayController(String fileName) {
        super(fileName);
    }

    @GetMapping
    @ResponseBody
    public List<Map<String, Object>> get(HttpServletRequest req, HttpServletResponse resp) {
        long timestamp = req.getDateHeader("If-Modified-Since");
        if (lastModified <= timestamp) {
            resp.setStatus(HttpServletResponse.SC_NOT_MODIFIED);
            return null;
        }

        resp.setDateHeader("Last-Modified", lastModified + 1000);
        return array;
    }

    @PostMapping
    @ResponseBody
    public List<Map<String, Object>> post(@RequestBody Map<String, Object> request, HttpServletRequest req, HttpServletResponse resp) {
        request = filter(request, TYPE_TOKEN, req.getServletPath());

        array.add(request);
        if (!request.containsKey("id")) {
            request.put("id", array.size());
        }
        lastModified = System.currentTimeMillis();
        return array;
    }

    @GetMapping("/{id}")
    @ResponseBody
    public Map<String, Object> get(@PathVariable("id") String id, HttpServletRequest req, HttpServletResponse response) {
        long timestamp = req.getDateHeader("If-Modified-Since");
        if (lastModified <= timestamp) {
            response.setStatus(HttpServletResponse.SC_NOT_MODIFIED);
            return null;
        }

        Map<String, Object> result = array.stream()
                .filter(it -> it.containsKey("id") && Objects.equals(String.valueOf(it.get("id")), id))
                .findFirst().orElseGet(() -> {
                    try {
                        return array.get(Integer.parseInt(id));
                    } catch (Exception e) {
                        return null;
                    }
                });

        if (result == null) {
            response.setStatus(HttpServletResponse.SC_NOT_FOUND);
            return null;
        } else {
            response.setDateHeader("Last-Modified", lastModified + 1000);
            return result;
        }
    }

    @PutMapping("/{id}")
    @ResponseBody
    public Map<String, Object> put(@PathVariable("id") String id,
                                   @RequestBody Map<String, Object> request,
                                   HttpServletRequest req,
                                   HttpServletResponse response) {
        request = filter(request, TYPE_TOKEN, req.getServletPath());
        try {
            Map<String, Object> result = array.get(Integer.parseInt(id));
            if (result.containsKey("id") && !Objects.equals(String.valueOf(result.get("id")), id)) {
                throw new RuntimeException();
            }
            array.set(Integer.parseInt(id), request);
            lastModified = System.currentTimeMillis();
            return array.get(Integer.parseInt(id));
        } catch (Exception e) {
            for (int i = array.size() - 1; i >= 0; i--) {
                Map<String, Object> map = array.get(i);
                if (map.containsKey("id") && Objects.equals(String.valueOf(map.get("id")), id)) {
                    array.set(i, request);
                    lastModified = System.currentTimeMillis();
                    return array.get(i);
                }
            }
        }

        response.setStatus(HttpServletResponse.SC_NOT_FOUND);
        return null;
    }

    @DeleteMapping("/{id}")
    @ResponseBody
    public Map<String, Object> delete(@PathVariable("id") String id, HttpServletResponse response) {
        try {
            Map<String, Object> result = array.get(Integer.parseInt(id));
            if (result.containsKey("id") && !Objects.equals(String.valueOf(result.get("id")), id)) {
                throw new RuntimeException();
            }
            lastModified = System.currentTimeMillis();
            return array.remove(Integer.parseInt(id));
        } catch (Exception e) {
            for (int i = array.size() - 1; i >= 0; i--) {
                Map<String, Object> map = array.get(i);
                if (map.containsKey("id") && Objects.equals(String.valueOf(map.get("id")), id)) {
                    lastModified = System.currentTimeMillis();
                    return array.remove(i);
                }
            }
        }

        response.setStatus(HttpServletResponse.SC_NOT_FOUND);
        return null;
    }

    @Override
    protected void onLoad(File file) {
        try {
            array = new Gson().fromJson(new FileReader(file), new TypeToken<ArrayList<Map<String, Object>>>() {}.getType());
        } catch (FileNotFoundException e) {

        }
    }

    @Override
    protected void onStore(File file) {
        try {
            Files.writeString(
                    file.toPath(),
                    new GsonBuilder().setPrettyPrinting().create().toJson(array),
                    StandardCharsets.UTF_8,
                    StandardOpenOption.CREATE, StandardOpenOption.TRUNCATE_EXISTING, StandardOpenOption.WRITE);
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}
