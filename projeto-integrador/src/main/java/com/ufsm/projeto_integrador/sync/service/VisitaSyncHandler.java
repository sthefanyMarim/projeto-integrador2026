package com.ufsm.projeto_integrador.sync.service;

import com.ufsm.projeto_integrador.domain.dto.diagnostico.DiagnosticoRequest;
import com.ufsm.projeto_integrador.domain.dto.encaminhamento.EncaminhamentoRequest;
import com.ufsm.projeto_integrador.domain.dto.visita.FinalizarVisitaRequest;
import com.ufsm.projeto_integrador.domain.dto.visita.VisitaDetalheResponse;
import com.ufsm.projeto_integrador.domain.dto.visita.VisitaRequest;
import com.ufsm.projeto_integrador.domain.dto.visita.VisitaResponse;
import com.ufsm.projeto_integrador.domain.entity.VisitaTecnica;
import com.ufsm.projeto_integrador.domain.enums.StatusVisita;
import com.ufsm.projeto_integrador.repository.VisitaTecnicaRepository;
import com.ufsm.projeto_integrador.service.VisitaTecnicaService;
import com.ufsm.projeto_integrador.sync.dto.SyncDiagnosticoPayload;
import com.ufsm.projeto_integrador.sync.dto.SyncEncaminhamentoPayload;
import com.ufsm.projeto_integrador.sync.dto.SyncFinalizarVisitaPayload;
import com.ufsm.projeto_integrador.sync.dto.SyncOperationRequest;
import com.ufsm.projeto_integrador.sync.dto.SyncOperationResult;
import com.ufsm.projeto_integrador.sync.dto.SyncVisitaUpsertPayload;
import com.ufsm.projeto_integrador.sync.enums.SyncActionType;
import com.ufsm.projeto_integrador.sync.enums.SyncEntityType;
import com.ufsm.projeto_integrador.sync.enums.SyncErrorCode;
import com.ufsm.projeto_integrador.sync.enums.SyncOperationStatus;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
@RequiredArgsConstructor
public class VisitaSyncHandler implements SyncOperationHandler {

    private final VisitaTecnicaService visitaTecnicaService;
    private final VisitaTecnicaRepository visitaRepository;
    private final SyncAttachmentService attachmentService;
    private final SyncPayloadMapper payloadMapper;

    @Override
    public boolean supports(SyncOperationRequest request) {
        if (request.entityType() != SyncEntityType.VISITA) {
            return false;
        }
        return request.action() == SyncActionType.CREATE_VISITA
                || request.action() == SyncActionType.UPDATE_VISITA
                || request.action() == SyncActionType.CANCEL_VISITA
                || request.action() == SyncActionType.FINALIZE_VISITA;
    }

    @Override
    public SyncOperationResult handle(SyncOperationRequest request, SyncRuntimeContext context) {
        return switch (request.action()) {
            case CREATE_VISITA -> criar(request, context);
            case UPDATE_VISITA -> atualizar(request, context);
            case CANCEL_VISITA -> cancelar(request, context);
            case FINALIZE_VISITA -> finalizar(request, context);
            default -> throw SyncProcessException.failed(
                    SyncErrorCode.UNSUPPORTED_ACTION,
                    "Acao de sync nao suportada para visita"
            );
        };
    }

    private SyncOperationResult criar(SyncOperationRequest request, SyncRuntimeContext context) {
        SyncVisitaUpsertPayload payload = payloadMapper.read(request.payload(), SyncVisitaUpsertPayload.class);
        Long propriedadeId = resolvePropriedadeId(payload, context);
        VisitaResponse response = visitaTecnicaService.agendar(toVisitaRequest(payload, propriedadeId));
        return success(request, response.id(), response.version(), response, "Visita sincronizada");
    }

    private SyncOperationResult atualizar(SyncOperationRequest request, SyncRuntimeContext context) {
        Long visitaId = resolveTargetVisitaId(request, context);
        VisitaTecnica atual = loadVisita(visitaId);
        validateEditable(request, atual);

        SyncVisitaUpsertPayload payload = payloadMapper.read(request.payload(), SyncVisitaUpsertPayload.class);
        Long propriedadeId = resolvePropriedadeId(payload, context);
        VisitaResponse response = visitaTecnicaService.atualizar(visitaId, toVisitaRequest(payload, propriedadeId));
        return success(request, response.id(), response.version(), response, "Visita atualizada");
    }

    private SyncOperationResult cancelar(SyncOperationRequest request, SyncRuntimeContext context) {
        Long visitaId = resolveTargetVisitaId(request, context);
        VisitaTecnica atual = loadVisita(visitaId);

        if (atual.getStatusVisita() == StatusVisita.CANCELADA) {
            return success(
                    request,
                    atual.getId(),
                    atual.getVersion(),
                    VisitaDetalheResponse.from(atual),
                    "Visita ja estava cancelada"
            );
        }

        if (atual.getStatusVisita() == StatusVisita.CONCLUIDA) {
            throw SyncProcessException.conflict(
                    SyncErrorCode.STATE_CONFLICT,
                    "Visita concluida nao pode ser cancelada",
                    atual.getId(),
                    atual.getVersion(),
                    payloadMapper.toJsonNode(VisitaDetalheResponse.from(atual))
            );
        }

        visitaTecnicaService.cancelar(visitaId);
        VisitaTecnica atualizada = loadVisita(visitaId);
        return success(
                request,
                atualizada.getId(),
                atualizada.getVersion(),
                VisitaDetalheResponse.from(atualizada),
                "Visita cancelada"
        );
    }

    private SyncOperationResult finalizar(SyncOperationRequest request, SyncRuntimeContext context) {
        Long visitaId = resolveTargetVisitaId(request, context);
        VisitaTecnica atual = loadVisita(visitaId);
        validateBaseVersion(request, atual, "A visita foi alterada no servidor");

        if (atual.getStatusVisita() == StatusVisita.CONCLUIDA) {
            throw SyncProcessException.conflict(
                    SyncErrorCode.STATE_CONFLICT,
                    "Visita ja esta concluida no servidor",
                    atual.getId(),
                    atual.getVersion(),
                    payloadMapper.toJsonNode(VisitaDetalheResponse.from(atual))
            );
        }
        if (atual.getStatusVisita() == StatusVisita.CANCELADA) {
            throw SyncProcessException.conflict(
                    SyncErrorCode.STATE_CONFLICT,
                    "Visita cancelada nao pode ser finalizada",
                    atual.getId(),
                    atual.getVersion(),
                    payloadMapper.toJsonNode(VisitaDetalheResponse.from(atual))
            );
        }

        SyncFinalizarVisitaPayload payload = payloadMapper.read(request.payload(), SyncFinalizarVisitaPayload.class);
        List<SyncDiagnosticoPayload> diagnosticos = payload.diagnosticos();
        FinalizarVisitaRequest finalizarRequest = new FinalizarVisitaRequest(
                diagnosticos.stream().map(item -> new DiagnosticoRequest(
                        item.categoria(),
                        item.criticidade(),
                        item.observacoes(),
                        resolveDiagnosticoImagem(item, context)
                )).toList(),
                payload.encaminhamentos().stream().map(this::toEncaminhamentoRequest).toList(),
                payload.observacoesGerais()
        );

        VisitaResponse response = visitaTecnicaService.finalizar(visitaId, finalizarRequest);

        for (SyncDiagnosticoPayload diagnostico : diagnosticos) {
            if (diagnostico.attachmentId() != null) {
                attachmentService.linkToVisita(
                        diagnostico.attachmentId(),
                        context.userId(),
                        context.deviceId(),
                        visitaId
                );
            }
        }

        VisitaTecnica atualizada = loadVisita(visitaId);
        return success(
                request,
                response.id(),
                atualizada.getVersion(),
                VisitaDetalheResponse.from(atualizada),
                "Visita finalizada"
        );
    }

    private Long resolvePropriedadeId(SyncVisitaUpsertPayload payload, SyncRuntimeContext context) {
        if (payload.propriedadeId() != null) {
            return payload.propriedadeId();
        }

        Long mapped = context.resolveServerId(SyncEntityType.PROPRIEDADE, payload.propriedadeLocalId());
        if (mapped != null) {
            return mapped;
        }

        throw SyncProcessException.failed(
                SyncErrorCode.DEPENDENCY_MISSING,
                "A visita depende de uma propriedade ainda nao sincronizada"
        );
    }

    private Long resolveTargetVisitaId(SyncOperationRequest request, SyncRuntimeContext context) {
        if (request.serverId() != null) {
            return request.serverId();
        }

        Long mapped = context.resolveServerId(SyncEntityType.VISITA, request.localId());
        if (mapped != null) {
            return mapped;
        }

        throw SyncProcessException.failed(
                SyncErrorCode.DEPENDENCY_MISSING,
                "A visita ainda nao possui ID definitivo no servidor"
        );
    }

    private VisitaTecnica loadVisita(Long visitaId) {
        return visitaRepository.findById(visitaId)
                .orElseThrow(() -> SyncProcessException.failed(
                        SyncErrorCode.NOT_FOUND,
                        "Visita nao encontrada no servidor"
                ));
    }

    private void validateEditable(SyncOperationRequest request, VisitaTecnica atual) {
        validateBaseVersion(request, atual, "A visita foi alterada no servidor");

        if (atual.getStatusVisita() == StatusVisita.CONCLUIDA
            || atual.getStatusVisita() == StatusVisita.CANCELADA) {
            throw SyncProcessException.conflict(
                    SyncErrorCode.STATE_CONFLICT,
                    "A visita nao pode mais ser editada no estado atual",
                    atual.getId(),
                    atual.getVersion(),
                    payloadMapper.toJsonNode(VisitaDetalheResponse.from(atual))
            );
        }
    }

    private void validateBaseVersion(
            SyncOperationRequest request,
            VisitaTecnica atual,
            String message
    ) {
        if (request.baseVersion() != null && !request.baseVersion().equals(atual.getVersion())) {
            throw SyncProcessException.conflict(
                    SyncErrorCode.VERSION_CONFLICT,
                    message,
                    atual.getId(),
                    atual.getVersion(),
                    payloadMapper.toJsonNode(VisitaDetalheResponse.from(atual))
            );
        }
    }

    private VisitaRequest toVisitaRequest(SyncVisitaUpsertPayload payload, Long propriedadeId) {
        return new VisitaRequest(
                propriedadeId,
                payload.dataVisita(),
                payload.horaVisita(),
                payload.tipoVisita(),
                payload.temaPrincipal(),
                payload.observacoes(),
                payload.urgencia(),
                null
        );
    }

    private EncaminhamentoRequest toEncaminhamentoRequest(SyncEncaminhamentoPayload item) {
        return new EncaminhamentoRequest(
                item.acaoRealizada(),
                item.responsavel(),
                item.prazo(),
                item.verificacao(),
                item.prioridade()
        );
    }

    private String resolveDiagnosticoImagem(SyncDiagnosticoPayload item, SyncRuntimeContext context) {
        if (item.attachmentId() != null) {
            return attachmentService.resolveUploadedUrl(
                    item.attachmentId(),
                    context.userId(),
                    context.deviceId()
            );
        }
        if (item.imagemUrl() != null && !item.imagemUrl().isBlank()) {
            return item.imagemUrl();
        }
        return null;
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
