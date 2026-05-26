package com.ufsm.projeto_integrador.scheduler;

import com.ufsm.projeto_integrador.repository.EncaminhamentoRepository;
import com.ufsm.projeto_integrador.repository.RefreshTokenRepository;
import com.ufsm.projeto_integrador.repository.VisitaTecnicaRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.LocalDate;

@Component
@RequiredArgsConstructor
@Slf4j
public class VisitaScheduler {

    private final VisitaTecnicaRepository visitaRepository;
    private final EncaminhamentoRepository encaminhamentoRepository;
    private final RefreshTokenRepository refreshTokenRepository;

    @CacheEvict(value = "dashboard", allEntries = true)
    @Scheduled(cron = "0 0 6 * * *")
    @Transactional
    public void marcarVisitasAtrasadas() {
        int n = visitaRepository.marcarComoAtrasadas(LocalDate.now());
        log.info("[Scheduler] {} visita(s) marcada(s) como ATRASADA", n);
    }

    @CacheEvict(value = "dashboard", allEntries = true)
    @Scheduled(cron = "0 5 6 * * *")
    @Transactional
    public void marcarEncaminhamentosAtrasados() {
        int n = encaminhamentoRepository.marcarComoAtrasados(LocalDate.now());
        log.info("[Scheduler] {} encaminhamento(s) marcado(s) como ATRASADO", n);
    }

    @Scheduled(cron = "0 0 3 * * *")
    @Transactional
    public void limparRefreshTokensExpirados() {
        refreshTokenRepository.deleteExpired(Instant.now());
        log.info("[Scheduler] Refresh tokens expirados removidos");
    }
}
