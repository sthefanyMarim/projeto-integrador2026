package com.ufsm.projeto_integrador.domain.dto.auth;

import com.ufsm.projeto_integrador.domain.enums.TipoUsuario;

public record LoginResponse(
        String accessToken,
        String refreshToken,
        TipoUsuario tipo,
        String nome,
        Long userId
) {}
