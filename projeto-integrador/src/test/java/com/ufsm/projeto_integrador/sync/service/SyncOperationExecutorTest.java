package com.ufsm.projeto_integrador.sync.service;

import com.ufsm.projeto_integrador.domain.entity.Usuario;
import com.ufsm.projeto_integrador.exception.BusinessException;
import com.ufsm.projeto_integrador.sync.domain.entity.SyncOperationLog;
import com.ufsm.projeto_integrador.sync.domain.entity.SyncSession;
import com.ufsm.projeto_integrador.sync.dto.SyncOperationRequest;
import com.ufsm.projeto_integrador.sync.dto.SyncOperationResult;
import com.ufsm.projeto_integrador.sync.enums.SyncActionType;
import com.ufsm.projeto_integrador.sync.enums.SyncEntityType;
import com.ufsm.projeto_integrador.sync.enums.SyncErrorCode;
import com.ufsm.projeto_integrador.sync.enums.SyncOperationStatus;
import com.ufsm.projeto_integrador.sync.repository.SyncOperationLogRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import tools.jackson.databind.ObjectMapper;
import tools.jackson.databind.json.JsonMapper;
import tools.jackson.databind.node.NullNode;

import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class SyncOperationExecutorTest {

    @Mock
    private SyncOperationHandler handler;

    @Mock
    private SyncOperationLogRepository operationLogRepository;

    private SyncOperationExecutor executor;

    @BeforeEach
    void setUp() {
        ObjectMapper objectMapper = JsonMapper.builder()
                .findAndAddModules()
                .build();
        executor = new SyncOperationExecutor(
                List.of(handler),
                operationLogRepository,
                new SyncPayloadMapper(objectMapper, TestValidatorFactory.validator()),
                new TestTransactionManager()
        );
    }

    @Test
    void executeDeveReaproveitarResultadoJaPersistidoQuandoOperationIdExistir() {
        SyncOperationRequest request = request("op-1");
        SyncOperationLog existente = SyncOperationLog.builder()
                .operationId("op-1")
                .entityType(SyncEntityType.PROPRIEDADE)
                .actionType(SyncActionType.CREATE_PROPRIEDADE)
                .localId("local-op-1")
                .serverId(50L)
                .entityVersion(6L)
                .status(SyncOperationStatus.APPLIED)
                .errorCode(SyncErrorCode.SUCCESS)
                .message("Operacao ja processada")
                .requestPayload("null")
                .responseSnapshot("{\"id\":50}")
                .build();

        when(operationLogRepository.findByUsuarioIdAndDeviceIdAndOperationId(1L, "device-1", "op-1"))
                .thenReturn(Optional.of(existente));

        SyncOperationResult result = executor.execute(session(), request, new SyncRuntimeContext(1L, "device-1"));

        assertEquals(SyncOperationStatus.APPLIED, result.status());
        assertEquals(SyncErrorCode.SUCCESS, result.code());
        assertEquals(50L, result.serverId());
        assertTrue(result.snapshot().has("id"));

        verify(operationLogRepository, never()).save(any(SyncOperationLog.class));
        verifyNoInteractions(handler);
    }

    @Test
    void executeDeveTraduzirBusinessExceptionParaValidationError() {
        SyncOperationRequest request = request("op-2");

        when(operationLogRepository.findByUsuarioIdAndDeviceIdAndOperationId(1L, "device-1", "op-2"))
                .thenReturn(Optional.empty());
        when(handler.supports(request)).thenReturn(true);
        when(handler.handle(eq(request), any(SyncRuntimeContext.class)))
                .thenThrow(new BusinessException("Payload invalido"));

        SyncOperationResult result = executor.execute(session(), request, new SyncRuntimeContext(7L, "device-7"));

        assertEquals(SyncOperationStatus.FAILED, result.status());
        assertEquals(SyncErrorCode.VALIDATION_ERROR, result.code());
        assertEquals("Payload invalido", result.message());

        verify(operationLogRepository).save(any(SyncOperationLog.class));
    }

    @Test
    void executeDeveFalharQuandoOperationIdJaExistirComOutroPayloadNoMesmoDispositivo() {
        SyncOperationRequest request = request("op-3");
        SyncOperationLog existente = SyncOperationLog.builder()
                .operationId("op-3")
                .entityType(SyncEntityType.PROPRIEDADE)
                .actionType(SyncActionType.UPDATE_PROPRIEDADE)
                .localId("local-op-3")
                .requestPayload("{\"nome\":\"Outro\"}")
                .status(SyncOperationStatus.APPLIED)
                .build();

        when(operationLogRepository.findByUsuarioIdAndDeviceIdAndOperationId(1L, "device-1", "op-3"))
                .thenReturn(Optional.of(existente));

        SyncOperationResult result = executor.execute(session(), request, new SyncRuntimeContext(1L, "device-1"));

        assertEquals(SyncOperationStatus.FAILED, result.status());
        assertEquals(SyncErrorCode.VALIDATION_ERROR, result.code());
        assertEquals(
                "operationId ja foi utilizado com outro payload neste dispositivo",
                result.message()
        );

        verify(operationLogRepository, never()).save(any(SyncOperationLog.class));
        verifyNoInteractions(handler);
    }

    private SyncOperationRequest request(String operationId) {
        return new SyncOperationRequest(
                operationId,
                SyncEntityType.PROPRIEDADE,
                SyncActionType.CREATE_PROPRIEDADE,
                "local-" + operationId,
                null,
                null,
                null,
                NullNode.instance
        );
    }

    private SyncSession session() {
        Usuario usuario = new Usuario();
        usuario.setId(1L);

        SyncSession session = new SyncSession();
        session.setUsuario(usuario);
        session.setDeviceId("device-1");
        return session;
    }
}
