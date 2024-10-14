package org.eu.smileyik.ocae.simplebackend.entity;

import java.util.Objects;

public class User {
    private String token;

    public String getToken() {
        return token;
    }

    public void setToken(String token) {
        this.token = token;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        User user = (User) o;
        return Objects.equals(token, user.token);
    }

    @Override
    public int hashCode() {
        return Objects.hashCode(token);
    }
}
