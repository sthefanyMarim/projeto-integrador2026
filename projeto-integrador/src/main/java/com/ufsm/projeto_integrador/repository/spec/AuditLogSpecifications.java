package com.ufsm.projeto_integrador.repository.spec;

import com.ufsm.projeto_integrador.domain.entity.AuditLog;
import org.springframework.data.jpa.domain.Specification;

public final class AuditLogSpecifications {

    private AuditLogSpecifications() {
    }

    public static Specification<AuditLog> daTabela(String tabela) {
        return (root, query, criteriaBuilder) -> {
            if (tabela == null || tabela.isBlank()) {
                return criteriaBuilder.conjunction();
            }
            return criteriaBuilder.equal(root.get("tabela"), tabela.trim());
        };
    }

    public static Specification<AuditLog> doUsuario(Long userId) {
        return (root, query, criteriaBuilder) ->
                userId == null ? criteriaBuilder.conjunction() : criteriaBuilder.equal(root.get("alteradoPor"), userId);
    }
}
