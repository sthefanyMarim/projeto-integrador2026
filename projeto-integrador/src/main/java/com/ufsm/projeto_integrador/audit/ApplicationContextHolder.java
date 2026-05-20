package com.ufsm.projeto_integrador.audit;

import org.springframework.context.ApplicationContext;
import org.springframework.context.ApplicationContextAware;
import org.springframework.stereotype.Component;

@Component
public class ApplicationContextHolder implements ApplicationContextAware {

    private static ApplicationContext context;

    @Override
    public void setApplicationContext(ApplicationContext ctx) {
        context = ctx;
    }

    public static <T> T getBean(Class<T> type) {
        if (context == null) return null;
        try {
            return context.getBean(type);
        } catch (Exception e) {
            return null;
        }
    }
}
