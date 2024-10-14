package org.eu.smileyik.ocae.simplebackend.config;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.eu.smileyik.ocae.simplebackend.Config;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

import java.util.Map;
import java.util.Objects;

@Component
public class MultiuserTokenInterceptor implements HandlerInterceptor {

    private Map<String, Long> reentTable;

    public Map<String, Long> getReentTable() {
        if (reentTable == null) {
            reentTable = (Map<String, Long>) ControllerInject.getApplicationContext().getBean("reentTable");
        }
        return reentTable;
    }

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) throws Exception {
        if (request.getMethod().equals("OPTIONS")) {
            return true;
        }

        try {
            String path = request.getServletPath();
            if (path.startsWith(Config.instance.getPrefixPath())) {
                String s = path.substring(Config.instance.getPrefixPath().length() + 1);
                int idx = s.indexOf('/');
                String token = s.substring(0, idx);
                String ocaetoken = request.getHeader("ocaetoken");
                if (Objects.equals(token, ocaetoken)) {
                    getReentTable().put(token, System.currentTimeMillis());
                    return HandlerInterceptor.super.preHandle(request, response, handler);
                }
                response.setStatus(HttpServletResponse.SC_NOT_FOUND);
                return false;
            }
        } catch (Exception e) {
            e.printStackTrace();
            response.setStatus(HttpServletResponse.SC_NOT_FOUND);
        }
        return HandlerInterceptor.super.preHandle(request, response, handler);
    }
}
