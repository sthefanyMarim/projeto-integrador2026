package com.ufsm.projeto_integrador.repository.spec;

import com.ufsm.projeto_integrador.domain.entity.Usuario;
import com.ufsm.projeto_integrador.domain.enums.TipoUsuario;
import org.springframework.data.jpa.domain.Specification;

import java.util.Locale;

public final class UsuarioSpecifications {

    private UsuarioSpecifications() {
    }

    public static Specification<Usuario> comBusca(String busca) {
        return (root, query, criteriaBuilder) -> {
            if (busca == null || busca.isBlank()) {
                return criteriaBuilder.conjunction();
            }

            String buscaLike = "%" + busca.toLowerCase(Locale.ROOT).trim() + "%";
            return criteriaBuilder.or(
                    criteriaBuilder.like(criteriaBuilder.lower(root.get("nome")), buscaLike),
                    criteriaBuilder.like(criteriaBuilder.lower(root.get("matricula")), buscaLike)
            );
        };
    }

    public static Specification<Usuario> comTipo(TipoUsuario tipo) {
        return (root, query, criteriaBuilder) ->
                tipo == null ? criteriaBuilder.conjunction() : criteriaBuilder.equal(root.get("tipo"), tipo);
    }
}
