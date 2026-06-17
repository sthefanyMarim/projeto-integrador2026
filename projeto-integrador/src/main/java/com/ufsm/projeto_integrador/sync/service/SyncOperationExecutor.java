package com.ufsm.projeto_integrador.sync.service;

import com.ufsm.projeto_integrador.exception.BusinessException;
import com.ufsm.projeto_integrador.sync.domain.entity.SyncOperationLog;
import com.ufsm.projeto_integrador.sync.domain.entity.SyncSession;
import com.ufsm.projeto_integrador.sync.dto.SyncOperationRequest;
import com.ufsm.projeto_integrador.sync.dto.SyncOperationResult;
import com.ufsm.projeto_integrador.sync.enums.SyncErrorCode;
import com.ufsm.projeto_integrador.sync.enums.SyncOperationStatus;
import com.ufsm.projeto_integrador.sync.repository.SyncOperationLogRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.TransactionDefinition;
import org.springframework.transaction.support.TransactionTemplate;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Objects;

@Service
public class SyncOperationExecutor {

    private final List<SyncOperationHandler> handlers;
    private final SyncOperationLogRepository operationLogRepository;
    private final SyncPayloadMapper payloadMapper;
    private final TransactionTemplate requiresNewTransaction;

    public SyncOperationExecutor(
            List<SyncOperationHandler> handlers,
            SyncOperationLogRepository operationLogRepository,
            SyncPayloadMapper payloadMapper,
            PlatformTransactionManager transactionManager
    ) {
        this.handlers = handlers;
        this.operationLogRepository = operationLogRepository;
        this.payloadMapper = payloadMapper;
        this.requiresNewTransaction = new TransactionTemplate(transactionManager);
        this.requiresNewTransaction.setPropagationBehavior(TransactionDefinition.PROPAGATION_REQUIRES_NEW);
    }

    public SyncOperationResult execute(
            SyncSession session,
            SyncOperationRequest request,
            SyncRuntimeContext context
    ) {
        String requestPayload = payloadMapper.toJsonString(request.payload());
        var existing = operationLogRepository.findByUsuarioIdAndDeviceIdAndOperationId(
                session.getUsuario().getId(),
                session.getDeviceId(),
                request.operationId()
        );
        if (existing.isPresent()) {
            return resolveExisting(existing.get(), request, requestPayload);
        }

        SyncOperationHandler handler = handlers.stream()
                .filter(candidate -> candidate.supports(request))
                .findFirst()
                .orElse(null);

        if (handler == null) {
            return persistOutcomeInNewTransaction(
                    session,
                    request,
                    requestPayload,
                    new SyncOperationResult(
                            request.operationId(),
                            request.entityType(),
                            request.action(),
                            request.localId(),
                            request.serverId(),
                            request.baseVersion(),
                            SyncOperationStatus.FAILED,
                            SyncErrorCode.UNSUPPORTED_ACTION,
                            "Nenhum handler de sync encontrado para a operacao",
                            null
                    )
            );
        }

        try {
            return requiresNewTransaction.execute(status ->
                    persistOutcome(
                            session,
                            request,
                            requestPayload,
                            handler.handle(request, context)
                    )
            );
        } catch (SyncProcessException ex) {
            return persistOutcomeInNewTransaction(session, request, requestPayload, new SyncOperationResult(
                    request.operationId(),
                    request.entityType(),
                    request.action(),
                    request.localId(),
                    ex.getServerId() != null ? ex.getServerId() : request.serverId(),
                    ex.getEntityVersion(),
                    ex.getStatus(),
                    ex.getCode(),
                    ex.getMessage(),
                    ex.getSnapshot()
            ));
        } catch (BusinessException ex) {
            return persistOutcomeInNewTransaction(session, request, requestPayload, new SyncOperationResult(
                    request.operationId(),
                    request.entityType(),
                    request.action(),
                    request.localId(),
                    request.serverId(),
                    request.baseVersion(),
                    SyncOperationStatus.FAILED,
                    SyncErrorCode.VALIDATION_ERROR,
                    ex.getMessage(),
                    null
            ));
        } catch (Exception ex) {
            return persistOutcomeInNewTransaction(session, request, requestPayload, new SyncOperationResult(
                    request.operationId(),
                    request.entityType(),
                    request.action(),
                    request.localId(),
                    request.serverId(),
                    request.baseVersion(),
                    SyncOperationStatus.FAILED,
                    SyncErrorCode.INTERNAL_ERROR,
                    "Falha interna ao processar o sync",
                    null
            ));
        }
    }

    public SyncOperationResult recordFailure(
            SyncSession session,
            SyncOperationRequest request,
            SyncErrorCode code,
            String message
    ) {
        return persistOutcomeInNewTransaction(session, request, payloadMapper.toJsonString(request.payload()), new SyncOperationResult(
                request.operationId(),
                request.entityType(),
                request.action(),
                request.localId(),
                request.serverId(),
                request.baseVersion(),
                code.isConflict() ? SyncOperationStatus.CONFLICT : SyncOperationStatus.FAILED,
                code,
                message,
                null
        ));
    }

    public SyncOperationResult recordSkipped(
            SyncSession session,
            SyncOperationRequest request,
            String message
    ) {
        return persistOutcomeInNewTransaction(session, request, payloadMapper.toJsonString(request.payload()), new SyncOperationResult(
                request.operationId(),
                request.entityType(),
                request.action(),
                request.localId(),
                request.serverId(),
                request.baseVersion(),
                SyncOperationStatus.SKIPPED,
                SyncErrorCode.SESSION_ABORTED,
                message,
                null
        ));
    }

    private SyncOperationResult resolveExisting(
            SyncOperationLog existing,
            SyncOperationRequest request,
            String requestPayload
    ) {
        if (sameRequest(existing, request, requestPayload)) {
            return toResult(existing);
        }

        return new SyncOperationResult(
                request.operationId(),
                request.entityType(),
                request.action(),
                request.localId(),
                request.serverId(),
                request.baseVersion(),
                SyncOperationStatus.FAILED,
                SyncErrorCode.VALIDATION_ERROR,
                "operationId ja foi utilizado com outro payload neste dispositivo",
                null
        );
    }

    private boolean sameRequest(
            SyncOperationLog existing,
            SyncOperationRequest request,
            String requestPayload
    ) {
        return existing.getEntityType() == request.entityType()
                && existing.getActionType() == request.action()
                && Objects.equals(existing.getLocalId(), request.localId())
                && (request.serverId() == null || Objects.equals(existing.getServerId(), request.serverId()))
                && Objects.equals(existing.getBaseVersion(), request.baseVersion())
                && Objects.equals(normalize(existing.getRequestPayload()), normalize(requestPayload));
    }

    private SyncOperationResult persistOutcome(
            SyncSession session,
            SyncOperationRequest request,
            String requestPayload,
            SyncOperationResult result
    ) {
        SyncOperationLog log = SyncOperationLog.builder()
                .operationId(result.operationId())
                .session(session)
                .usuario(session.getUsuario())
                .deviceId(session.getDeviceId())
                .entityType(result.entityType())
                .actionType(result.action())
                .localId(result.localId())
                .serverId(result.serverId())
                .baseVersion(request.baseVersion())
                .status(result.status())
                .errorCode(result.code())
                .message(result.message())
                .requestPayload(requestPayload)
                .responseSnapshot(payloadMapper.toJsonString(result.snapshot()))
                .entityVersion(result.entityVersion())
                .processedAt(LocalDateTime.now())
                .build();

        operationLogRepository.save(log);
        return result;
    }

    private SyncOperationResult persistOutcomeInNewTransaction(
            SyncSession session,
            SyncOperationRequest request,
            String requestPayload,
            SyncOperationResult result
    ) {
        return requiresNewTransaction.execute(status -> persistOutcome(session, request, requestPayload, result));
    }

    private SyncOperationResult toResult(SyncOperationLog log) {
        SyncErrorCode code = log.getErrorCode() == null ? SyncErrorCode.ALREADY_APPLIED : log.getErrorCode();
        String message = log.getMessage();
        if (code == SyncErrorCode.ALREADY_APPLIED && (message == null || message.isBlank())) {
            message = "Operacao ja processada em sessao anterior";
        }

        return new SyncOperationResult(
                log.getOperationId(),
                log.getEntityType(),
                log.getActionType(),
                log.getLocalId(),
                log.getServerId(),
                log.getEntityVersion(),
                log.getStatus(),
                code,
                message,
                payloadMapper.parse(log.getResponseSnapshot())
        );
    }

    private String normalize(String value) {
        return value == null ? "" : value;
    }
}
