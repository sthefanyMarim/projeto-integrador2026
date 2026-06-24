package com.ufsm.projeto_integrador.service;

import com.ufsm.projeto_integrador.domain.dto.common.PageResponse;
import com.ufsm.projeto_integrador.domain.dto.visita.FinalizarVisitaRequest;
import com.ufsm.projeto_integrador.domain.dto.visita.VisitaDetalheResponse;
import com.ufsm.projeto_integrador.domain.dto.visita.VisitaRequest;
import com.ufsm.projeto_integrador.domain.dto.visita.VisitaResponse;
import com.ufsm.projeto_integrador.domain.entity.*;
import com.ufsm.projeto_integrador.domain.enums.Prioridade;
import com.ufsm.projeto_integrador.domain.enums.StatusEncaminhamento;
import com.ufsm.projeto_integrador.domain.enums.StatusVisita;
import com.ufsm.projeto_integrador.domain.enums.Verificacao;
import com.ufsm.projeto_integrador.exception.BusinessException;
import com.ufsm.projeto_integrador.exception.ResourceNotFoundException;
import com.ufsm.projeto_integrador.repository.PropriedadeRepository;
import com.ufsm.projeto_integrador.repository.UsuarioRepository;
import com.ufsm.projeto_integrador.repository.VisitaTecnicaRepository;
import com.ufsm.projeto_integrador.repository.spec.VisitaTecnicaSpecifications;
import com.ufsm.projeto_integrador.security.SecurityUtils;
import com.ufsm.projeto_integrador.sync.service.SyncChangeService;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.Comparator;
import java.util.List;

@Service
@RequiredArgsConstructor
public class VisitaTecnicaService {

    private static final DateTimeFormatter HORA_FMT = DateTimeFormatter.ofPattern("HH:mm");

    private final VisitaTecnicaRepository repository;
    private final PropriedadeRepository propriedadeRepository;
    private final UsuarioRepository usuarioRepository;
    private final SyncChangeService syncChangeService;

    @Value("${app.visita.duracao-minutos:45}")
    private int duracaoVisitaMinutos;

    @Transactional(readOnly = true)
    public List<VisitaResponse> listarHoje(Long userId) {
        return repository
                .findByUsuarioIdAndDataVisitaOrderByHoraVisitaAsc(userId, LocalDate.now())
                .stream().map(VisitaResponse::from).toList();
    }

    @Transactional(readOnly = true)
    public PageResponse<VisitaResponse> listar(StatusVisita status, Long propId, Pageable pageable) {
        Long userId = SecurityUtils.isAdmin() ? null : SecurityUtils.getCurrentUserId();
        Specification<VisitaTecnica> specification = VisitaTecnicaSpecifications.doUsuario(userId)
                .and(VisitaTecnicaSpecifications.comStatus(status))
                .and(VisitaTecnicaSpecifications.daPropriedade(propId));

        return PageResponse.from(repository.findAll(specification, pageable).map(VisitaResponse::from));
    }

    @Transactional(readOnly = true)
    public VisitaResponse buscarPorId(Long id) {
        return VisitaResponse.from(buscarAutorizada(id));
    }

    @Transactional(readOnly = true)
    public VisitaDetalheResponse buscarDetalhes(Long id) {
        return VisitaDetalheResponse.from(buscarAutorizada(id));
    }

    @Transactional(readOnly = true)
    public VisitaTecnica buscarAutorizada(Long id) {
        VisitaTecnica visita = findOrThrow(id);
        validarAcesso(visita);
        return visita;
    }

    @CacheEvict(value = "dashboard", allEntries = true)
    @Transactional
    public VisitaResponse agendar(VisitaRequest req) {
        Long userId = SecurityUtils.getCurrentUserId();

        Propriedade propriedade = propriedadeRepository.findById(req.propriedadeId())
                .orElseThrow(() -> new ResourceNotFoundException("Propriedade não encontrada"));
        if (!propriedade.getAtiva())
            throw new BusinessException("Propriedade inativa");

        validarHorarioPassado(req.dataVisita(), req.horaVisita());
        validarConflito(userId, req.dataVisita(), req.horaVisita(), null);

        Usuario usuario = usuarioRepository.getReferenceById(userId);

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

        VisitaTecnica salva = repository.save(visita);
        syncChangeService.recordVisitaUpsert(salva, userId);
        return VisitaResponse.from(salva);
    }

    @CacheEvict(value = "dashboard", allEntries = true)
    @Transactional
    public VisitaResponse atualizar(Long id, VisitaRequest req) {
        VisitaTecnica visita = findOrThrow(id);
        validarAcesso(visita);

        Propriedade propriedade = propriedadeRepository.findById(req.propriedadeId())
                .orElseThrow(() -> new ResourceNotFoundException("Propriedade não encontrada"));

        if (req.baseVersion() != null && !req.baseVersion().equals(visita.getVersion())) {
            throw new BusinessException(
                    "Esta visita foi modificada por outro dispositivo. Recarregue e tente novamente.");
        }
        validarHorarioPassado(req.dataVisita(), req.horaVisita());
        validarConflito(visita.getUsuario().getId(), req.dataVisita(), req.horaVisita(), id);

        visita.setPropriedade(propriedade);
        visita.setDataVisita(req.dataVisita());
        visita.setHoraVisita(req.horaVisita());
        visita.setTipoVisita(req.tipoVisita());
        visita.setTemaPrincipal(req.temaPrincipal());
        visita.setObservacoes(req.observacoes());
        if (req.urgencia() != null) visita.setUrgencia(req.urgencia());

        VisitaTecnica salva = repository.save(visita);
        syncChangeService.recordVisitaUpsert(salva, SecurityUtils.getCurrentUserIdOrNull());
        return VisitaResponse.from(salva);
    }

    @CacheEvict(value = "dashboard", allEntries = true)
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
                    .imagemUrl(d.imagemUrl())
                    .build();
            visita.getDiagnosticos().add(diag);
        });

        req.encaminhamentos().forEach(e -> {
            if (e.verificacao() == null) {
                throw new BusinessException("Forma de verificação obrigatória para o encaminhamento.");
            }
            if (e.verificacao() != Verificacao.VISITA && e.prazo() == null) {
                throw new BusinessException(
                    "Encaminhamento de verificação por " + e.verificacao().name().toLowerCase() +
                    " requer um prazo definido."
                );
            }

            Prioridade prioridadeFinal;
            if (e.verificacao() == Verificacao.VISITA && e.prazo() == null) {
                prioridadeFinal = Prioridade.CRITICA;
            } else {
                prioridadeFinal = e.prioridade() != null ? e.prioridade() : Prioridade.MEDIA;
            }

            Encaminhamento enc = Encaminhamento.builder()
                    .visita(visita)
                    .acaoRealizada(e.acaoRealizada())
                    .responsavel(e.responsavel())
                    .prazo(e.prazo())
                    .verificacao(e.verificacao())
                    .prioridade(prioridadeFinal)
                    .status(StatusEncaminhamento.PENDENTE)
                    .build();
            visita.getEncaminhamentos().add(enc);
        });

        visita.setStatusVisita(StatusVisita.CONCLUIDA);
        VisitaTecnica salva = repository.save(visita);
        Long changedBy = SecurityUtils.getCurrentUserIdOrNull();
        syncChangeService.recordVisitaUpsert(salva, changedBy);
        salva.getEncaminhamentos().forEach(enc -> syncChangeService.recordEncaminhamentoUpsert(enc, changedBy));
        return VisitaResponse.from(salva);
    }

    @CacheEvict(value = "dashboard", allEntries = true)
    @Transactional
    public void cancelar(Long id) {
        VisitaTecnica visita = findOrThrow(id);
        validarAcesso(visita);
        if (visita.getStatusVisita() == StatusVisita.CONCLUIDA)
            throw new BusinessException("Visita concluída não pode ser cancelada");
        visita.setStatusVisita(StatusVisita.CANCELADA);
        VisitaTecnica salva = repository.save(visita);
        syncChangeService.recordVisitaUpsert(salva, SecurityUtils.getCurrentUserIdOrNull());
    }

    private void validarHorarioPassado(LocalDate data, LocalTime hora) {
        if (LocalDateTime.of(data, hora).isBefore(LocalDateTime.now())) {
            throw new BusinessException("Não é possível agendar uma visita para uma data e horário no passado.");
        }
    }

    private void validarConflito(Long userId, LocalDate data, LocalTime hora, Long excludeId) {
        List<VisitaTecnica> existentes = repository.findAtivasByUsuarioAndData(userId, data)
                .stream()
                .filter(v -> excludeId == null || !v.getId().equals(excludeId))
                .sorted(Comparator.comparing(VisitaTecnica::getHoraVisita))
                .toList();

        for (VisitaTecnica existente : existentes) {
            long diffMinutos = Math.abs(Duration.between(hora, existente.getHoraVisita()).toMinutes());
            if (diffMinutos < duracaoVisitaMinutos) {
                LocalTime proximo = existente.getHoraVisita().plusMinutes(duracaoVisitaMinutos);
                throw new BusinessException(String.format(
                        "Conflito de horário: você já possui uma visita agendada às %s neste dia. " +
                        "O próximo horário disponível é a partir das %s.",
                        existente.getHoraVisita().format(HORA_FMT),
                        proximo.format(HORA_FMT)
                ));
            }
        }
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
