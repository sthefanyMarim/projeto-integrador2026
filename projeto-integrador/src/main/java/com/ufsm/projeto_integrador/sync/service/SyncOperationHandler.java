package com.ufsm.projeto_integrador.sync.service;

import com.ufsm.projeto_integrador.sync.dto.SyncOperationRequest;
import com.ufsm.projeto_integrador.sync.dto.SyncOperationResult;

public interface SyncOperationHandler {

    boolean supports(SyncOperationRequest request);

    SyncOperationResult handle(SyncOperationRequest request, SyncRuntimeContext context);
}
