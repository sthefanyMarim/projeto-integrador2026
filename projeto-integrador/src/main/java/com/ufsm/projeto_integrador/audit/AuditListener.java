package com.ufsm.projeto_integrador.audit;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.ufsm.projeto_integrador.domain.entity.AuditLog;
import com.ufsm.projeto_integrador.domain.enums.AuditAction;
import com.ufsm.projeto_integrador.repository.AuditLogRepository;
import com.ufsm.projeto_integrador.security.SecurityUtils;
import jakarta.persistence.*;
import lombok.extern.slf4j.Slf4j;

import java.time.LocalDateTime;

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
            AuditLogRepository repo = ApplicationContextHolder.getBean(AuditLogRepository.class);
            ObjectMapper mapper    = ApplicationContextHolder.getBean(ObjectMapper.class);
            if (repo == null || mapper == null) return;

            Table tableAnn = entity.getClass().getAnnotation(Table.class);
            if (tableAnn == null) return;

            Long registroId = (Long) entity.getClass().getMethod("getId").invoke(entity);

            String json = null;
            if (action != AuditAction.DELETE) {
                try {
                    json = mapper.writeValueAsString(entity);
                } catch (Exception ignored) {}
            }

            Long userId = null;
            String ip   = null;
            try {
                userId = SecurityUtils.getCurrentUserId();
                ip     = SecurityUtils.getCurrentIp();
            } catch (Exception ignored) {}

            AuditLog log = AuditLog.builder()
                    .tabela(tableAnn.name())
                    .registroId(registroId)
                    .acao(action)
                    .dadosNovos(action != AuditAction.DELETE ? json : null)
                    .dadosAntigos(action == AuditAction.DELETE ? json : null)
                    .alteradoPor(userId)
                    .alteradoEm(LocalDateTime.now())
                    .ipOrigem(ip)
                    .build();

            repo.save(log);
        } catch (Exception e) {
            log.warn("AuditListener: falha ao salvar log — {}", e.getMessage());
        }
    }
}
