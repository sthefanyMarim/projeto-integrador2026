package com.ufsm.projeto_integrador.service;

import com.ufsm.projeto_integrador.domain.dto.common.PageResponse;
import com.ufsm.projeto_integrador.domain.dto.encaminhamento.EncaminhamentoResponse;
import com.ufsm.projeto_integrador.domain.entity.Encaminhamento;
import com.ufsm.projeto_integrador.domain.enums.StatusEncaminhamento;
import com.ufsm.projeto_integrador.exception.BusinessException;
import com.ufsm.projeto_integrador.exception.ResourceNotFoundException;
import com.ufsm.projeto_integrador.repository.EncaminhamentoRepository;
import com.ufsm.projeto_integrador.repository.spec.EncaminhamentoSpecifications;
import com.ufsm.projeto_integrador.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

@Service
@RequiredArgsConstructor
public class EncaminhamentoService {

    private final EncaminhamentoRepository repository;

    public PageResponse<EncaminhamentoResponse> listarMeus(StatusEncaminhamento status, Pageable pageable) {
        Long userId = SecurityUtils.getCurrentUserId();
        Specification<Encaminhamento> specification = EncaminhamentoSpecifications.doUsuario(userId)
                .and(EncaminhamentoSpecifications.comStatus(status));

        return PageResponse.from(repository.findAll(specification, pageable).map(EncaminhamentoResponse::from));
    }

    @Transactional
    public EncaminhamentoResponse concluir(Long id) {
        Encaminhamento enc = findOrThrow(id);
        validarAcesso(enc);

        if (enc.getStatus() == StatusEncaminhamento.CONCLUIDO)
            throw new BusinessException("Encaminhamento já concluído");
        if (enc.getStatus() == StatusEncaminhamento.CANCELADO)
            throw new BusinessException("Encaminhamento cancelado");

        enc.setStatus(StatusEncaminhamento.CONCLUIDO);
        enc.setConcluidoEm(LocalDateTime.now());
        return EncaminhamentoResponse.from(repository.save(enc));
    }

    @Transactional
    public void cancelar(Long id) {
        Encaminhamento enc = findOrThrow(id);
        validarAcesso(enc);

        if (enc.getStatus() == StatusEncaminhamento.CONCLUIDO)
            throw new BusinessException("Encaminhamento já concluído não pode ser cancelado");

        enc.setStatus(StatusEncaminhamento.CANCELADO);
        repository.save(enc);
    }

    private void validarAcesso(Encaminhamento enc) {
        Long tecnicoId = enc.getVisita().getUsuario().getId();
        if (!SecurityUtils.isAdmin() && !tecnicoId.equals(SecurityUtils.getCurrentUserId()))
            throw new BusinessException("Acesso negado a este encaminhamento");
    }

    private Encaminhamento findOrThrow(Long id) {
        return repository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Encaminhamento não encontrado: " + id));
    }
}
