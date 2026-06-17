package com.ufsm.projeto_integrador.sync.service;

import com.ufsm.projeto_integrador.domain.entity.Encaminhamento;
import com.ufsm.projeto_integrador.domain.entity.Propriedade;
import com.ufsm.projeto_integrador.domain.entity.Usuario;
import com.ufsm.projeto_integrador.domain.entity.VisitaTecnica;
import com.ufsm.projeto_integrador.domain.enums.StatusEncaminhamento;
import com.ufsm.projeto_integrador.repository.EncaminhamentoRepository;
import com.ufsm.projeto_integrador.service.EncaminhamentoService;
import com.ufsm.projeto_integrador.sync.dto.SyncOperationRequest;
import com.ufsm.projeto_integrador.sync.dto.SyncOperationResult;
import com.ufsm.projeto_integrador.sync.enums.SyncActionType;
import com.ufsm.projeto_integrador.sync.enums.SyncEntityType;
import com.ufsm.projeto_integrador.sync.enums.SyncErrorCode;
import com.ufsm.projeto_integrador.sync.enums.SyncOperationStatus;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import tools.jackson.databind.ObjectMapper;
import tools.jackson.databind.json.JsonMapper;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class EncaminhamentoSyncHandlerTest {

    @Mock
    private EncaminhamentoService encaminhamentoService;

    @Mock
    private EncaminhamentoRepository encaminhamentoRepository;

    private EncaminhamentoSyncHandler handler;

    @BeforeEach
    void setUp() {
        ObjectMapper objectMapper = JsonMapper.builder()
                .findAndAddModules()
                .build();
        handler = new EncaminhamentoSyncHandler(
                encaminhamentoService,
                encaminhamentoRepository,
                new SyncPayloadMapper(objectMapper, TestValidatorFactory.validator())
        );
    }

    @Test
    void concluirDeveRetornarConflitoQuandoEncaminhamentoJaEstiverCancelado() {
        Encaminhamento atual = encaminhamento(12L, StatusEncaminhamento.CANCELADO, 9L);
        SyncOperationRequest request = new SyncOperationRequest(
                "op-enc-1",
                SyncEntityType.ENCAMINHAMENTO,
                SyncActionType.CONCLUDE_ENCAMINHAMENTO,
                "enc-local-1",
                12L,
                null,
                null,
                null
        );

        when(encaminhamentoRepository.findById(12L)).thenReturn(Optional.of(atual));

        SyncProcessException ex = assertThrows(
                SyncProcessException.class,
                () -> handler.handle(request, new SyncRuntimeContext(1L, "device-1"))
        );

        assertEquals(SyncOperationStatus.CONFLICT, ex.getStatus());
        assertEquals(SyncErrorCode.STATE_CONFLICT, ex.getCode());
        verifyNoInteractions(encaminhamentoService);
    }

    @Test
    void cancelarDeveSerIdempotenteQuandoEncaminhamentoJaEstiverCancelado() {
        Encaminhamento atual = encaminhamento(18L, StatusEncaminhamento.CANCELADO, 4L);
        SyncOperationRequest request = new SyncOperationRequest(
                "op-enc-2",
                SyncEntityType.ENCAMINHAMENTO,
                SyncActionType.CANCEL_ENCAMINHAMENTO,
                "enc-local-2",
                18L,
                null,
                null,
                null
        );

        when(encaminhamentoRepository.findById(18L)).thenReturn(Optional.of(atual));

        SyncOperationResult result = handler.handle(request, new SyncRuntimeContext(1L, "device-1"));

        assertEquals(SyncOperationStatus.APPLIED, result.status());
        assertEquals(SyncErrorCode.SUCCESS, result.code());
        assertEquals("Encaminhamento ja estava cancelado", result.message());
        verifyNoInteractions(encaminhamentoService);
    }

    private Encaminhamento encaminhamento(Long id, StatusEncaminhamento status, Long version) {
        Usuario usuario = new Usuario();
        usuario.setId(3L);
        usuario.setNome("Tecnico");

        Propriedade propriedade = Propriedade.builder()
                .id(4L)
                .nome("Propriedade")
                .nomeProprietario("Produtor")
                .build();

        VisitaTecnica visita = VisitaTecnica.builder()
                .id(5L)
                .usuario(usuario)
                .propriedade(propriedade)
                .build();

        return Encaminhamento.builder()
                .id(id)
                .visita(visita)
                .acaoRealizada("Acao")
                .status(status)
                .version(version)
                .build();
    }
}
