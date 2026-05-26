package com.ufsm.projeto_integrador.domain.dto.usuario;

import com.ufsm.projeto_integrador.domain.enums.TipoUsuario;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record UsuarioRequest(
        @NotBlank(message = "Nome obrigatório")
        @Size(max = 150)
        String nome,

        @NotBlank(message = "Matrícula obrigatória")
        @Size(max = 20)
        String matricula,

        @NotBlank(message = "Email obrigatório")
        @Email(message = "Email inválido")
        String email,

        String telefone,

        @Size(min = 6, message = "Senha deve ter no mínimo 6 caracteres")
        String senha,

        @NotNull(message = "Tipo obrigatório")
        TipoUsuario tipo
) {}
