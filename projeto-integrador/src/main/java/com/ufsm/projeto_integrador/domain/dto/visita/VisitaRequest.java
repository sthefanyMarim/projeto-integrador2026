package com.ufsm.projeto_integrador.domain.dto.visita;

import com.ufsm.projeto_integrador.domain.enums.TipoVisita;
import com.ufsm.projeto_integrador.domain.enums.Urgencia;
import jakarta.validation.constraints.FutureOrPresent;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.LocalDate;
import java.time.LocalTime;

public record VisitaRequest(
        @NotNull(message = "Propriedade obrigatória") Long propriedadeId,
        @NotNull(message = "Data obrigatória") @FutureOrPresent LocalDate dataVisita,
        @NotNull(message = "Hora obrigatória") LocalTime horaVisita,
        @NotNull(message = "Tipo obrigatório") TipoVisita tipoVisita,
        @Size(max = 200) String temaPrincipal,
        String observacoes,
        Urgencia urgencia,
        Long baseVersion
) {}
