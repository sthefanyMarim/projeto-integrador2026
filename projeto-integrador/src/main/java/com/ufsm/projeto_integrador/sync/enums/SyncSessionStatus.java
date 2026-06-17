package com.ufsm.projeto_integrador.sync.enums;

public enum SyncSessionStatus {
    STARTED,
    PROCESSING_OPERATIONS,
    PULLING_SERVER_CHANGES,
    COMPLETED,
    FAILED,
    CONFLICT
}
