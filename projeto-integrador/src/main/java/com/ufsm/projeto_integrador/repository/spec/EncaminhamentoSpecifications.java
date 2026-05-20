package com.ufsm.projeto_integrador.repository.spec;

import com.ufsm.projeto_integrador.domain.entity.Encaminhamento;
import com.ufsm.projeto_integrador.domain.enums.StatusEncaminhamento;
import org.springframework.data.jpa.domain.Specification;

public final class EncaminhamentoSpecifications {

    private EncaminhamentoSpecifications() {
    }

    public static Specification<Encaminhamento> doUsuario(Long userId) {
        return (root, query, criteriaBuilder) ->
                userId == null ? criteriaBuilder.conjunction()
                        : criteriaBuilder.equal(root.get("visita").get("usuario").get("id"), userId);
    }

    public static Specification<Encaminhamento> comStatus(StatusEncaminhamento status) {
        return (root, query, criteriaBuilder) ->
                status == null ? criteriaBuilder.conjunction()
                        : criteriaBuilder.equal(root.get("status"), status);
    }
}
