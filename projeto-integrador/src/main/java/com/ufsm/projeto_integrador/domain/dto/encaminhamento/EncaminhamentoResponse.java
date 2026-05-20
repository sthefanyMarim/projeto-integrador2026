package com.ufsm.projeto_integrador.domain.dto.encaminhamento;

import com.ufsm.projeto_integrador.domain.entity.Encaminhamento;
import com.ufsm.projeto_integrador.domain.enums.Prioridade;
import com.ufsm.projeto_integrador.domain.enums.StatusEncaminhamento;
import com.ufsm.projeto_integrador.domain.enums.Verificacao;

import java.time.LocalDate;
import java.time.LocalDateTime;

public record EncaminhamentoResponse(
        Long id,
        Long visitaId,
        String propriedadeNome,
        String acaoRealizada,
        String responsavel,
        LocalDate prazo,
        Verificacao verificacao,
        Prioridade prioridade,
        StatusEncaminhamento status,
        LocalDateTime concluidoEm,
        LocalDateTime criadoEm
) {
    public static EncaminhamentoResponse from(Encaminhamento e) {
        return new EncaminhamentoResponse(
                e.getId(),
                e.getVisita().getId(),
                e.getVisita().getPropriedade().getNome(),
                e.getAcaoRealizada(),
                e.getResponsavel(),
                e.getPrazo(),
                e.getVerificacao(),
                e.getPrioridade(),
                e.getStatus(),
                e.getConcluidoEm(),
                e.getCriadoEm());
    }
}
