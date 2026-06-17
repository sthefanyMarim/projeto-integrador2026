package com.ufsm.projeto_integrador.sync.service;

import com.ufsm.projeto_integrador.exception.BusinessException;
import com.ufsm.projeto_integrador.domain.dto.propriedade.PropriedadeRequest;
import com.ufsm.projeto_integrador.domain.entity.Propriedade;
import com.ufsm.projeto_integrador.repository.PropriedadeRepository;
import com.ufsm.projeto_integrador.service.PropriedadeService;
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
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class PropriedadeSyncHandlerTest {

    @Mock
    private PropriedadeService propriedadeService;

    @Mock
    private PropriedadeRepository propriedadeRepository;

    private PropriedadeSyncHandler handler;
    private ObjectMapper objectMapper;

    @BeforeEach
    void setUp() {
        objectMapper = JsonMapper.builder()
                .findAndAddModules()
                .build();
        handler = new PropriedadeSyncHandler(
                propriedadeService,
                propriedadeRepository,
                new SyncPayloadMapper(objectMapper, TestValidatorFactory.validator())
        );
    }

    @Test
    void atualizarDeveRetornarConflitoQuandoVersaoBaseDivergir() {
        Propriedade atual = propriedade(9L, 4L);
        SyncOperationRequest request = new SyncOperationRequest(
                "op-prop-1",
                SyncEntityType.PROPRIEDADE,
                SyncActionType.UPDATE_PROPRIEDADE,
                "prop-local-1",
                9L,
                3L,
                null,
                objectMapper.valueToTree(payload())
        );

        when(propriedadeRepository.findById(9L)).thenReturn(Optional.of(atual));

        SyncProcessException ex = assertThrows(
                SyncProcessException.class,
                () -> handler.handle(request, new SyncRuntimeContext(1L, "device-1"))
        );

        assertEquals(SyncOperationStatus.CONFLICT, ex.getStatus());
        assertEquals(SyncErrorCode.VERSION_CONFLICT, ex.getCode());
        verifyNoInteractions(propriedadeService);
    }

    @Test
    void deletarDeveResolverIdDoServidorAPartirDoMapeamentoLocal() {
        Propriedade atual = propriedade(22L, 8L);
        SyncRuntimeContext context = new SyncRuntimeContext(1L, "device-1");
        context.registerMapping(SyncEntityType.PROPRIEDADE, "prop-local-2", 22L);
        SyncOperationRequest request = new SyncOperationRequest(
                "op-prop-2",
                SyncEntityType.PROPRIEDADE,
                SyncActionType.DELETE_PROPRIEDADE,
                "prop-local-2",
                null,
                8L,
                null,
                null
        );

        when(propriedadeRepository.findById(22L)).thenReturn(Optional.of(atual));

        SyncOperationResult result = handler.handle(request, context);

        assertEquals(SyncOperationStatus.APPLIED, result.status());
        assertEquals(22L, result.serverId());
        assertEquals("Propriedade removida", result.message());
        verify(propriedadeService).deletar(22L);
    }

    @Test
    void criarDeveValidarPayloadAntesDeChamarServico() {
        SyncOperationRequest request = new SyncOperationRequest(
                "op-prop-3",
                SyncEntityType.PROPRIEDADE,
                SyncActionType.CREATE_PROPRIEDADE,
                "prop-local-3",
                null,
                null,
                null,
                objectMapper.valueToTree(Map.of("nome", "Propriedade sem dono"))
        );

        BusinessException ex = assertThrows(
                BusinessException.class,
                () -> handler.handle(request, new SyncRuntimeContext(1L, "device-1"))
        );

        assertTrue(ex.getMessage().contains("Payload de sync invalido para PropriedadeRequest"));
        assertTrue(ex.getMessage().contains("nomeProprietario"));
        verifyNoInteractions(propriedadeService);
    }

    private PropriedadeRequest payload() {
        return new PropriedadeRequest(
                "Propriedade Teste",
                "Produtor Teste",
                "55999999999",
                "Linha 1",
                "Santa Maria",
                "RS",
                null,
                null,
                "Leite",
                true
        );
    }

    private Propriedade propriedade(Long id, Long version) {
        return Propriedade.builder()
                .id(id)
                .nome("Propriedade Teste")
                .nomeProprietario("Produtor Teste")
                .version(version)
                .build();
    }
}
