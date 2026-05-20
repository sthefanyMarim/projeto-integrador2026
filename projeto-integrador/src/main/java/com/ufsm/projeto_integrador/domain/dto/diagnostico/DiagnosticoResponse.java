package com.ufsm.projeto_integrador.domain.dto.diagnostico;

import com.ufsm.projeto_integrador.domain.entity.Diagnostico;
import com.ufsm.projeto_integrador.domain.enums.Criticidade;

import java.time.LocalDateTime;

public record DiagnosticoResponse(
        Long id,
        Long visitaId,
        String categoria,
        Criticidade criticidade,
        String observacoes,
        LocalDateTime criadoEm
) {
    public static DiagnosticoResponse from(Diagnostico d) {
        return new DiagnosticoResponse(
                d.getId(), d.getVisita().getId(),
                d.getCategoria(), d.getCriticidade(),
                d.getObservacoes(), d.getCriadoEm());
    }
}
