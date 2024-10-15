package org.eu.smileyik.ocae.simplebackend.pojo;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.reflect.TypeToken;
import org.eu.smileyik.ocae.simplebackend.Config;
import org.eu.smileyik.ocae.simplebackend.config.ControllerInject;
import org.eu.smileyik.ocae.simplebackend.controller.BaseController;
import org.eu.smileyik.ocae.simplebackend.controller.SimpleArrayController;
import org.eu.smileyik.ocae.simplebackend.controller.SimpleObjectController;
import org.eu.smileyik.ocae.simplebackend.entity.User;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.stereotype.Component;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.StandardOpenOption;
import java.util.*;
import java.util.concurrent.locks.ReentrantReadWriteLock;

@Component
public class UserPojo {
    private static final Gson GSON = new GsonBuilder().setPrettyPrinting().create();

    private ReentrantReadWriteLock lock;
    private List<BaseController> controllers;

    private ControllerInject inject;

    @Autowired
    public void setControllers(List<BaseController> controllers) {
        this.controllers = controllers;
        init();
    }

    @Autowired
    public void setLock(@Qualifier("baseControllerLock") ReentrantReadWriteLock lock) {
        this.lock = lock;
        init();
    }

    @Autowired
    public void setInject(ControllerInject inject) {
        this.inject = inject;
        init();
    }

    public String getUserUrl(User user) {
        return Config.instance.getPrefixPath() + "/" + user.getToken();
    }

    private void init() {
        if (lock == null || inject == null || controllers == null) return;
        try {
            getUsers().forEach(this::injectUserPath);
        } catch (FileNotFoundException e) {
            e.printStackTrace();
        }
    }

    public synchronized User generateUser() {
        User user = new User();
        user.setToken(UUID.randomUUID().toString());
        try {
            List<User> users = getUsers();
            long count = users.stream().filter(it -> user.getToken().equals(it.getToken())).count();
            if (count == 0) {
                users.add(user);
                store(users);
                injectUserPath(user);
                Map<String, Long> reentTable = (Map<String, Long>) ControllerInject.getApplicationContext().getBean("reentTable");
                reentTable.put(user.getToken(), System.currentTimeMillis());
                return user;
            } else {
                return null;
            }
        } catch (Exception e) {
            e.printStackTrace();
            return null;
        }
    }

    public synchronized void removeUser(User user) {
        if (user == null || user.getToken() == null) return;
        try {
            List<User> users = getUsers();
            users.remove(user);
            store(users);
            uninjectUserPath(user);
        } catch (IOException e) {
            throw new RuntimeException(e);
        }

    }

    public synchronized void uninjectUserPath(User user) {
        lock.writeLock().lock();
        try {
            String path = user.getToken();
            new File("./" + Config.instance.getPrefixPath() + "/" + path).deleteOnExit();
            Config.instance.getPaths().forEach((key, value) -> {
                String fileName = "./" + Config.instance.getPrefixPath() + "/" + path + "/" + key.replaceAll("[\\\\/]", ".");
                fileName += ".json";

                for (BaseController controller : controllers) {
                    if (Objects.equals(fileName, controller.getFileName())) {
                        controllers.remove(controller);
                        break;
                    }
                }

                String targetPath = Config.instance.getPrefixPath() + "/" + user.getToken() + key;
                if (Objects.equals("Object", value)) {
                    System.out.println("Start uninject " + value + " to path " + targetPath);
                    inject.uninject(targetPath, SimpleObjectController.class);
                } else if (Objects.equals("Array", value)) {
                    System.out.println("Start uninject " + value + " to path " + targetPath);
                    inject.uninject(targetPath, SimpleArrayController.class);
                }
            });
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            lock.writeLock().unlock();
        }
    }

    public synchronized void injectUserPath(User user) {
        lock.writeLock().lock();
        try {
            String path = user.getToken();
            Config.instance.getPaths().forEach((key, value) -> {
                BaseController baseController = null;
                String fileName = "./" + Config.instance.getPrefixPath() + "/" + path + "/" + key.replaceAll("[\\\\/]", ".");
                fileName += ".json";

                if (Objects.equals("Object", value)) {
                    baseController = new SimpleObjectController(fileName);
                } else if (Objects.equals("Array", value)) {
                    baseController = new SimpleArrayController(fileName);
                }

                if (baseController != null) {
                    String targetPath = Config.instance.getPrefixPath() + "/" + user.getToken() + key;
                    try {
                        baseController.load();
                        System.out.println("Start inject " + value + " to path " + targetPath);
                        inject.inject(targetPath, baseController);
                        System.out.println("End inject " + value + " to path " + targetPath);
                        controllers.add(baseController);
                    } catch (Exception e) {
                        System.out.println("Failed inject " + value + " to path " + targetPath);
                        e.printStackTrace();
                    }
                }
            });
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            lock.writeLock().unlock();
        }
    }

    public synchronized void store(List<User> users) throws IOException {
        File file = new File(Config.instance.getUserFile());
        File parentFile = file.getParentFile();
        if (parentFile != null && !parentFile.exists()) {
            parentFile.mkdirs();
        }

        Files.writeString(
                file.toPath(),
                GSON.toJson(users),
                StandardCharsets.UTF_8,
                StandardOpenOption.WRITE, StandardOpenOption.CREATE, StandardOpenOption.TRUNCATE_EXISTING);
    }

    public synchronized List<User> getUsers() throws FileNotFoundException {
        File file = new File(Config.instance.getUserFile());
        if (!file.exists()) {
            return new ArrayList<>();
        }
        return GSON.fromJson(new FileReader(file), new TypeToken<List<User>>() {}.getType());
    }
}
