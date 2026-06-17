package com.ufsm.projeto_integrador.sync.service;

import com.ufsm.projeto_integrador.domain.dto.encaminhamento.EncaminhamentoResponse;
import com.ufsm.projeto_integrador.domain.entity.Encaminhamento;
import com.ufsm.projeto_integrador.domain.enums.StatusEncaminhamento;
import com.ufsm.projeto_integrador.repository.EncaminhamentoRepository;
import com.ufsm.projeto_integrador.service.EncaminhamentoService;
import com.ufsm.projeto_integrador.sync.dto.SyncOperationRequest;
import com.ufsm.projeto_integrador.sync.dto.SyncOperationResult;
import com.ufsm.projeto_integrador.sync.enums.SyncActionType;
import com.ufsm.projeto_integrador.sync.enums.SyncEntityType;
import com.ufsm.projeto_integrador.sync.enums.SyncErrorCode;
import com.ufsm.projeto_integrador.sync.enums.SyncOperationStatus;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
public class EncaminhamentoSyncHandler implements SyncOperationHandler {

    private final EncaminhamentoService encaminhamentoService;
    private final EncaminhamentoRepository encaminhamentoRepository;
    private final SyncPayloadMapper payloadMapper;

    @Override
    public boolean supports(SyncOperationRequest request) {
        if (request.entityType() != SyncEntityType.ENCAMINHAMENTO) {
            return false;
        }
        return request.action() == SyncActionType.CONCLUDE_ENCAMINHAMENTO
                || request.action() == SyncActionType.CANCEL_ENCAMINHAMENTO;
    }

    @Override
    public SyncOperationResult handle(SyncOperationRequest request, SyncRuntimeContext context) {
        return switch (request.action()) {
            case CONCLUDE_ENCAMINHAMENTO -> concluir(request);
            case CANCEL_ENCAMINHAMENTO -> cancelar(request);
            default -> throw SyncProcessException.failed(
                    SyncErrorCode.UNSUPPORTED_ACTION,
                    "Acao de sync nao suportada para encaminhamento"
            );
        };
    }

    private SyncOperationResult concluir(SyncOperationRequest request) {
        Encaminhamento atual = load(request.serverId());

        if (atual.getStatus() == StatusEncaminhamento.CONCLUIDO) {
            return success(
                    request,
                    atual.getId(),
                    atual.getVersion(),
                    EncaminhamentoResponse.from(atual),
                    "Encaminhamento ja estava concluido"
            );
        }

        if (atual.getStatus() == StatusEncaminhamento.CANCELADO) {
            throw SyncProcessException.conflict(
                    SyncErrorCode.STATE_CONFLICT,
                    "Encaminhamento cancelado nao pode ser concluido",
                    atual.getId(),
                    atual.getVersion(),
                    payloadMapper.toJsonNode(EncaminhamentoResponse.from(atual))
            );
        }

        EncaminhamentoResponse response = encaminhamentoService.concluir(atual.getId());
        return success(request, response.id(), response.version(), response, "Encaminhamento concluido");
    }

    private SyncOperationResult cancelar(SyncOperationRequest request) {
        Encaminhamento atual = load(request.serverId());

        if (atual.getStatus() == StatusEncaminhamento.CANCELADO) {
            return success(
                    request,
                    atual.getId(),
                    atual.getVersion(),
                    EncaminhamentoResponse.from(atual),
                    "Encaminhamento ja estava cancelado"
            );
        }

        if (atual.getStatus() == StatusEncaminhamento.CONCLUIDO) {
            throw SyncProcessException.conflict(
                    SyncErrorCode.STATE_CONFLICT,
                    "Encaminhamento concluido nao pode ser cancelado",
                    atual.getId(),
                    atual.getVersion(),
                    payloadMapper.toJsonNode(EncaminhamentoResponse.from(atual))
            );
        }

        encaminhamentoService.cancelar(atual.getId());
        Encaminhamento atualizado = load(atual.getId());
        return success(
                request,
                atualizado.getId(),
                atualizado.getVersion(),
                EncaminhamentoResponse.from(atualizado),
                "Encaminhamento cancelado"
        );
    }

    private Encaminhamento load(Long serverId) {
        if (serverId == null) {
            throw SyncProcessException.failed(
                    SyncErrorCode.DEPENDENCY_MISSING,
                    "Encaminhamento sem ID do servidor"
            );
        }

        return encaminhamentoRepository.findById(serverId)
                .orElseThrow(() -> SyncProcessException.failed(
                        SyncErrorCode.NOT_FOUND,
                        "Encaminhamento nao encontrado no servidor"
                ));
    }

    private SyncOperationResult success(
            SyncOperationRequest request,
            Long serverId,
            Long version,
            Object snapshot,
            String message
    ) {
        return new SyncOperationResult(
                request.operationId(),
                request.entityType(),
                request.action(),
                request.localId(),
                serverId,
                version,
                SyncOperationStatus.APPLIED,
                SyncErrorCode.SUCCESS,
                message,
                payloadMapper.toJsonNode(snapshot)
        );
    }
}
