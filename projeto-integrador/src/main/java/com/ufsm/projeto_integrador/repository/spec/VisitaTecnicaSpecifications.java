package com.ufsm.projeto_integrador.repository.spec;

import com.ufsm.projeto_integrador.domain.entity.VisitaTecnica;
import com.ufsm.projeto_integrador.domain.enums.StatusVisita;
import org.springframework.data.jpa.domain.Specification;

public final class VisitaTecnicaSpecifications {

    private VisitaTecnicaSpecifications() {
    }

    public static Specification<VisitaTecnica> doUsuario(Long userId) {
        return (root, query, criteriaBuilder) ->
                userId == null ? criteriaBuilder.conjunction()
                        : criteriaBuilder.equal(root.get("usuario").get("id"), userId);
    }

    public static Specification<VisitaTecnica> comStatus(StatusVisita status) {
        return (root, query, criteriaBuilder) ->
                status == null ? criteriaBuilder.conjunction()
                        : criteriaBuilder.equal(root.get("statusVisita"), status);
    }

    public static Specification<VisitaTecnica> daPropriedade(Long propriedadeId) {
        return (root, query, criteriaBuilder) ->
                propriedadeId == null ? criteriaBuilder.conjunction()
                        : criteriaBuilder.equal(root.get("propriedade").get("id"), propriedadeId);
    }
}
