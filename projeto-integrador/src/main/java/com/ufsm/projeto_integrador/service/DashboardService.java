package com.ufsm.projeto_integrador.service;

import com.ufsm.projeto_integrador.domain.dto.common.DashboardResponse;
import com.ufsm.projeto_integrador.domain.dto.encaminhamento.EncaminhamentoResponse;
import com.ufsm.projeto_integrador.domain.dto.visita.VisitaResponse;
import com.ufsm.projeto_integrador.domain.entity.Encaminhamento;
import com.ufsm.projeto_integrador.domain.entity.Usuario;
import com.ufsm.projeto_integrador.domain.enums.StatusEncaminhamento;
import com.ufsm.projeto_integrador.exception.ResourceNotFoundException;
import com.ufsm.projeto_integrador.repository.*;
import com.ufsm.projeto_integrador.repository.spec.EncaminhamentoSpecifications;
import lombok.RequiredArgsConstructor;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class DashboardService {

    private final UsuarioRepository usuarioRepository;
    private final VisitaTecnicaRepository visitaRepository;
    private final EncaminhamentoRepository encaminhamentoRepository;
    private final PropriedadeRepository propriedadeRepository;

    @Cacheable(value = "dashboard", key = "#userId")
    @Transactional(readOnly = true)
    public DashboardResponse getDashboard(Long userId) {
        Usuario usuario = usuarioRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("Usuário não encontrado"));

        LocalDate hoje = LocalDate.now();

        List<VisitaResponse> visitasHoje = visitaRepository
                .findByUsuarioIdAndDataVisitaOrderByHoraVisitaAsc(userId, hoje)
                .stream().map(VisitaResponse::from).toList();

        long atrasadas  = visitaRepository.countAtrasadasPorUsuario(userId, hoje, LocalTime.now());
        long pendencias = encaminhamentoRepository
                .countByVisitaUsuarioIdAndStatus(userId, StatusEncaminhamento.PENDENTE)
                + encaminhamentoRepository
                .countByVisitaUsuarioIdAndStatus(userId, StatusEncaminhamento.ATRASADO);
        long totalProps = propriedadeRepository.countByAtivaTrue();

        Specification<Encaminhamento> urgentesSpecification = EncaminhamentoSpecifications.doUsuario(userId)
                .and(EncaminhamentoSpecifications.comStatus(StatusEncaminhamento.ATRASADO));

        List<EncaminhamentoResponse> urgentes = encaminhamentoRepository
                .findAll(urgentesSpecification, PageRequest.of(0, 5, Sort.by("prazo").ascending()))
                .stream().map(EncaminhamentoResponse::from).toList();

        return new DashboardResponse(
                usuario.getNome(), totalProps, atrasadas, pendencias, visitasHoje, urgentes);
    }
}
