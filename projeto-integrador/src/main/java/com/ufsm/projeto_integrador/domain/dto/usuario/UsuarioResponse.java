package com.ufsm.projeto_integrador.domain.dto.usuario;

import com.ufsm.projeto_integrador.domain.entity.Usuario;
import com.ufsm.projeto_integrador.domain.enums.TipoUsuario;

import java.time.LocalDateTime;

public record UsuarioResponse(
        Long id,
        String nome,
        String matricula,
        String email,
        String telefone,
        TipoUsuario tipo,
        String fotoUrl,
        Boolean ativo,
        Long version,
        LocalDateTime criadoEm,
        LocalDateTime atualizadoEm
) {
    public static UsuarioResponse from(Usuario u) {
        return new UsuarioResponse(
                u.getId(), u.getNome(), u.getMatricula(),
                u.getEmail(), u.getTelefone(), u.getTipo(),
                u.getFotoUrl(), u.getAtivo(), u.getVersion(),
                u.getCriadoEm(), u.getAtualizadoEm());
    }
}
