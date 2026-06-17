package com.ufsm.projeto_integrador.domain.dto.relatorio;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.Map;

public record RelatorioPropriedadeResponse(
        long propriedadeId,
        String propriedadeNome,
        String nomeProprietario,
        String municipio,
        String tipoProducao,

        LocalDate inicio,
        LocalDate fim,

        long totalVisitas,
        Map<String, Long> visitasPorStatus,
        Map<String, Long> visitasPorTipo,
        List<VisitaItem> visitas,

        long totalDiagnosticos,
        Map<String, Long> diagnosticosPorCategoria,
        Map<String, Long> diagnosticosPorCriticidade,
        List<DiagnosticoItem> diagnosticos,

        long totalEncaminhamentos,
        Map<String, Long> encaminhamentosPorStatus,
        List<EncaminhamentoItem> encaminhamentos
) {
    public record VisitaItem(
            LocalDate data,
            LocalTime hora,
            String tecnico,
            String tipo,
            String status,
            String temaPrincipal
    ) {}

    public record DiagnosticoItem(
            String categoria,
            String criticidade,
            String observacoes
    ) {}

    public record EncaminhamentoItem(
            String acaoRealizada,
            String responsavel,
            LocalDate prazo,
            String prioridade,
            String status
    ) {}
}
