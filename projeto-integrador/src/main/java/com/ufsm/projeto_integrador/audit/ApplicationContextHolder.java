package com.ufsm.projeto_integrador.audit;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.BeansException;
import org.springframework.context.ApplicationContext;
import org.springframework.context.ApplicationContextAware;
import org.springframework.stereotype.Component;

@Component
@Slf4j
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
        } catch (BeansException e) {
            log.warn("Falha ao obter bean {} no contexto da aplicação", type.getSimpleName(), e);
            return null;
        }
    }
}
