package com.ufsm.projeto_integrador.domain.dto.visita;

import com.ufsm.projeto_integrador.domain.entity.VisitaTecnica;
import com.ufsm.projeto_integrador.domain.enums.StatusVisita;
import com.ufsm.projeto_integrador.domain.enums.TipoVisita;
import com.ufsm.projeto_integrador.domain.enums.Urgencia;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;

public record VisitaResponse(
        Long id,
        Long usuarioId,
        String usuarioNome,
        Long propriedadeId,
        String propriedadeNome,
        LocalDate dataVisita,
        LocalTime horaVisita,
        TipoVisita tipoVisita,
        String temaPrincipal,
        String observacoes,
        StatusVisita statusVisita,
        Urgencia urgencia,
        LocalDateTime criadoEm
) {
    public static VisitaResponse from(VisitaTecnica v) {
        return new VisitaResponse(
                v.getId(),
                v.getUsuario().getId(),
                v.getUsuario().getNome(),
                v.getPropriedade().getId(),
                v.getPropriedade().getNome(),
                v.getDataVisita(),
                v.getHoraVisita(),
                v.getTipoVisita(),
                v.getTemaPrincipal(),
                v.getObservacoes(),
                v.getStatusVisita(),
                v.getUrgencia(),
                v.getCriadoEm());
    }
}
