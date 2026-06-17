package com.ufsm.projeto_integrador.sync.dto;

import com.ufsm.projeto_integrador.domain.enums.TipoVisita;
import com.ufsm.projeto_integrador.domain.enums.Urgencia;
import jakarta.validation.constraints.NotNull;

import java.time.LocalDate;
import java.time.LocalTime;

public record SyncVisitaUpsertPayload(
        Long propriedadeId,
        String propriedadeLocalId,
        @NotNull LocalDate dataVisita,
        @NotNull LocalTime horaVisita,
        @NotNull TipoVisita tipoVisita,
        String temaPrincipal,
        String observacoes,
        Urgencia urgencia
) {
}
