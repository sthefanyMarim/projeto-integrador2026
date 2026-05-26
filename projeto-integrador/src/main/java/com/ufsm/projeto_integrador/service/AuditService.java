package com.ufsm.projeto_integrador.service;

import com.ufsm.projeto_integrador.domain.dto.common.PageResponse;
import com.ufsm.projeto_integrador.domain.entity.AuditLog;
import com.ufsm.projeto_integrador.repository.AuditLogRepository;
import com.ufsm.projeto_integrador.repository.spec.AuditLogSpecifications;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionTemplate;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.TransactionDefinition;

@Service
@RequiredArgsConstructor
@Slf4j
public class AuditService {

    private final AuditLogRepository repository;
    private final PlatformTransactionManager transactionManager;

    @Transactional(readOnly = true)
    public PageResponse<AuditLog> listar(String tabela, Long userId, Pageable pageable) {
        Specification<AuditLog> specification = AuditLogSpecifications.daTabela(tabela)
                .and(AuditLogSpecifications.doUsuario(userId));

        return PageResponse.from(repository.findAll(specification, pageable));
    }

    public void salvarSeguro(AuditLog auditLog) {
        try {
            TransactionTemplate transactionTemplate = new TransactionTemplate(transactionManager);
            transactionTemplate.setPropagationBehavior(TransactionDefinition.PROPAGATION_REQUIRES_NEW);
            transactionTemplate.executeWithoutResult(status -> repository.saveAndFlush(auditLog));
        } catch (RuntimeException e) {
            log.warn("Falha ao persistir log de auditoria; operacao principal sera mantida", e);
        }
    }
}
