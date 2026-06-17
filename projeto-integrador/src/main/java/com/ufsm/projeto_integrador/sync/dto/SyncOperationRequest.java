package com.ufsm.projeto_integrador.sync.dto;

import com.ufsm.projeto_integrador.sync.enums.SyncActionType;
import com.ufsm.projeto_integrador.sync.enums.SyncEntityType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import tools.jackson.databind.JsonNode;

import java.util.List;

public record SyncOperationRequest(
        @NotBlank(message = "operationId obrigatorio") String operationId,
        @NotNull(message = "entityType obrigatorio") SyncEntityType entityType,
        @NotNull(message = "action obrigatoria") SyncActionType action,
        String localId,
        Long serverId,
        Long baseVersion,
        List<String> dependsOn,
        JsonNode payload
) {
}
