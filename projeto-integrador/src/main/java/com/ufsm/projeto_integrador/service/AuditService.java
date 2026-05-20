package com.ufsm.projeto_integrador.service;

import com.ufsm.projeto_integrador.domain.dto.common.PageResponse;
import com.ufsm.projeto_integrador.domain.entity.AuditLog;
import com.ufsm.projeto_integrador.repository.AuditLogRepository;
import com.ufsm.projeto_integrador.repository.spec.AuditLogSpecifications;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class AuditService {

    private final AuditLogRepository repository;

    public PageResponse<AuditLog> listar(String tabela, Long userId, Pageable pageable) {
        Specification<AuditLog> specification = AuditLogSpecifications.daTabela(tabela)
                .and(AuditLogSpecifications.doUsuario(userId));

        return PageResponse.from(repository.findAll(specification, pageable));
    }
}
