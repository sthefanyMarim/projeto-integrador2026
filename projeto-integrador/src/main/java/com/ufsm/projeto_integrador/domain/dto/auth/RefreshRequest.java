package com.ufsm.projeto_integrador.domain.dto.auth;

import jakarta.validation.constraints.NotBlank;

public record RefreshRequest(
        @NotBlank(message = "Refresh token obrigatório") String refreshToken
) {}
