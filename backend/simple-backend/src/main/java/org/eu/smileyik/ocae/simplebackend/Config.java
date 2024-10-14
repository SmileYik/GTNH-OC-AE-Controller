package org.eu.smileyik.ocae.simplebackend;

import java.util.Map;

public class Config {
    public static Config instance;

    private int port;
    private String token;
    private Map<String, String> controller;

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

    @Override
    public String toString() {
        return "Config{" +
                "port=" + port +
                ", token='" + token + '\'' +
                ", paths=" + controller +
                '}';
    }
}
