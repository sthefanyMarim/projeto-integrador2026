package com.ufsm.projeto_integrador.domain.dto.relatorio;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

public record RelatorioGeralResponse(
        LocalDate inicio,
        LocalDate fim,

        long totalVisitas,
        Map<String, Long> visitasPorStatus,
        Map<String, Long> visitasPorTipo,

        long totalDiagnosticos,
        Map<String, Long> diagnosticosPorCategoria,
        Map<String, Long> diagnosticosPorCriticidade,

        long totalEncaminhamentos,
        Map<String, Long> encaminhamentosPorStatus,
        long encaminhadosConcluidosNoPrazo,
        long encaminhadosComPrazo,

        List<RankingItem> topPropriedadesVisitadas,
        List<RankingItem> topPropriedadesDiagnosticos,
        List<RankingItem> visitasPorTecnico
) {
    public record RankingItem(Long id, String nome, long total) {}
}
