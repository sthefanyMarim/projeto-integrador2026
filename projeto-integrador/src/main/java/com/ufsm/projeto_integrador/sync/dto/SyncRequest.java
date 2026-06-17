package com.ufsm.projeto_integrador.sync.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;

import java.util.List;

public record SyncRequest(
        @NotBlank(message = "deviceId obrigatorio") String deviceId,
        Long lastSyncToken,
        String appVersion,
        @Valid List<SyncOperationRequest> operations
) {
}
