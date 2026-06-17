package com.ufsm.projeto_integrador.audit;

import com.ufsm.projeto_integrador.domain.entity.AuditLog;
import com.ufsm.projeto_integrador.domain.enums.AuditAction;
import com.ufsm.projeto_integrador.security.SecurityUtils;
import com.ufsm.projeto_integrador.service.AuditService;
import jakarta.persistence.ManyToMany;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToMany;
import jakarta.persistence.OneToOne;
import jakarta.persistence.PostPersist;
import jakarta.persistence.PostUpdate;
import jakarta.persistence.PreRemove;
import jakarta.persistence.Table;
import lombok.extern.slf4j.Slf4j;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import java.lang.reflect.Field;
import java.lang.reflect.Modifier;
import java.time.LocalDateTime;
import java.time.temporal.Temporal;
import java.util.LinkedHashMap;
import java.util.Map;

@Slf4j
public class AuditListener {

    @PostPersist
    public void onInsert(Object entity) {
        save(entity, AuditAction.INSERT);
    }

    @PostUpdate
    public void onUpdate(Object entity) {
        save(entity, AuditAction.UPDATE);
    }

    @PreRemove
    public void onDelete(Object entity) {
        save(entity, AuditAction.DELETE);
    }

    private void save(Object entity, AuditAction action) {
        try {
            AuditService auditService = ApplicationContextHolder.getBean(AuditService.class);
            if (auditService == null) {
                return;
            }

            Table tableAnnotation = entity.getClass().getAnnotation(Table.class);
            if (tableAnnotation == null) {
                return;
            }

            Long registroId = (Long) entity.getClass().getMethod("getId").invoke(entity);
            Map<String, Object> dados = toAuditMap(entity);

            Long userId = SecurityUtils.getCurrentUserIdOrNull();
            String ip = null;
            if (userId != null) {
                try {
                    ip = SecurityUtils.getCurrentIp();
                } catch (Exception ignored) {}
            }

            AuditLog auditLog = AuditLog.builder()
                    .tabela(tableAnnotation.name())
                    .registroId(registroId)
                    .acao(action)
                    .dadosNovos(action != AuditAction.DELETE ? dados : null)
                    .dadosAntigos(action == AuditAction.DELETE ? dados : null)
                    .alteradoPor(userId)
                    .alteradoEm(LocalDateTime.now())
                    .ipOrigem(ip)
                    .build();

            saveAfterCommit(auditService, auditLog);
        } catch (Exception e) {
            log.warn("AuditListener: falha ao preparar log de auditoria", e);
        }
    }

    private void saveAfterCommit(AuditService auditService, AuditLog auditLog) {
        if (TransactionSynchronizationManager.isSynchronizationActive()) {
            TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
                @Override
                public void afterCommit() {
                    auditService.salvarSeguro(auditLog);
                }
            });
            return;
        }

        auditService.salvarSeguro(auditLog);
    }

    private Map<String, Object> toAuditMap(Object entity) throws IllegalAccessException {
        Map<String, Object> values = new LinkedHashMap<>();
        Class<?> type = entity.getClass();

        while (type != null && type != Object.class) {
            for (Field field : type.getDeclaredFields()) {
                if (Modifier.isStatic(field.getModifiers()) || field.isSynthetic() || shouldSkip(field)) {
                    continue;
                }

                field.setAccessible(true);
                Object value = field.get(entity);
                if (isEntityReference(field)) {
                    values.put(field.getName() + "Id", extractId(value));
                } else if (value == null || isSimpleValue(value)) {
                    values.put(field.getName(), normalizeSimpleValue(value));
                } else {
                    values.put(field.getName(), String.valueOf(value));
                }
            }
            type = type.getSuperclass();
        }

        return values;
    }

    private boolean shouldSkip(Field field) {
        return field.isAnnotationPresent(OneToMany.class) || field.isAnnotationPresent(ManyToMany.class);
    }

    private boolean isEntityReference(Field field) {
        return field.isAnnotationPresent(ManyToOne.class) || field.isAnnotationPresent(OneToOne.class);
    }

    private Object extractId(Object value) {
        if (value == null) {
            return null;
        }

        try {
            return value.getClass().getMethod("getId").invoke(value);
        } catch (Exception e) {
            return null;
        }
    }

    private boolean isSimpleValue(Object value) {
        return value instanceof CharSequence
                || value instanceof Number
                || value instanceof Boolean
                || value instanceof Enum<?>
                || value instanceof Temporal;
    }

    private Object normalizeSimpleValue(Object value) {
        if (value instanceof Enum<?> enumValue) {
            return enumValue.name();
        }
        if (value instanceof Temporal) {
            return value.toString();
        }
        return value;
    }
}
