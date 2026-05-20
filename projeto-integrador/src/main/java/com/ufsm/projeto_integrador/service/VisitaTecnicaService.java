package com.ufsm.projeto_integrador.service;

import com.ufsm.projeto_integrador.domain.dto.common.PageResponse;
import com.ufsm.projeto_integrador.domain.dto.visita.FinalizarVisitaRequest;
import com.ufsm.projeto_integrador.domain.dto.visita.VisitaRequest;
import com.ufsm.projeto_integrador.domain.dto.visita.VisitaResponse;
import com.ufsm.projeto_integrador.domain.entity.*;
import com.ufsm.projeto_integrador.domain.enums.StatusEncaminhamento;
import com.ufsm.projeto_integrador.domain.enums.StatusVisita;
import com.ufsm.projeto_integrador.exception.BusinessException;
import com.ufsm.projeto_integrador.exception.ResourceNotFoundException;
import com.ufsm.projeto_integrador.repository.PropriedadeRepository;
import com.ufsm.projeto_integrador.repository.VisitaTecnicaRepository;
import com.ufsm.projeto_integrador.repository.spec.VisitaTecnicaSpecifications;
import com.ufsm.projeto_integrador.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;

@Service
@RequiredArgsConstructor
public class VisitaTecnicaService {

    private final VisitaTecnicaRepository repository;
    private final PropriedadeRepository propriedadeRepository;

    public List<VisitaResponse> listarHoje(Long userId) {
        return repository
                .findByUsuarioIdAndDataVisitaOrderByHoraVisitaAsc(userId, LocalDate.now())
                .stream().map(VisitaResponse::from).toList();
    }

    public PageResponse<VisitaResponse> listar(StatusVisita status, Long propId, Pageable pageable) {
        Long userId = SecurityUtils.isAdmin() ? null : SecurityUtils.getCurrentUserId();
        Specification<VisitaTecnica> specification = VisitaTecnicaSpecifications.doUsuario(userId)
                .and(VisitaTecnicaSpecifications.comStatus(status))
                .and(VisitaTecnicaSpecifications.daPropriedade(propId));

        return PageResponse.from(repository.findAll(specification, pageable).map(VisitaResponse::from));
    }

    public VisitaResponse buscarPorId(Long id) {
        return VisitaResponse.from(findOrThrow(id));
    }

    @CacheEvict(value = "dashboard", key = "#result.usuarioId()")
    @Transactional
    public VisitaResponse agendar(VisitaRequest req) {
        Long userId = SecurityUtils.getCurrentUserId();

        Propriedade propriedade = propriedadeRepository.findById(req.propriedadeId())
                .orElseThrow(() -> new ResourceNotFoundException("Propriedade não encontrada"));
        if (!propriedade.getAtiva())
            throw new BusinessException("Propriedade inativa");

        Usuario usuario = new Usuario();
        usuario.setId(userId);

        VisitaTecnica visita = VisitaTecnica.builder()
                .usuario(usuario)
                .propriedade(propriedade)
                .dataVisita(req.dataVisita())
                .horaVisita(req.horaVisita())
                .tipoVisita(req.tipoVisita())
                .temaPrincipal(req.temaPrincipal())
                .observacoes(req.observacoes())
                .urgencia(req.urgencia() != null ? req.urgencia() : com.ufsm.projeto_integrador.domain.enums.Urgencia.BAIXA)
                .statusVisita(StatusVisita.AGENDADA)
                .build();

        return VisitaResponse.from(repository.save(visita));
    }

    @Transactional
    public VisitaResponse atualizar(Long id, VisitaRequest req) {
        VisitaTecnica visita = findOrThrow(id);
        validarAcesso(visita);

        Propriedade propriedade = propriedadeRepository.findById(req.propriedadeId())
                .orElseThrow(() -> new ResourceNotFoundException("Propriedade não encontrada"));

        visita.setPropriedade(propriedade);
        visita.setDataVisita(req.dataVisita());
        visita.setHoraVisita(req.horaVisita());
        visita.setTipoVisita(req.tipoVisita());
        visita.setTemaPrincipal(req.temaPrincipal());
        visita.setObservacoes(req.observacoes());
        if (req.urgencia() != null) visita.setUrgencia(req.urgencia());

        return VisitaResponse.from(repository.save(visita));
    }

    @Transactional
    public VisitaResponse finalizar(Long id, FinalizarVisitaRequest req) {
        VisitaTecnica visita = findOrThrow(id);
        validarAcesso(visita);

        if (visita.getStatusVisita() == StatusVisita.CONCLUIDA)
            throw new BusinessException("Visita já concluída");
        if (visita.getStatusVisita() == StatusVisita.CANCELADA)
            throw new BusinessException("Visita cancelada não pode ser finalizada");

        if (req.observacoesGerais() != null)
            visita.setObservacoes(req.observacoesGerais());

        req.diagnosticos().forEach(d -> {
            Diagnostico diag = Diagnostico.builder()
                    .visita(visita)
                    .categoria(d.categoria())
                    .criticidade(d.criticidade())
                    .observacoes(d.observacoes())
                    .build();
            visita.getDiagnosticos().add(diag);
        });

        req.encaminhamentos().forEach(e -> {
            Encaminhamento enc = Encaminhamento.builder()
                    .visita(visita)
                    .acaoRealizada(e.acaoRealizada())
                    .responsavel(e.responsavel())
                    .prazo(e.prazo())
                    .verificacao(e.verificacao())
                    .prioridade(e.prioridade() != null ? e.prioridade() : com.ufsm.projeto_integrador.domain.enums.Prioridade.MEDIA)
                    .status(StatusEncaminhamento.PENDENTE)
                    .build();
            visita.getEncaminhamentos().add(enc);
        });

        visita.setStatusVisita(StatusVisita.CONCLUIDA);
        return VisitaResponse.from(repository.save(visita));
    }

    @Transactional
    public void cancelar(Long id) {
        VisitaTecnica visita = findOrThrow(id);
        validarAcesso(visita);
        if (visita.getStatusVisita() == StatusVisita.CONCLUIDA)
            throw new BusinessException("Visita concluída não pode ser cancelada");
        visita.setStatusVisita(StatusVisita.CANCELADA);
        repository.save(visita);
    }

    private void validarAcesso(VisitaTecnica visita) {
        if (!SecurityUtils.isAdmin() &&
            !visita.getUsuario().getId().equals(SecurityUtils.getCurrentUserId())) {
            throw new BusinessException("Acesso negado a esta visita");
        }
    }

    private VisitaTecnica findOrThrow(Long id) {
        return repository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Visita não encontrada: " + id));
    }
}
