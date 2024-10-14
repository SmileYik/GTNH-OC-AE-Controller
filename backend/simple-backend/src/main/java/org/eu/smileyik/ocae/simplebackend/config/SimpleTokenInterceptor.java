package org.eu.smileyik.ocae.simplebackend.config;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.eu.smileyik.ocae.simplebackend.Config;
import org.springframework.web.servlet.HandlerInterceptor;

import java.util.Objects;

public class SimpleTokenInterceptor implements HandlerInterceptor {
    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) throws Exception {
        if (request.getMethod().equals("OPTIONS")) {
            return HandlerInterceptor.super.preHandle(request, response, handler);
        }

        String ocaetoken = request.getHeader("ocaetoken");
        if (Objects.equals(ocaetoken, Config.instance.getToken())) {
            return HandlerInterceptor.super.preHandle(request, response, handler);
        }
        response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
        return false;
    }
}
