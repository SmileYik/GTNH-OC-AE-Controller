package org.eu.smileyik.ocae.simplebackend;

import java.util.HashMap;
import java.util.Map;

public class Config {
    public static Config instance;

    private int port;
    private String token;
    private Map<String, String> controller = new HashMap<String, String>();
    private boolean enableMultiuser = false;
    private String userFile = "users.json";
    private String prefixPath = "/users";
    private String reentTableFile = "reent-table.json";
    private long maxReentFreeTime = 604800000;

    public int getPort() {
        return port;
    }

    public Map<String, String> getPaths() {
        return controller;
    }

    public String getToken() {
        return token;
    }

    public void setPaths(Map<String, String> controller) {
        this.controller = controller;
    }

    public void setPort(int port) {
        this.port = port;
    }

    public void setToken(String token) {
        this.token = token;
    }

    public boolean isEnableMultiuser() {
        return enableMultiuser;
    }

    public void setEnableMultiuser(boolean enableMultiuser) {
        this.enableMultiuser = enableMultiuser;
    }

    public String getUserFile() {
        return userFile;
    }

    public void setPrefixPath(String prefixPath) {
        this.prefixPath = prefixPath;
    }

    public void setUserFile(String userFile) {
        this.userFile = userFile;
    }

    public String getPrefixPath() {
        return prefixPath;
    }

    public String getReentTableFile() {
        return reentTableFile;
    }

    public void setReentTableFile(String reentTableFile) {
        this.reentTableFile = reentTableFile;
    }

    public long getMaxReentFreeTime() {
        return maxReentFreeTime;
    }

    public void setMaxReentFreeTime(long maxReentFreeTime) {
        this.maxReentFreeTime = maxReentFreeTime;
    }

    @Override
    public String toString() {
        return "Config{" +
                "port=" + port +
                ", token='" + token + '\'' +
                ", controller=" + controller +
                ", enableMultiuser=" + enableMultiuser +
                ", userFile='" + userFile + '\'' +
                ", prefixPath='" + prefixPath + '\'' +
                '}';
    }
}
