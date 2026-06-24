package com.ufsm.projeto_integrador.domain.dto.usuario;

import com.ufsm.projeto_integrador.domain.enums.TipoUsuario;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record UsuarioRequest(
        @NotBlank(message = "Nome obrigatório")
        @Size(max = 150)
        String nome,

        @NotBlank(message = "Matrícula obrigatória")
        @Size(max = 20)
        String matricula,

        @NotBlank(message = "Email obrigatório")
        @Pattern(regexp = "^[A-Za-z0-9][A-Za-z0-9._%+-]*@[A-Za-z0-9-]+(\\.[A-Za-z0-9-]+)*\\.[A-Za-z]{2,}$",
                message = "Email inválido")
        String email,

        @Pattern(regexp = "^\\(\\d{2}\\) \\d{4,5}-\\d{4}$",
                message = "Telefone deve estar no formato (DD) 9999-9999 ou (DD) 99999-9999")
        String telefone,

        @Size(min = 6, message = "Senha deve ter no mínimo 6 caracteres")
        String senha,

        @NotNull(message = "Tipo obrigatório")
        TipoUsuario tipo
) {}
