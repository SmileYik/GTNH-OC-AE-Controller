package org.eu.smileyik.ocae.simplebackend.controller;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.eu.smileyik.ocae.simplebackend.Config;
import org.eu.smileyik.ocae.simplebackend.entity.User;
import org.eu.smileyik.ocae.simplebackend.pojo.UserPojo;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Set;

@RestController
@RequestMapping
public class ApplyTokenController {
    private UserPojo userPojo;
    private Set<String> ipCache;

    @GetMapping("/apply")
    public Result<String> applyToken(HttpServletRequest req, HttpServletResponse res) {
        if (!Config.instance.isEnableMultiuser()) {
            res.setStatus(HttpServletResponse.SC_NOT_FOUND);
            return null;
        }
        if (ipCache.contains(req.getRemoteHost())) {
            return new Result<>(403, "你今天已经领取一个Token了！", null);
        }
        User user = userPojo.generateUser();
        if (user == null) {
            return new Result<>(500, "申领时出现问题，请稍后再试！", null);
        }
        ipCache.add(req.getRemoteHost());
        return Result.success(user.getToken());
    }

    public void clearCache() {
        ipCache.clear();
    }

    @Autowired
    public void setUserPojo(UserPojo userPojo) {
        this.userPojo = userPojo;
    }

    @Autowired
    public void setIpCache(@Qualifier("ipCache") Set<String> ipCache) {
        this.ipCache = ipCache;
    }

    public static class Result <T> {
        private final int code;
        private final String message;
        private final T data;

        protected Result(int code, String message, T data) {
            this.code = code;
            this.message = message;
            this.data = data;
        }

        public static <T> Result<T> success(T data) {
            return new Result<>(HttpServletResponse.SC_OK, "success", data);
        }

        public int getCode() {
            return code;
        }

        public String getMessage() {
            return message;
        }

        public T getData() {
            return data;
        }
    }
}
