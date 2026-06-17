package com.ufsm.projeto_integrador.sync.enums;

public enum SyncErrorCode {
    SUCCESS,
    VERSION_CONFLICT,
    STATE_CONFLICT,
    DEPENDENCY_MISSING,
    VALIDATION_ERROR,
    NOT_FOUND,
    FORBIDDEN,
    ATTACHMENT_NOT_READY,
    UNSUPPORTED_ACTION,
    SESSION_ABORTED,
    ALREADY_APPLIED,
    INTERNAL_ERROR;

    public boolean isConflict() {
        return this == VERSION_CONFLICT || this == STATE_CONFLICT;
    }
}
