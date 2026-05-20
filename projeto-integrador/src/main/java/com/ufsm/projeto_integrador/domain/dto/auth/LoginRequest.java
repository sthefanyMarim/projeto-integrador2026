package com.ufsm.projeto_integrador.domain.dto.auth;

import jakarta.validation.constraints.NotBlank;

public record LoginRequest(
        @NotBlank(message = "Matrícula obrigatória") String matricula,
        @NotBlank(message = "Senha obrigatória")    String senha
) {}
