package com.ufsm.projeto_integrador.repository.spec;

import com.ufsm.projeto_integrador.domain.entity.Propriedade;
import org.springframework.data.jpa.domain.Specification;

import java.util.Locale;

public final class PropriedadeSpecifications {

    private PropriedadeSpecifications() {
    }

    public static Specification<Propriedade> comBusca(String busca) {
        return (root, query, criteriaBuilder) -> {
            if (busca == null || busca.isBlank()) {
                return criteriaBuilder.conjunction();
            }

            String buscaLike = "%" + busca.toLowerCase(Locale.ROOT).trim() + "%";
            return criteriaBuilder.or(
                    criteriaBuilder.like(criteriaBuilder.lower(root.get("nome")), buscaLike),
                    criteriaBuilder.like(criteriaBuilder.lower(root.get("nomeProprietario")), buscaLike)
            );
        };
    }

    public static Specification<Propriedade> comStatus(Boolean ativa) {
        return (root, query, criteriaBuilder) ->
                ativa == null ? criteriaBuilder.conjunction() : criteriaBuilder.equal(root.get("ativa"), ativa);
    }
}
