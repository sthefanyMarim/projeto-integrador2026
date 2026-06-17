package com.ufsm.projeto_integrador.scheduler;

import com.ufsm.projeto_integrador.domain.enums.StatusEncaminhamento;
import com.ufsm.projeto_integrador.domain.enums.StatusVisita;
import com.ufsm.projeto_integrador.repository.EncaminhamentoRepository;
import com.ufsm.projeto_integrador.repository.RefreshTokenRepository;
import com.ufsm.projeto_integrador.repository.VisitaTecnicaRepository;
import com.ufsm.projeto_integrador.sync.service.SyncChangeService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;

@Component
@RequiredArgsConstructor
@Slf4j
public class VisitaScheduler {

    private final VisitaTecnicaRepository visitaRepository;
    private final EncaminhamentoRepository encaminhamentoRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final SyncChangeService syncChangeService;

    @CacheEvict(value = "dashboard", allEntries = true)
    @Scheduled(cron = "0 */30 * * * *")
    @Transactional
    public void marcarVisitasAtrasadas() {
        var visitas = visitaRepository.findAtrasadas(LocalDate.now(), LocalTime.now());
        visitas.forEach(visita -> visita.setStatusVisita(StatusVisita.ATRASADA));
        visitaRepository.saveAll(visitas);
        visitas.forEach(visita -> syncChangeService.recordVisitaUpsert(visita, null));
        log.info("[Scheduler] {} visita(s) marcada(s) como ATRASADA", visitas.size());
    }

    @CacheEvict(value = "dashboard", allEntries = true)
    @Scheduled(cron = "0 5 6 * * *")
    @Transactional
    public void marcarEncaminhamentosAtrasados() {
        var encaminhamentos = encaminhamentoRepository.findByPrazoBeforeAndStatus(LocalDate.now(), StatusEncaminhamento.PENDENTE);
        encaminhamentos.forEach(encaminhamento -> encaminhamento.setStatus(StatusEncaminhamento.ATRASADO));
        encaminhamentoRepository.saveAll(encaminhamentos);
        encaminhamentos.forEach(encaminhamento -> syncChangeService.recordEncaminhamentoUpsert(encaminhamento, null));
        log.info("[Scheduler] {} encaminhamento(s) marcado(s) como ATRASADO", encaminhamentos.size());
    }

    @Scheduled(cron = "0 0 3 * * *")
    @Transactional
    public void limparRefreshTokensExpirados() {
        refreshTokenRepository.deleteExpired(Instant.now());
        log.info("[Scheduler] Refresh tokens expirados removidos");
    }
}
