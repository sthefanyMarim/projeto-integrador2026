package com.ufsm.projeto_integrador.sync.dto;

import com.ufsm.projeto_integrador.sync.enums.SyncChangeType;
import com.ufsm.projeto_integrador.sync.enums.SyncEntityType;
import tools.jackson.databind.JsonNode;

import java.time.LocalDateTime;

public record SyncServerChange(
        Long changeToken,
        SyncEntityType entityType,
        Long entityId,
        SyncChangeType changeType,
        Long entityVersion,
        LocalDateTime changedAt,
        JsonNode snapshot
) {
}
