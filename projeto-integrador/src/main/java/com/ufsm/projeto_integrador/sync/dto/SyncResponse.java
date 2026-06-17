package com.ufsm.projeto_integrador.sync.dto;

import com.ufsm.projeto_integrador.sync.enums.SyncSessionStatus;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

public record SyncResponse(
        UUID sessionId,
        SyncSessionStatus sessionStatus,
        boolean blocking,
        Long nextSyncToken,
        LocalDateTime serverTime,
        List<SyncOperationResult> operationResults,
        List<SyncServerChange> serverChanges
) {
}
