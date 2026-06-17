package com.ufsm.projeto_integrador.sync.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;

import java.util.List;

public record SyncFinalizarVisitaPayload(
        @NotEmpty @Valid List<SyncDiagnosticoPayload> diagnosticos,
        @NotEmpty @Valid List<SyncEncaminhamentoPayload> encaminhamentos,
        String observacoesGerais
) {
}
