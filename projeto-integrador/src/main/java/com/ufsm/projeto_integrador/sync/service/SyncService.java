package com.ufsm.projeto_integrador.sync.service;

import com.ufsm.projeto_integrador.repository.UsuarioRepository;
import com.ufsm.projeto_integrador.exception.BusinessException;
import com.ufsm.projeto_integrador.security.SecurityUtils;
import com.ufsm.projeto_integrador.sync.domain.entity.SyncSession;
import com.ufsm.projeto_integrador.sync.dto.SyncOperationRequest;
import com.ufsm.projeto_integrador.sync.dto.SyncOperationResult;
import com.ufsm.projeto_integrador.sync.dto.SyncRequest;
import com.ufsm.projeto_integrador.sync.dto.SyncResponse;
import com.ufsm.projeto_integrador.sync.dto.SyncServerChange;
import com.ufsm.projeto_integrador.sync.enums.SyncErrorCode;
import com.ufsm.projeto_integrador.sync.enums.SyncOperationStatus;
import com.ufsm.projeto_integrador.sync.enums.SyncSessionStatus;
import com.ufsm.projeto_integrador.sync.repository.SyncSessionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Collection;
import java.util.EnumSet;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.IdentityHashMap;
import java.util.Objects;
import java.util.Set;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class SyncService {

    private final SyncSessionRepository sessionRepository;
    private final SyncOperationExecutor operationExecutor;
    private final SyncChangeService changeService;
    private final UsuarioRepository usuarioRepository;
    private static final java.time.Duration ACTIVE_SESSION_TIMEOUT = java.time.Duration.ofMinutes(15);
    private static final Set<com.ufsm.projeto_integrador.sync.enums.SyncActionType> ALLOWED_OFFLINE_PHASE_ONE_ACTIONS =
            Set.of(
                    com.ufsm.projeto_integrador.sync.enums.SyncActionType.CREATE_VISITA,
                    com.ufsm.projeto_integrador.sync.enums.SyncActionType.UPDATE_VISITA,
                    com.ufsm.projeto_integrador.sync.enums.SyncActionType.FINALIZE_VISITA,
                    com.ufsm.projeto_integrador.sync.enums.SyncActionType.CONCLUDE_ENCAMINHAMENTO
            );
    private static final List<SyncSessionStatus> ACTIVE_SESSION_STATUSES = List.copyOf(
            EnumSet.of(
                    SyncSessionStatus.STARTED,
                    SyncSessionStatus.PROCESSING_OPERATIONS,
                    SyncSessionStatus.PULLING_SERVER_CHANGES
            )
    );

    public SyncResponse synchronize(SyncRequest request) {
        Long userId = SecurityUtils.getCurrentUserId();
        SyncRuntimeContext context = new SyncRuntimeContext(userId, request.deviceId());
        SyncSession session = createSession(userId, request);

        List<SyncOperationRequest> originalOperations = request.operations() == null
                ? List.of()
                : request.operations();
        BatchPreparation preparation = prepareOperations(originalOperations);
        List<SyncOperationRequest> operations = preparation.orderedOperations();
        Map<SyncOperationRequest, SyncOperationResult> resultsByOperation = new IdentityHashMap<>();
        Map<String, SyncOperationResult> processed = new HashMap<>();

        session.setStatus(SyncSessionStatus.PROCESSING_OPERATIONS);
        sessionRepository.save(session);

        SyncSessionStatus finalStatus = SyncSessionStatus.COMPLETED;
        String terminalMessage = null;
        int abortFromIndex = -1;

        if (preparation.failure() != null) {
            SyncOperationRequest failedOperation = preparation.failure().offendingOperation();
            SyncOperationResult failed = operationExecutor.recordFailure(
                    session,
                    failedOperation,
                    preparation.failure().code(),
                    preparation.failure().message()
            );
            resultsByOperation.put(failedOperation, failed);
            processed.put(failed.operationId(), failed);
            finalStatus = failed.status() == SyncOperationStatus.CONFLICT
                    ? SyncSessionStatus.CONFLICT
                    : SyncSessionStatus.FAILED;
            terminalMessage = failed.message();

            for (SyncOperationRequest operation : originalOperations) {
                if (sameOperation(operation, failedOperation)) {
                    continue;
                }
                SyncOperationResult skipped = operationExecutor.recordSkipped(
                        session,
                        operation,
                        "Operacao nao executada porque o lote de sync foi invalidado"
                );
                resultsByOperation.put(operation, skipped);
                processed.put(skipped.operationId(), skipped);
            }
        } else {
            for (int i = 0; i < operations.size(); i++) {
                SyncOperationRequest operation = operations.get(i);
                String dependencyMessage = findDependencyIssue(operation, processed);
                if (dependencyMessage != null) {
                    SyncOperationResult failed = operationExecutor.recordFailure(
                            session,
                            operation,
                            SyncErrorCode.DEPENDENCY_MISSING,
                            dependencyMessage
                    );
                    resultsByOperation.put(operation, failed);
                    processed.put(operation.operationId(), failed);
                    finalStatus = SyncSessionStatus.FAILED;
                    terminalMessage = dependencyMessage;
                    abortFromIndex = i + 1;
                    break;
                }

                SyncOperationResult result = operationExecutor.execute(session, operation, context);
                resultsByOperation.put(operation, result);
                processed.put(operation.operationId(), result);

                if (result.status() == SyncOperationStatus.APPLIED && result.serverId() != null) {
                    context.registerMapping(operation.entityType(), operation.localId(), result.serverId());
                }

                if (result.status() == SyncOperationStatus.CONFLICT || result.status() == SyncOperationStatus.FAILED) {
                    finalStatus = result.status() == SyncOperationStatus.CONFLICT
                            ? SyncSessionStatus.CONFLICT
                            : SyncSessionStatus.FAILED;
                    terminalMessage = result.message();
                    abortFromIndex = i + 1;
                    break;
                }
            }

            if (abortFromIndex >= 0) {
                for (int i = abortFromIndex; i < operations.size(); i++) {
                    SyncOperationResult skipped = operationExecutor.recordSkipped(
                            session,
                            operations.get(i),
                            "Operacao nao executada porque a sessao de sync foi interrompida"
                    );
                    resultsByOperation.put(operations.get(i), skipped);
                    processed.put(skipped.operationId(), skipped);
                }
            }
        }

        List<SyncServerChange> serverChanges = List.of();
        Long nextSyncToken = request.lastSyncToken() == null ? 0L : request.lastSyncToken();

        if (finalStatus == SyncSessionStatus.COMPLETED) {
            session.setStatus(SyncSessionStatus.PULLING_SERVER_CHANGES);
            sessionRepository.save(session);

            serverChanges = changeService.fetchVisibleChangesAfter(request.lastSyncToken(), userId);
            if (!serverChanges.isEmpty()) {
                nextSyncToken = serverChanges.get(serverChanges.size() - 1).changeToken();
            }
            changeService.updateDeviceState(
                    userId,
                    request.deviceId(),
                    nextSyncToken,
                    session.getId(),
                    request.appVersion()
            );
        }

        LocalDateTime finishedAt = LocalDateTime.now();
        session.setStatus(finalStatus);
        session.setFinishedAt(finishedAt);
        session.setServerTime(finishedAt);
        session.setErrorType(finalStatus == SyncSessionStatus.COMPLETED ? null : finalStatus.name());
        session.setErrorMessage(finalStatus == SyncSessionStatus.COMPLETED ? null : terminalMessage);
        sessionRepository.save(session);

        List<SyncOperationResult> orderedResults = orderResultsByOriginalRequest(
                originalOperations,
                resultsByOperation
        );

        return new SyncResponse(
                session.getId(),
                session.getStatus(),
                true,
                nextSyncToken,
                finishedAt,
                orderedResults,
                serverChanges
        );
    }

    private SyncSession createSession(Long userId, SyncRequest request) {
        LocalDateTime now = LocalDateTime.now();
        sessionRepository.expireStaleSessions(
                userId,
                request.deviceId(),
                ACTIVE_SESSION_STATUSES,
                now.minus(ACTIVE_SESSION_TIMEOUT),
                SyncSessionStatus.FAILED,
                now,
                SyncSessionStatus.FAILED.name(),
                "Sessao anterior expirada antes de concluir o sync"
        );

        if (sessionRepository.existsByUsuarioIdAndDeviceIdAndStatusIn(
                userId,
                request.deviceId(),
                ACTIVE_SESSION_STATUSES
        )) {
            throw new BusinessException("Ja existe uma sincronizacao em andamento para este dispositivo");
        }

        try {
            return sessionRepository.save(
                    SyncSession.builder()
                            .id(UUID.randomUUID())
                            .usuario(usuarioRepository.getReferenceById(userId))
                            .deviceId(request.deviceId())
                            .status(SyncSessionStatus.STARTED)
                            .lastSyncToken(request.lastSyncToken())
                            .build()
            );
        } catch (DataIntegrityViolationException ex) {
            throw new BusinessException("Ja existe uma sincronizacao em andamento para este dispositivo");
        }
    }

    private String findDependencyIssue(
            SyncOperationRequest operation,
            Map<String, SyncOperationResult> processed
    ) {
        if (operation.dependsOn() == null || operation.dependsOn().isEmpty()) {
            return null;
        }

        for (String dependency : operation.dependsOn()) {
            SyncOperationResult previous = processed.get(dependency);
            if (previous == null) {
                return "Dependencia de sync ainda nao foi processada: " + dependency;
            }
            if (previous.status() != SyncOperationStatus.APPLIED) {
                return "Dependencia de sync falhou anteriormente: " + dependency;
            }
        }
        return null;
    }

    private BatchPreparation prepareOperations(List<SyncOperationRequest> operations) {
        if (operations.isEmpty()) {
            return new BatchPreparation(operations, null);
        }

        Map<String, SyncOperationRequest> operationsById = new LinkedHashMap<>();
        for (SyncOperationRequest operation : operations) {
            if (!ALLOWED_OFFLINE_PHASE_ONE_ACTIONS.contains(operation.action())) {
                return new BatchPreparation(
                        operations,
                        new BatchFailure(
                                operation,
                                SyncErrorCode.UNSUPPORTED_ACTION,
                                "Acao de sync disponivel apenas online nesta fase: " + operation.action().name()
                        )
                );
            }

            if (!operationsById.containsKey(operation.operationId())) {
                operationsById.put(operation.operationId(), operation);
                continue;
            }

            return new BatchPreparation(
                    operations,
                    new BatchFailure(
                            operation,
                            SyncErrorCode.VALIDATION_ERROR,
                            "operationId duplicado no mesmo lote: " + operation.operationId()
                    )
            );
        }

        Map<String, Set<String>> outgoing = new LinkedHashMap<>();
        Map<String, Integer> indegree = new LinkedHashMap<>();
        operationsById.keySet().forEach(operationId -> {
            outgoing.put(operationId, new LinkedHashSet<>());
            indegree.put(operationId, 0);
        });

        for (SyncOperationRequest operation : operations) {
            List<String> dependencies = operation.dependsOn();
            if (dependencies == null || dependencies.isEmpty()) {
                continue;
            }

            Set<String> uniqueDependencies = new LinkedHashSet<>(dependencies);
            for (String dependency : uniqueDependencies) {
                if (dependency == null || dependency.isBlank()) {
                    return new BatchPreparation(
                            operations,
                            new BatchFailure(
                                    operation,
                                    SyncErrorCode.VALIDATION_ERROR,
                                    "A operacao possui dependencia de sync vazia"
                            )
                    );
                }
                if (!operationsById.containsKey(dependency)) {
                    return new BatchPreparation(
                            operations,
                            new BatchFailure(
                                    operation,
                                    SyncErrorCode.DEPENDENCY_MISSING,
                                    "Dependencia de sync nao existe no lote: " + dependency
                            )
                    );
                }
                if (dependency.equals(operation.operationId())) {
                    return new BatchPreparation(
                            operations,
                            new BatchFailure(
                                    operation,
                                    SyncErrorCode.VALIDATION_ERROR,
                                    "A operacao nao pode depender dela mesma: " + dependency
                            )
                    );
                }
                if (outgoing.get(dependency).add(operation.operationId())) {
                    indegree.put(operation.operationId(), indegree.get(operation.operationId()) + 1);
                }
            }
        }

        ArrayDeque<String> ready = new ArrayDeque<>();
        operations.stream()
                .map(SyncOperationRequest::operationId)
                .filter(operationId -> indegree.get(operationId) == 0)
                .forEach(ready::addLast);

        List<SyncOperationRequest> ordered = new ArrayList<>(operations.size());
        while (!ready.isEmpty()) {
            String operationId = ready.removeFirst();
            ordered.add(operationsById.get(operationId));
            for (String dependent : outgoing.get(operationId)) {
                int nextIndegree = indegree.get(dependent) - 1;
                indegree.put(dependent, nextIndegree);
                if (nextIndegree == 0) {
                    ready.addLast(dependent);
                }
            }
        }

        if (ordered.size() != operations.size()) {
            Set<String> processed = new HashSet<>();
            ordered.stream().map(SyncOperationRequest::operationId).forEach(processed::add);
            SyncOperationRequest cyclic = operations.stream()
                    .filter(operation -> !processed.contains(operation.operationId()))
                    .findFirst()
                    .orElse(operations.getFirst());

            return new BatchPreparation(
                    operations,
                    new BatchFailure(
                            cyclic,
                            SyncErrorCode.VALIDATION_ERROR,
                            "Dependencias ciclicas detectadas no lote de sync"
                    )
            );
        }

        return new BatchPreparation(ordered, null);
    }

    private List<SyncOperationResult> orderResultsByOriginalRequest(
            List<SyncOperationRequest> originalOperations,
            Map<SyncOperationRequest, SyncOperationResult> resultsByOperation
    ) {
        if (originalOperations.isEmpty()) {
            return List.of();
        }

        return originalOperations.stream()
                .map(resultsByOperation::get)
                .filter(Objects::nonNull)
                .toList();
    }

    private boolean sameOperation(SyncOperationRequest left, SyncOperationRequest right) {
        return left == right;
    }

    private record BatchPreparation(
            List<SyncOperationRequest> orderedOperations,
            BatchFailure failure
    ) {
    }

    private record BatchFailure(
            SyncOperationRequest offendingOperation,
            SyncErrorCode code,
            String message
    ) {
    }
}
