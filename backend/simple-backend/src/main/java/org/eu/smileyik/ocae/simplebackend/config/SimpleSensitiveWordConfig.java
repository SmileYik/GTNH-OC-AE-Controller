package org.eu.smileyik.ocae.simplebackend.config;

import com.github.houbb.sensitive.word.bs.SensitiveWordBs;
import com.github.houbb.sensitive.word.support.ignore.SensitiveWordCharIgnores;
import com.github.houbb.sensitive.word.support.resultcondition.WordResultConditions;
import com.github.houbb.sensitive.word.support.tag.WordTags;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.eu.smileyik.ocae.simplebackend.Config;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.HandlerInterceptor;

@Configuration
public class SimpleSensitiveWordConfig {

    @Bean
    public SensitiveWordBs sensitiveWordBs() {
        if (!Config.instance.isEnableSensitiveWordCheck()) {
            return null;
        }
        System.out.println("enable sensitive word check");
        return SensitiveWordBs.newInstance()
                .ignoreCase(true)
                .ignoreWidth(true)
                .ignoreNumStyle(true)
                .ignoreChineseStyle(true)
                .ignoreEnglishStyle(true)
                .ignoreRepeat(true)
                .enableNumCheck(false)
                .enableEmailCheck(true)
                .enableUrlCheck(true)
                .enableIpv4Check(true)
                .enableWordCheck(true)
                .wordTag(WordTags.none())
                .charIgnore(SensitiveWordCharIgnores.defaults())
                .wordResultCondition(WordResultConditions.alwaysTrue())
                .init();
    }

}
