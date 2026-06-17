package com.ufsm.projeto_integrador.sync.dto;

import com.ufsm.projeto_integrador.domain.enums.Criticidade;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.util.UUID;

public record SyncDiagnosticoPayload(
        @NotBlank String categoria,
        @NotNull Criticidade criticidade,
        String observacoes,
        UUID attachmentId,
        String imagemUrl
) {
}
