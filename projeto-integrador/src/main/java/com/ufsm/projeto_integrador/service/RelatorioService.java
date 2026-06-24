package com.ufsm.projeto_integrador.service;

import com.ufsm.projeto_integrador.domain.dto.relatorio.RelatorioGeralResponse;
import com.ufsm.projeto_integrador.domain.dto.relatorio.RelatorioGeralResponse.RankingItem;
import com.ufsm.projeto_integrador.domain.dto.relatorio.RelatorioPropriedadeResponse;
import com.ufsm.projeto_integrador.domain.dto.relatorio.RelatorioPropriedadeResponse.DiagnosticoItem;
import com.ufsm.projeto_integrador.domain.dto.relatorio.RelatorioPropriedadeResponse.EncaminhamentoItem;
import com.ufsm.projeto_integrador.domain.dto.relatorio.RelatorioPropriedadeResponse.VisitaItem;
import com.ufsm.projeto_integrador.domain.entity.Encaminhamento;
import com.ufsm.projeto_integrador.domain.entity.Propriedade;
import com.ufsm.projeto_integrador.domain.entity.VisitaTecnica;
import com.ufsm.projeto_integrador.exception.ResourceNotFoundException;
import com.ufsm.projeto_integrador.repository.DiagnosticoRepository;
import com.ufsm.projeto_integrador.repository.EncaminhamentoRepository;
import com.ufsm.projeto_integrador.repository.PropriedadeRepository;
import com.ufsm.projeto_integrador.repository.VisitaTecnicaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class RelatorioService {

    private final VisitaTecnicaRepository visitaRepository;
    private final DiagnosticoRepository diagnosticoRepository;
    private final EncaminhamentoRepository encaminhamentoRepository;
    private final PropriedadeRepository propriedadeRepository;

    @Transactional(readOnly = true)
    public RelatorioGeralResponse gerarGeral(LocalDate inicio, LocalDate fim) {
        long totalVisitas = visitaRepository.countInPeriod(inicio, fim);

        Map<String, Long> visitasPorStatus = toMap(visitaRepository.countByStatusInPeriod(inicio, fim));
        Map<String, Long> visitasPorTipo = toMap(visitaRepository.countByTipoInPeriod(inicio, fim));

        long totalDiagnosticos = diagnosticoRepository.countInPeriod(inicio, fim);
        Map<String, Long> diagnosticosPorCategoria = toMap(diagnosticoRepository.countByCategoriaInPeriod(inicio, fim));
        Map<String, Long> diagnosticosPorCriticidade = toMap(diagnosticoRepository.countByCriticidadeInPeriod(inicio, fim));

        long totalEncaminhamentos = encaminhamentoRepository.countInPeriod(inicio, fim);
        Map<String, Long> encaminhamentosPorStatus = toMap(encaminhamentoRepository.countByStatusInPeriod(inicio, fim));
        long comPrazo = encaminhamentoRepository.countComPrazoInPeriod(inicio, fim);
        long concluidosNoPrazo = calcularConcluidosNoPrazo(inicio, fim);

        List<RankingItem> topVisitadas = toRankingItems(
                visitaRepository.rankPropriedadesVisitadas(inicio, fim, PageRequest.of(0, 5)));
        List<RankingItem> topDiagnosticos = toRankingItems(
                diagnosticoRepository.rankPropriedadesDiagnosticosCriticos(inicio, fim, PageRequest.of(0, 5)));
        List<RankingItem> topTecnicos = toRankingItems(
                visitaRepository.rankTecnicosPorVisitasConcluidas(inicio, fim, PageRequest.of(0, 5)));

        return new RelatorioGeralResponse(
                inicio, fim,
                totalVisitas, visitasPorStatus, visitasPorTipo,
                totalDiagnosticos, diagnosticosPorCategoria, diagnosticosPorCriticidade,
                totalEncaminhamentos, encaminhamentosPorStatus, concluidosNoPrazo, comPrazo,
                topVisitadas, topDiagnosticos, topTecnicos);
    }

    @Transactional(readOnly = true)
    public RelatorioPropriedadeResponse gerarPropriedade(Long propriedadeId, LocalDate inicio, LocalDate fim) {
        Propriedade prop = propriedadeRepository.findById(propriedadeId)
                .orElseThrow(() -> new ResourceNotFoundException("Propriedade não encontrada"));

        List<VisitaTecnica> visitas = visitaRepository.findByPropriedadeAndPeriod(propriedadeId, inicio, fim);

        Map<String, Long> visitasPorStatus = new LinkedHashMap<>();
        Map<String, Long> visitasPorTipo = new LinkedHashMap<>();
        for (VisitaTecnica v : visitas) {
            visitasPorStatus.merge(v.getStatusVisita().name(), 1L, Long::sum);
            if (v.getTipoVisita() != null) {
                visitasPorTipo.merge(v.getTipoVisita().name(), 1L, Long::sum);
            }
        }

        List<VisitaItem> listaVisitas = visitas.stream().map(v -> new VisitaItem(
                v.getDataVisita(),
                v.getHoraVisita(),
                v.getUsuario().getNome(),
                v.getTipoVisita() != null ? v.getTipoVisita().name() : null,
                v.getStatusVisita().name(),
                v.getTemaPrincipal()
        )).toList();

        var diagnosticos = diagnosticoRepository.findByPropriedadeAndPeriod(propriedadeId, inicio, fim);
        Map<String, Long> diagPorCategoria = new LinkedHashMap<>();
        Map<String, Long> diagPorCriticidade = new LinkedHashMap<>();
        for (var d : diagnosticos) {
            diagPorCategoria.merge(d.getCategoria(), 1L, Long::sum);
            diagPorCriticidade.merge(d.getCriticidade().name(), 1L, Long::sum);
        }
        List<DiagnosticoItem> listaDiag = diagnosticos.stream()
                .map(d -> new DiagnosticoItem(d.getCategoria(), d.getCriticidade().name(), d.getObservacoes()))
                .toList();

        var encaminhamentos = encaminhamentoRepository.findByPropriedadeAndPeriod(propriedadeId, inicio, fim);
        Map<String, Long> encPorStatus = new LinkedHashMap<>();
        for (Encaminhamento e : encaminhamentos) {
            encPorStatus.merge(e.getStatus().name(), 1L, Long::sum);
        }
        List<EncaminhamentoItem> listaEnc = encaminhamentos.stream()
                .map(e -> new EncaminhamentoItem(
                        e.getAcaoRealizada(),
                        e.getResponsavel(),
                        e.getPrazo(),
                        e.getPrioridade().name(),
                        e.getStatus().name()))
                .toList();

        return new RelatorioPropriedadeResponse(
                prop.getId(), prop.getNome(), prop.getNomeProprietario(),
                prop.getMunicipio(), prop.getTipoProducao() != null ? prop.getTipoProducao().name() : null,
                inicio, fim,
                visitas.size(), visitasPorStatus, visitasPorTipo, listaVisitas,
                diagnosticos.size(), diagPorCategoria, diagPorCriticidade, listaDiag,
                encaminhamentos.size(), encPorStatus, listaEnc);
    }

    private long calcularConcluidosNoPrazo(LocalDate inicio, LocalDate fim) {
        return encaminhamentoRepository.findConcluidosComPrazoInPeriod(inicio, fim).stream()
                .filter(e -> !e.getConcluidoEm().toLocalDate().isAfter(e.getPrazo()))
                .count();
    }

    private Map<String, Long> toMap(List<Object[]> rows) {
        Map<String, Long> result = new LinkedHashMap<>();
        for (Object[] row : rows) {
            result.put(row[0] != null ? row[0].toString() : "OUTRO", ((Number) row[1]).longValue());
        }
        return result;
    }

    private List<RankingItem> toRankingItems(List<Object[]> rows) {
        return rows.stream()
                .map(row -> new RankingItem(
                        row[0] instanceof Number n ? n.longValue() : null,
                        row[1] != null ? row[1].toString() : "",
                        ((Number) row[2]).longValue()))
                .toList();
    }
}
