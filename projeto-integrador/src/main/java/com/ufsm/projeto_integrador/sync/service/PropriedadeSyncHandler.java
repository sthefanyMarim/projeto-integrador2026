package com.ufsm.projeto_integrador.sync.service;

import com.ufsm.projeto_integrador.domain.dto.propriedade.PropriedadeRequest;
import com.ufsm.projeto_integrador.domain.dto.propriedade.PropriedadeResponse;
import com.ufsm.projeto_integrador.domain.entity.Propriedade;
import com.ufsm.projeto_integrador.repository.PropriedadeRepository;
import com.ufsm.projeto_integrador.service.PropriedadeService;
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
public class PropriedadeSyncHandler implements SyncOperationHandler {

    private final PropriedadeService propriedadeService;
    private final PropriedadeRepository propriedadeRepository;
    private final SyncPayloadMapper payloadMapper;

    @Override
    public boolean supports(SyncOperationRequest request) {
        if (request.entityType() != SyncEntityType.PROPRIEDADE) {
            return false;
        }
        return request.action() == SyncActionType.CREATE_PROPRIEDADE
                || request.action() == SyncActionType.UPDATE_PROPRIEDADE
                || request.action() == SyncActionType.DELETE_PROPRIEDADE;
    }

    @Override
    public SyncOperationResult handle(SyncOperationRequest request, SyncRuntimeContext context) {
        return switch (request.action()) {
            case CREATE_PROPRIEDADE -> criar(request);
            case UPDATE_PROPRIEDADE -> atualizar(request, context);
            case DELETE_PROPRIEDADE -> deletar(request, context);
            default -> throw SyncProcessException.failed(
                    SyncErrorCode.UNSUPPORTED_ACTION,
                    "Acao de sync nao suportada para propriedade"
            );
        };
    }

    private SyncOperationResult criar(SyncOperationRequest request) {
        PropriedadeRequest payload = payloadMapper.read(request.payload(), PropriedadeRequest.class);
        PropriedadeResponse response = propriedadeService.criar(payload);
        return success(request, response.id(), response.version(), response, "Propriedade sincronizada");
    }

    private SyncOperationResult atualizar(SyncOperationRequest request, SyncRuntimeContext context) {
        Long targetId = resolveTargetId(request, context);
        Propriedade atual = propriedadeRepository.findById(targetId)
                .orElseThrow(() -> SyncProcessException.failed(
                        SyncErrorCode.NOT_FOUND,
                        "Propriedade nao encontrada no servidor"
                ));

        validateBaseVersion(request, atual);

        PropriedadeRequest payload = payloadMapper.read(request.payload(), PropriedadeRequest.class);
        PropriedadeResponse response = propriedadeService.atualizar(targetId, payload);
        return success(request, response.id(), response.version(), response, "Propriedade atualizada");
    }

    private SyncOperationResult deletar(SyncOperationRequest request, SyncRuntimeContext context) {
        Long targetId = resolveTargetId(request, context);
        Propriedade atual = propriedadeRepository.findById(targetId)
                .orElseThrow(() -> SyncProcessException.failed(
                        SyncErrorCode.NOT_FOUND,
                        "Propriedade nao encontrada no servidor"
                ));

        validateBaseVersion(request, atual);
        propriedadeService.deletar(targetId);

        return new SyncOperationResult(
                request.operationId(),
                request.entityType(),
                request.action(),
                request.localId(),
                targetId,
                atual.getVersion(),
                SyncOperationStatus.APPLIED,
                SyncErrorCode.SUCCESS,
                "Propriedade removida",
                null
        );
    }

    private Long resolveTargetId(SyncOperationRequest request, SyncRuntimeContext context) {
        if (request.serverId() != null) {
            return request.serverId();
        }
        Long mapped = context.resolveServerId(request.entityType(), request.localId());
        if (mapped != null) {
            return mapped;
        }
        throw SyncProcessException.failed(
                SyncErrorCode.DEPENDENCY_MISSING,
                "Registro local ainda nao foi mapeado para um ID do servidor"
        );
    }

    private void validateBaseVersion(SyncOperationRequest request, Propriedade atual) {
        if (request.baseVersion() == null) {
            return;
        }
        if (!request.baseVersion().equals(atual.getVersion())) {
            throw SyncProcessException.conflict(
                    SyncErrorCode.VERSION_CONFLICT,
                    "A propriedade foi alterada no servidor",
                    atual.getId(),
                    atual.getVersion(),
                    payloadMapper.toJsonNode(PropriedadeResponse.from(atual))
            );
        }
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
