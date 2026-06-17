package com.ufsm.projeto_integrador.domain.dto.visita;

import com.ufsm.projeto_integrador.domain.dto.diagnostico.DiagnosticoResponse;
import com.ufsm.projeto_integrador.domain.dto.encaminhamento.EncaminhamentoResponse;
import com.ufsm.projeto_integrador.domain.entity.VisitaTecnica;
import com.ufsm.projeto_integrador.domain.enums.StatusVisita;
import com.ufsm.projeto_integrador.domain.enums.TipoVisita;
import com.ufsm.projeto_integrador.domain.enums.Urgencia;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;

public record VisitaDetalheResponse(
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
        Long version,
        LocalDateTime criadoEm,
        LocalDateTime atualizadoEm,
        List<DiagnosticoResponse> diagnosticos,
        List<EncaminhamentoResponse> encaminhamentos
) {
    public static VisitaDetalheResponse from(VisitaTecnica v) {
        return new VisitaDetalheResponse(
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
                v.getVersion(),
                v.getCriadoEm(),
                v.getAtualizadoEm(),
                v.getDiagnosticos().stream().map(DiagnosticoResponse::from).toList(),
                v.getEncaminhamentos().stream().map(EncaminhamentoResponse::from).toList()
        );
    }
}
