package com.ufsm.projeto_integrador.sync.service;

import com.ufsm.projeto_integrador.domain.entity.Usuario;
import com.ufsm.projeto_integrador.exception.BusinessException;
import com.ufsm.projeto_integrador.repository.UsuarioRepository;
import com.ufsm.projeto_integrador.security.SecurityUtils;
import com.ufsm.projeto_integrador.sync.domain.entity.SyncSession;
import com.ufsm.projeto_integrador.sync.dto.SyncOperationRequest;
import com.ufsm.projeto_integrador.sync.dto.SyncOperationResult;
import com.ufsm.projeto_integrador.sync.dto.SyncRequest;
import com.ufsm.projeto_integrador.sync.dto.SyncResponse;
import com.ufsm.projeto_integrador.sync.dto.SyncServerChange;
import com.ufsm.projeto_integrador.sync.enums.SyncActionType;
import com.ufsm.projeto_integrador.sync.enums.SyncChangeType;
import com.ufsm.projeto_integrador.sync.enums.SyncEntityType;
import com.ufsm.projeto_integrador.sync.enums.SyncErrorCode;
import com.ufsm.projeto_integrador.sync.enums.SyncOperationStatus;
import com.ufsm.projeto_integrador.sync.enums.SyncSessionStatus;
import com.ufsm.projeto_integrador.sync.repository.SyncSessionRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.InOrder;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;
import tools.jackson.databind.node.NullNode;

import java.time.LocalDateTime;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.inOrder;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class SyncServiceTest {

    @Mock
    private SyncSessionRepository sessionRepository;

    @Mock
    private SyncOperationExecutor operationExecutor;

    @Mock
    private SyncChangeService changeService;

    @Mock
    private UsuarioRepository usuarioRepository;

    @InjectMocks
    private SyncService service;

    @Test
    void synchronizeDeveCompletarSessaoEAtualizarTokenQuandoTodasOperacoesPassarem() {
        Usuario usuario = usuario(10L);
        SyncOperationRequest operacao = operation(
                "op-1",
                SyncEntityType.VISITA,
                SyncActionType.CREATE_VISITA
        );
        SyncOperationResult aplicada = result(
                operacao,
                SyncOperationStatus.APPLIED,
                SyncErrorCode.SUCCESS,
                "Visita sincronizada",
                55L,
                3L
        );
        SyncServerChange change = new SyncServerChange(
                9L,
                SyncEntityType.VISITA,
                55L,
                SyncChangeType.UPSERT,
                3L,
                LocalDateTime.of(2026, 6, 1, 10, 0),
                NullNode.instance
        );

        when(sessionRepository.existsByUsuarioIdAndDeviceIdAndStatusIn(eq(10L), eq("device-1"), any()))
                .thenReturn(false);
        when(sessionRepository.save(any(SyncSession.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(usuarioRepository.getReferenceById(10L)).thenReturn(usuario);
        when(operationExecutor.execute(any(SyncSession.class), eq(operacao), any(SyncRuntimeContext.class)))
                .thenReturn(aplicada);
        when(changeService.fetchVisibleChangesAfter(4L, 10L)).thenReturn(List.of(change));

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentUserId).thenReturn(10L);

            SyncResponse response = service.synchronize(
                    new SyncRequest("device-1", 4L, "1.2.0", List.of(operacao))
            );

            assertNotNull(response.sessionId());
            assertTrue(response.blocking());
            assertEquals(SyncSessionStatus.COMPLETED, response.sessionStatus());
            assertEquals(9L, response.nextSyncToken());
            assertEquals(1, response.operationResults().size());
            assertEquals(SyncOperationStatus.APPLIED, response.operationResults().get(0).status());
            assertEquals(1, response.serverChanges().size());

            verify(sessionRepository).expireStaleSessions(eq(10L), eq("device-1"), any(), any(), eq(SyncSessionStatus.FAILED), any(), eq("FAILED"), eq("Sessao anterior expirada antes de concluir o sync"));
            verify(changeService).updateDeviceState(10L, "device-1", 9L, response.sessionId(), "1.2.0");
        }
    }

    @Test
    void synchronizeDeveOrdenarOperacoesPorDependenciaMesmoQuandoLoteVierForaDeOrdem() {
        Usuario usuario = usuario(15L);
        SyncOperationRequest base = operation(
                "op-1",
                SyncEntityType.VISITA,
                SyncActionType.CREATE_VISITA
        );
        SyncOperationRequest dependente = new SyncOperationRequest(
                "op-2",
                SyncEntityType.VISITA,
                SyncActionType.UPDATE_VISITA,
                "visita-local-1",
                null,
                null,
                List.of("op-1"),
                NullNode.instance
        );

        when(sessionRepository.existsByUsuarioIdAndDeviceIdAndStatusIn(eq(15L), eq("device-2"), any()))
                .thenReturn(false);
        when(sessionRepository.save(any(SyncSession.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(usuarioRepository.getReferenceById(15L)).thenReturn(usuario);
        when(operationExecutor.execute(any(SyncSession.class), eq(base), any(SyncRuntimeContext.class)))
                .thenReturn(result(
                        base,
                        SyncOperationStatus.APPLIED,
                        SyncErrorCode.SUCCESS,
                        "Criada",
                        20L,
                        1L
                ));
        when(operationExecutor.execute(any(SyncSession.class), eq(dependente), any(SyncRuntimeContext.class)))
                .thenReturn(result(
                        dependente,
                        SyncOperationStatus.APPLIED,
                        SyncErrorCode.SUCCESS,
                        "Visita sincronizada",
                        99L,
                        3L
                ));
        when(changeService.fetchVisibleChangesAfter(7L, 15L)).thenReturn(List.of());

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentUserId).thenReturn(15L);

            SyncResponse response = service.synchronize(
                    new SyncRequest("device-2", 7L, "1.2.0", List.of(dependente, base))
            );

            assertEquals(SyncSessionStatus.COMPLETED, response.sessionStatus());
            assertEquals(2, response.operationResults().size());
            assertEquals(SyncOperationStatus.APPLIED, response.operationResults().get(0).status());
            assertEquals(SyncOperationStatus.APPLIED, response.operationResults().get(1).status());

            InOrder inOrder = inOrder(operationExecutor);
            inOrder.verify(operationExecutor).execute(any(SyncSession.class), eq(base), any(SyncRuntimeContext.class));
            inOrder.verify(operationExecutor).execute(any(SyncSession.class), eq(dependente), any(SyncRuntimeContext.class));
        }
    }

    @Test
    void synchronizeDevePararNoConflitoESinalizarItensRestantesComoSkipped() {
        Usuario usuario = usuario(21L);
        SyncOperationRequest primeira = operation(
                "op-1",
                SyncEntityType.VISITA,
                SyncActionType.CREATE_VISITA
        );
        SyncOperationRequest conflito = operation(
                "op-2",
                SyncEntityType.VISITA,
                SyncActionType.UPDATE_VISITA
        );
        SyncOperationRequest restante = operation(
                "op-3",
                SyncEntityType.ENCAMINHAMENTO,
                SyncActionType.CONCLUDE_ENCAMINHAMENTO
        );

        when(sessionRepository.existsByUsuarioIdAndDeviceIdAndStatusIn(eq(21L), eq("device-3"), any()))
                .thenReturn(false);
        when(sessionRepository.save(any(SyncSession.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(usuarioRepository.getReferenceById(21L)).thenReturn(usuario);
        when(operationExecutor.execute(any(SyncSession.class), eq(primeira), any(SyncRuntimeContext.class)))
                .thenReturn(result(primeira, SyncOperationStatus.APPLIED, SyncErrorCode.SUCCESS, "Criada", 31L, 2L));
        when(operationExecutor.execute(any(SyncSession.class), eq(conflito), any(SyncRuntimeContext.class)))
                .thenReturn(result(
                        conflito,
                        SyncOperationStatus.CONFLICT,
                        SyncErrorCode.VERSION_CONFLICT,
                        "A visita foi alterada no servidor",
                        44L,
                        8L
                ));
        when(operationExecutor.recordSkipped(any(SyncSession.class), eq(restante),
                eq("Operacao nao executada porque a sessao de sync foi interrompida")))
                .thenReturn(result(
                        restante,
                        SyncOperationStatus.SKIPPED,
                        SyncErrorCode.SESSION_ABORTED,
                        "Operacao nao executada porque a sessao de sync foi interrompida",
                        null,
                        null
                ));

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentUserId).thenReturn(21L);

            SyncResponse response = service.synchronize(
                    new SyncRequest("device-3", 11L, "1.2.0", List.of(primeira, conflito, restante))
            );

            assertEquals(SyncSessionStatus.CONFLICT, response.sessionStatus());
            assertEquals(3, response.operationResults().size());
            assertEquals(SyncOperationStatus.CONFLICT, response.operationResults().get(1).status());
            assertEquals(SyncOperationStatus.SKIPPED, response.operationResults().get(2).status());

            verify(changeService, never()).fetchVisibleChangesAfter(any(), any());
            verify(changeService, never()).updateDeviceState(any(), any(), any(), any(), any());
        }
    }

    @Test
    void synchronizeDeveInvalidarLoteQuandoOperationIdEstiverDuplicado() {
        Usuario usuario = usuario(30L);
        SyncOperationRequest primeira = operation(
                "op-repetida",
                SyncEntityType.VISITA,
                SyncActionType.CREATE_VISITA
        );
        SyncOperationRequest duplicada = operation(
                "op-repetida",
                SyncEntityType.VISITA,
                SyncActionType.UPDATE_VISITA
        );
        SyncOperationRequest terceira = operation(
                "op-3",
                SyncEntityType.ENCAMINHAMENTO,
                SyncActionType.CONCLUDE_ENCAMINHAMENTO
        );

        when(sessionRepository.existsByUsuarioIdAndDeviceIdAndStatusIn(eq(30L), eq("device-4"), any()))
                .thenReturn(false);
        when(sessionRepository.save(any(SyncSession.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(usuarioRepository.getReferenceById(30L)).thenReturn(usuario);
        when(operationExecutor.recordFailure(any(SyncSession.class), eq(duplicada),
                eq(SyncErrorCode.VALIDATION_ERROR), eq("operationId duplicado no mesmo lote: op-repetida")))
                .thenReturn(result(
                        duplicada,
                        SyncOperationStatus.FAILED,
                        SyncErrorCode.VALIDATION_ERROR,
                        "operationId duplicado no mesmo lote: op-repetida",
                        null,
                        null
                ));
        when(operationExecutor.recordSkipped(any(SyncSession.class), eq(primeira),
                eq("Operacao nao executada porque o lote de sync foi invalidado")))
                .thenReturn(result(
                        primeira,
                        SyncOperationStatus.SKIPPED,
                        SyncErrorCode.SESSION_ABORTED,
                        "Operacao nao executada porque o lote de sync foi invalidado",
                        null,
                        null
                ));
        when(operationExecutor.recordSkipped(any(SyncSession.class), eq(terceira),
                eq("Operacao nao executada porque o lote de sync foi invalidado")))
                .thenReturn(result(
                        terceira,
                        SyncOperationStatus.SKIPPED,
                        SyncErrorCode.SESSION_ABORTED,
                        "Operacao nao executada porque o lote de sync foi invalidado",
                        null,
                        null
                ));

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentUserId).thenReturn(30L);

            SyncResponse response = service.synchronize(
                    new SyncRequest("device-4", 0L, "1.2.0", List.of(primeira, duplicada, terceira))
            );

            assertEquals(SyncSessionStatus.FAILED, response.sessionStatus());
            assertEquals(3, response.operationResults().size());
            assertEquals(SyncOperationStatus.SKIPPED, response.operationResults().get(0).status());
            assertEquals(SyncOperationStatus.FAILED, response.operationResults().get(1).status());
            assertEquals(SyncOperationStatus.SKIPPED, response.operationResults().get(2).status());

            verifyNoInteractions(changeService);
            verify(operationExecutor, never()).execute(any(), any(), any());
        }
    }

    @Test
    void synchronizeDeveBloquearNovaSessaoQuandoJaExistirSyncAtivoNoDispositivo() {
        when(sessionRepository.existsByUsuarioIdAndDeviceIdAndStatusIn(eq(40L), eq("device-5"), any()))
                .thenReturn(true);

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentUserId).thenReturn(40L);

            BusinessException ex = assertThrows(
                    BusinessException.class,
                    () -> service.synchronize(new SyncRequest("device-5", 3L, "1.2.0", List.of()))
            );

            assertEquals(
                    "Ja existe uma sincronizacao em andamento para este dispositivo",
                    ex.getMessage()
            );
            verify(sessionRepository).expireStaleSessions(eq(40L), eq("device-5"), any(), any(), eq(SyncSessionStatus.FAILED), any(), eq("FAILED"), eq("Sessao anterior expirada antes de concluir o sync"));
            verifyNoInteractions(operationExecutor, changeService, usuarioRepository);
        }
    }

    @Test
    void synchronizeDeveRejeitarAcaoForaDaPoliticaOfflineDaFaseUm() {
        Usuario usuario = usuario(50L);
        SyncOperationRequest proibida = operation(
                "op-bloqueada",
                SyncEntityType.PROPRIEDADE,
                SyncActionType.UPDATE_PROPRIEDADE
        );

        when(sessionRepository.existsByUsuarioIdAndDeviceIdAndStatusIn(eq(50L), eq("device-6"), any()))
                .thenReturn(false);
        when(sessionRepository.save(any(SyncSession.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(usuarioRepository.getReferenceById(50L)).thenReturn(usuario);
        when(operationExecutor.recordFailure(any(SyncSession.class), eq(proibida),
                eq(SyncErrorCode.UNSUPPORTED_ACTION),
                eq("Acao de sync disponivel apenas online nesta fase: UPDATE_PROPRIEDADE")))
                .thenReturn(result(
                        proibida,
                        SyncOperationStatus.FAILED,
                        SyncErrorCode.UNSUPPORTED_ACTION,
                        "Acao de sync disponivel apenas online nesta fase: UPDATE_PROPRIEDADE",
                        null,
                        null
                ));

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentUserId).thenReturn(50L);

            SyncResponse response = service.synchronize(
                    new SyncRequest("device-6", 0L, "1.2.0", List.of(proibida))
            );

            assertEquals(SyncSessionStatus.FAILED, response.sessionStatus());
            assertEquals(1, response.operationResults().size());
            assertEquals(SyncOperationStatus.FAILED, response.operationResults().get(0).status());
            assertEquals(SyncErrorCode.UNSUPPORTED_ACTION, response.operationResults().get(0).code());

            verify(operationExecutor, never()).execute(any(), any(), any());
            verifyNoInteractions(changeService);
        }
    }

    private SyncOperationRequest operation(
            String operationId,
            SyncEntityType entityType,
            SyncActionType actionType
    ) {
        return new SyncOperationRequest(
                operationId,
                entityType,
                actionType,
                "local-" + operationId,
                null,
                null,
                null,
                NullNode.instance
        );
    }

    private SyncOperationResult result(
            SyncOperationRequest request,
            SyncOperationStatus status,
            SyncErrorCode code,
            String message,
            Long serverId,
            Long version
    ) {
        return new SyncOperationResult(
                request.operationId(),
                request.entityType(),
                request.action(),
                request.localId(),
                serverId,
                version,
                status,
                code,
                message,
                NullNode.instance
        );
    }

    private Usuario usuario(Long id) {
        Usuario usuario = new Usuario();
        usuario.setId(id);
        usuario.setNome("Usuario Sync");
        return usuario;
    }
}
