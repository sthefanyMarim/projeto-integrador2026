package com.ufsm.projeto_integrador.sync.dto;

import com.ufsm.projeto_integrador.domain.enums.Prioridade;
import com.ufsm.projeto_integrador.domain.enums.Verificacao;
import jakarta.validation.constraints.NotBlank;

import java.time.LocalDate;

public record SyncEncaminhamentoPayload(
        @NotBlank String acaoRealizada,
        String responsavel,
        LocalDate prazo,
        Verificacao verificacao,
        Prioridade prioridade
) {
}
