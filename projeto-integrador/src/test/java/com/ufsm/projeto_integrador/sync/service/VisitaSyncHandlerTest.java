package com.ufsm.projeto_integrador.sync.service;

import com.ufsm.projeto_integrador.domain.entity.Propriedade;
import com.ufsm.projeto_integrador.domain.entity.Usuario;
import com.ufsm.projeto_integrador.domain.entity.VisitaTecnica;
import com.ufsm.projeto_integrador.domain.enums.Criticidade;
import com.ufsm.projeto_integrador.domain.enums.Prioridade;
import com.ufsm.projeto_integrador.domain.enums.StatusVisita;
import com.ufsm.projeto_integrador.domain.enums.TipoVisita;
import com.ufsm.projeto_integrador.domain.enums.Urgencia;
import com.ufsm.projeto_integrador.domain.enums.Verificacao;
import com.ufsm.projeto_integrador.repository.VisitaTecnicaRepository;
import com.ufsm.projeto_integrador.service.VisitaTecnicaService;
import com.ufsm.projeto_integrador.sync.dto.SyncDiagnosticoPayload;
import com.ufsm.projeto_integrador.sync.dto.SyncEncaminhamentoPayload;
import com.ufsm.projeto_integrador.sync.dto.SyncFinalizarVisitaPayload;
import com.ufsm.projeto_integrador.sync.dto.SyncOperationRequest;
import com.ufsm.projeto_integrador.sync.dto.SyncOperationResult;
import com.ufsm.projeto_integrador.sync.dto.SyncVisitaUpsertPayload;
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

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class VisitaSyncHandlerTest {

    @Mock
    private VisitaTecnicaService visitaTecnicaService;

    @Mock
    private VisitaTecnicaRepository visitaRepository;

    @Mock
    private SyncAttachmentService attachmentService;

    private VisitaSyncHandler handler;
    private ObjectMapper objectMapper;

    @BeforeEach
    void setUp() {
        objectMapper = JsonMapper.builder()
                .findAndAddModules()
                .build();
        handler = new VisitaSyncHandler(
                visitaTecnicaService,
                visitaRepository,
                attachmentService,
                new SyncPayloadMapper(objectMapper, TestValidatorFactory.validator())
        );
    }

    @Test
    void criarDeveFalharQuandoPropriedadeLocalNaoFoiSincronizada() {
        SyncOperationRequest request = new SyncOperationRequest(
                "op-visita-1",
                SyncEntityType.VISITA,
                SyncActionType.CREATE_VISITA,
                "visita-local-1",
                null,
                null,
                null,
                objectMapper.valueToTree(new SyncVisitaUpsertPayload(
                        null,
                        "prop-local-ausente",
                        LocalDate.of(2026, 6, 10),
                        LocalTime.of(9, 0),
                        TipoVisita.DIAGNOSTICO,
                        "Tema",
                        "Observacao",
                        Urgencia.MEDIA
                ))
        );

        SyncProcessException ex = assertThrows(
                SyncProcessException.class,
                () -> handler.handle(request, new SyncRuntimeContext(1L, "device-1"))
        );

        assertEquals(SyncOperationStatus.FAILED, ex.getStatus());
        assertEquals(SyncErrorCode.DEPENDENCY_MISSING, ex.getCode());
        verifyNoInteractions(visitaTecnicaService);
    }

    @Test
    void finalizarDeveDetectarConflitoDeVersaoAntesDePersistir() {
        VisitaTecnica atual = visita(7L, StatusVisita.AGENDADA, 8L);
        SyncOperationRequest request = new SyncOperationRequest(
                "op-visita-2",
                SyncEntityType.VISITA,
                SyncActionType.FINALIZE_VISITA,
                "visita-local-2",
                7L,
                6L,
                null,
                objectMapper.valueToTree(finalizarPayload())
        );

        when(visitaRepository.findById(7L)).thenReturn(Optional.of(atual));

        SyncProcessException ex = assertThrows(
                SyncProcessException.class,
                () -> handler.handle(request, new SyncRuntimeContext(1L, "device-1"))
        );

        assertEquals(SyncOperationStatus.CONFLICT, ex.getStatus());
        assertEquals(SyncErrorCode.VERSION_CONFLICT, ex.getCode());
        verifyNoInteractions(visitaTecnicaService);
        verifyNoInteractions(attachmentService);
    }

    @Test
    void cancelarDeveSerIdempotenteQuandoVisitaJaEstiverCancelada() {
        VisitaTecnica atual = visita(11L, StatusVisita.CANCELADA, 5L);
        SyncOperationRequest request = new SyncOperationRequest(
                "op-visita-3",
                SyncEntityType.VISITA,
                SyncActionType.CANCEL_VISITA,
                "visita-local-3",
                11L,
                5L,
                null,
                null
        );

        when(visitaRepository.findById(11L)).thenReturn(Optional.of(atual));

        SyncOperationResult result = handler.handle(request, new SyncRuntimeContext(1L, "device-1"));

        assertEquals(SyncOperationStatus.APPLIED, result.status());
        assertEquals(SyncErrorCode.SUCCESS, result.code());
        assertEquals("Visita ja estava cancelada", result.message());
        verifyNoInteractions(visitaTecnicaService);
    }

    private SyncFinalizarVisitaPayload finalizarPayload() {
        return new SyncFinalizarVisitaPayload(
                List.of(new SyncDiagnosticoPayload(
                        "Solo",
                        Criticidade.MEDIA,
                        "Observacao",
                        null,
                        "https://cdn.exemplo/imagem.jpg"
                )),
                List.of(new SyncEncaminhamentoPayload(
                        "Ajustar manejo",
                        "Tecnico",
                        LocalDate.of(2026, 6, 20),
                        Verificacao.VISITA,
                        Prioridade.ALTA
                )),
                "Resumo geral"
        );
    }

    private VisitaTecnica visita(Long id, StatusVisita status, Long version) {
        Usuario usuario = new Usuario();
        usuario.setId(2L);
        usuario.setNome("Tecnico Sync");

        Propriedade propriedade = Propriedade.builder()
                .id(3L)
                .nome("Propriedade Sync")
                .nomeProprietario("Produtor Sync")
                .build();

        return VisitaTecnica.builder()
                .id(id)
                .usuario(usuario)
                .propriedade(propriedade)
                .statusVisita(status)
                .version(version)
                .build();
    }
}
