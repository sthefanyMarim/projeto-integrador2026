package com.ufsm.projeto_integrador.service;

import com.ufsm.projeto_integrador.domain.dto.visita.FinalizarVisitaRequest;
import com.ufsm.projeto_integrador.domain.dto.visita.VisitaRequest;
import com.ufsm.projeto_integrador.domain.dto.visita.VisitaResponse;
import com.ufsm.projeto_integrador.domain.dto.diagnostico.DiagnosticoRequest;
import com.ufsm.projeto_integrador.domain.dto.encaminhamento.EncaminhamentoRequest;
import com.ufsm.projeto_integrador.domain.entity.Propriedade;
import com.ufsm.projeto_integrador.domain.entity.Usuario;
import com.ufsm.projeto_integrador.domain.entity.VisitaTecnica;
import com.ufsm.projeto_integrador.domain.enums.Criticidade;
import com.ufsm.projeto_integrador.domain.enums.Prioridade;
import com.ufsm.projeto_integrador.domain.enums.StatusVisita;
import com.ufsm.projeto_integrador.domain.enums.TipoVisita;
import com.ufsm.projeto_integrador.domain.enums.Verificacao;
import com.ufsm.projeto_integrador.exception.BusinessException;
import com.ufsm.projeto_integrador.exception.ResourceNotFoundException;
import com.ufsm.projeto_integrador.repository.PropriedadeRepository;
import com.ufsm.projeto_integrador.repository.UsuarioRepository;
import com.ufsm.projeto_integrador.repository.VisitaTecnicaRepository;
import com.ufsm.projeto_integrador.security.SecurityUtils;
import com.ufsm.projeto_integrador.sync.service.SyncChangeService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class VisitaTecnicaServiceTest {

    @Mock
    private VisitaTecnicaRepository repository;

    @Mock
    private PropriedadeRepository propriedadeRepository;

    @Mock
    private UsuarioRepository usuarioRepository;

    @Mock
    private SyncChangeService syncChangeService;

    @InjectMocks
    private VisitaTecnicaService service;

    @BeforeEach
    void configurarDuracaoVisita() {
        ReflectionTestUtils.setField(service, "duracaoVisitaMinutos", 45);
    }

    private Propriedade propriedadeAtiva() {
        return Propriedade.builder().id(3L).nome("Sitio Boa Vista").nomeProprietario("Zé").ativa(true).build();
    }

    private VisitaRequest visitaRequestPara(LocalDate data, LocalTime hora) {
        return new VisitaRequest(3L, data, hora, TipoVisita.ROTINA, "Tema", "Obs", null, null);
    }

    @Test
    void buscarPorIdDeveNegarAcessoQuandoVisitaForDeOutroTecnico() {
        VisitaTecnica visita = visitaComUsuario(7L, 10L);
        when(repository.findById(7L)).thenReturn(Optional.of(visita));

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::isAdmin).thenReturn(false);
            security.when(SecurityUtils::getCurrentUserId).thenReturn(99L);

            BusinessException ex = assertThrows(BusinessException.class, () -> service.buscarPorId(7L));
            assertEquals("Acesso negado a esta visita", ex.getMessage());
        }
    }

    @Test
    void buscarPorIdDevePermitirAcessoQuandoVisitaForDoUsuarioLogado() {
        VisitaTecnica visita = visitaComUsuario(8L, 42L);
        when(repository.findById(8L)).thenReturn(Optional.of(visita));

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::isAdmin).thenReturn(false);
            security.when(SecurityUtils::getCurrentUserId).thenReturn(42L);

            assertEquals(8L, service.buscarPorId(8L).id());
            assertEquals(42L, service.buscarPorId(8L).usuarioId());
        }
    }

    private VisitaTecnica visitaComUsuario(Long visitaId, Long usuarioId) {
        Usuario usuario = new Usuario();
        usuario.setId(usuarioId);
        usuario.setNome("Tecnico Teste");

        Propriedade propriedade = new Propriedade();
        propriedade.setId(3L);
        propriedade.setNome("Propriedade Teste");

        VisitaTecnica visita = new VisitaTecnica();
        visita.setId(visitaId);
        visita.setUsuario(usuario);
        visita.setPropriedade(propriedade);
        return visita;
    }

    @Test
    void agendarDeveLancarResourceNotFoundQuandoPropriedadeNaoExiste() {
        when(propriedadeRepository.findById(3L)).thenReturn(Optional.empty());
        VisitaRequest req = visitaRequestPara(LocalDate.now().plusDays(1), LocalTime.of(10, 0));

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentUserId).thenReturn(42L);

            assertThrows(ResourceNotFoundException.class, () -> service.agendar(req));
        }
    }

    @Test
    void agendarDeveLancarBusinessExceptionQuandoPropriedadeInativa() {
        Propriedade inativa = Propriedade.builder().id(3L).nome("Sitio").nomeProprietario("Zé").ativa(false).build();
        when(propriedadeRepository.findById(3L)).thenReturn(Optional.of(inativa));
        VisitaRequest req = visitaRequestPara(LocalDate.now().plusDays(1), LocalTime.of(10, 0));

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentUserId).thenReturn(42L);

            BusinessException ex = assertThrows(BusinessException.class, () -> service.agendar(req));
            assertEquals("Propriedade inativa", ex.getMessage());
        }
    }

    @Test
    void agendarDeveLancarBusinessExceptionQuandoHorarioNoPassado() {
        when(propriedadeRepository.findById(3L)).thenReturn(Optional.of(propriedadeAtiva()));
        VisitaRequest req = visitaRequestPara(LocalDate.now().minusDays(1), LocalTime.of(10, 0));

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentUserId).thenReturn(42L);

            BusinessException ex = assertThrows(BusinessException.class, () -> service.agendar(req));
            assertTrue(ex.getMessage().contains("passado"));
        }
    }

    @Test
    void agendarDeveLancarBusinessExceptionQuandoConflitoDeHorario() {
        when(propriedadeRepository.findById(3L)).thenReturn(Optional.of(propriedadeAtiva()));
        LocalDate data = LocalDate.now().plusDays(1);
        VisitaTecnica existente = new VisitaTecnica();
        existente.setId(1L);
        existente.setHoraVisita(LocalTime.of(10, 0));
        when(repository.findAtivasByUsuarioAndData(42L, data)).thenReturn(List.of(existente));

        VisitaRequest req = visitaRequestPara(data, LocalTime.of(10, 20));

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentUserId).thenReturn(42L);

            BusinessException ex = assertThrows(BusinessException.class, () -> service.agendar(req));
            assertTrue(ex.getMessage().contains("Conflito de horário"));
        }
    }

    @Test
    void agendarDeveSalvarVisitaQuandoSemConflito() {
        when(propriedadeRepository.findById(3L)).thenReturn(Optional.of(propriedadeAtiva()));
        LocalDate data = LocalDate.now().plusDays(1);
        when(repository.findAtivasByUsuarioAndData(42L, data)).thenReturn(List.of());
        when(repository.save(any(VisitaTecnica.class))).thenAnswer(invocation -> invocation.getArgument(0));
        Usuario tecnicoLogado = Usuario.builder().id(42L).nome("Joao Tecnico").build();
        when(usuarioRepository.getReferenceById(42L)).thenReturn(tecnicoLogado);

        VisitaRequest req = visitaRequestPara(data, LocalTime.of(10, 0));

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentUserId).thenReturn(42L);

            VisitaResponse response = service.agendar(req);

            assertEquals(42L, response.usuarioId());
            assertEquals(StatusVisita.AGENDADA, response.statusVisita());
            assertEquals("Joao Tecnico", response.usuarioNome());
        }
    }

    @Test
    void atualizarDeveLancarBusinessExceptionQuandoVersionDivergente() {
        VisitaTecnica visita = visitaComUsuario(7L, 42L);
        visita.setVersion(3L);
        when(repository.findById(7L)).thenReturn(Optional.of(visita));
        when(propriedadeRepository.findById(3L)).thenReturn(Optional.of(propriedadeAtiva()));

        VisitaRequest req = new VisitaRequest(3L, LocalDate.now().plusDays(1), LocalTime.of(10, 0),
                TipoVisita.ROTINA, "Tema", "Obs", null, 1L);

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::isAdmin).thenReturn(false);
            security.when(SecurityUtils::getCurrentUserId).thenReturn(42L);

            BusinessException ex = assertThrows(BusinessException.class, () -> service.atualizar(7L, req));
            assertTrue(ex.getMessage().contains("modificada por outro dispositivo"));
        }
    }

    @Test
    void finalizarDeveLancarBusinessExceptionQuandoVisitaJaConcluida() {
        VisitaTecnica visita = visitaComUsuario(7L, 42L);
        visita.setStatusVisita(StatusVisita.CONCLUIDA);
        when(repository.findById(7L)).thenReturn(Optional.of(visita));

        FinalizarVisitaRequest req = new FinalizarVisitaRequest(List.of(), List.of(), null);

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::isAdmin).thenReturn(false);
            security.when(SecurityUtils::getCurrentUserId).thenReturn(42L);

            BusinessException ex = assertThrows(BusinessException.class, () -> service.finalizar(7L, req));
            assertEquals("Visita já concluída", ex.getMessage());
        }
    }

    @Test
    void finalizarDeveLancarBusinessExceptionQuandoVisitaCancelada() {
        VisitaTecnica visita = visitaComUsuario(7L, 42L);
        visita.setStatusVisita(StatusVisita.CANCELADA);
        when(repository.findById(7L)).thenReturn(Optional.of(visita));

        FinalizarVisitaRequest req = new FinalizarVisitaRequest(List.of(), List.of(), null);

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::isAdmin).thenReturn(false);
            security.when(SecurityUtils::getCurrentUserId).thenReturn(42L);

            BusinessException ex = assertThrows(BusinessException.class, () -> service.finalizar(7L, req));
            assertEquals("Visita cancelada não pode ser finalizada", ex.getMessage());
        }
    }

    @Test
    void finalizarDevePermitirAntecipacaoQuandoDataAgendadaNoFuturo() {
        VisitaTecnica visita = visitaComUsuario(7L, 42L);
        visita.setStatusVisita(StatusVisita.AGENDADA);
        visita.setDataVisita(LocalDate.now().plusDays(6));
        when(repository.findById(7L)).thenReturn(Optional.of(visita));
        when(repository.save(any(VisitaTecnica.class))).thenAnswer(invocation -> invocation.getArgument(0));

        FinalizarVisitaRequest req = new FinalizarVisitaRequest(List.of(), List.of(), null);

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::isAdmin).thenReturn(false);
            security.when(SecurityUtils::getCurrentUserId).thenReturn(42L);
            security.when(SecurityUtils::getCurrentUserIdOrNull).thenReturn(42L);

            service.finalizar(7L, req);

            assertEquals(StatusVisita.CONCLUIDA, visita.getStatusVisita());
        }
    }

    @Test
    void finalizarDevePermitirQuandoDataAgendadaEHojeOuPassado() {
        VisitaTecnica visita = visitaComUsuario(7L, 42L);
        visita.setStatusVisita(StatusVisita.AGENDADA);
        visita.setDataVisita(LocalDate.now().minusDays(2));
        when(repository.findById(7L)).thenReturn(Optional.of(visita));
        when(repository.save(any(VisitaTecnica.class))).thenAnswer(invocation -> invocation.getArgument(0));

        FinalizarVisitaRequest req = new FinalizarVisitaRequest(List.of(), List.of(), null);

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::isAdmin).thenReturn(false);
            security.when(SecurityUtils::getCurrentUserId).thenReturn(42L);
            security.when(SecurityUtils::getCurrentUserIdOrNull).thenReturn(42L);

            service.finalizar(7L, req);

            assertEquals(StatusVisita.CONCLUIDA, visita.getStatusVisita());
        }
    }

    @Test
    void finalizarDeveLancarBusinessExceptionQuandoVerificacaoNula() {
        VisitaTecnica visita = visitaComUsuario(7L, 42L);
        visita.setStatusVisita(StatusVisita.AGENDADA);
        when(repository.findById(7L)).thenReturn(Optional.of(visita));

        DiagnosticoRequest diag = new DiagnosticoRequest("Solo", Criticidade.ALTA, "obs", null);
        EncaminhamentoRequest enc = new EncaminhamentoRequest("Ligar para produtor", "Zé", null, null, null);
        FinalizarVisitaRequest req = new FinalizarVisitaRequest(List.of(diag), List.of(enc), null);

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::isAdmin).thenReturn(false);
            security.when(SecurityUtils::getCurrentUserId).thenReturn(42L);

            BusinessException ex = assertThrows(BusinessException.class, () -> service.finalizar(7L, req));
            assertEquals("Forma de verificação obrigatória para o encaminhamento.", ex.getMessage());
        }
        verify(repository, never()).save(any());
    }

    @Test
    void finalizarDeveDefinirPrioridadeCriticaQuandoVerificacaoVisitaSemPrazo() {
        VisitaTecnica visita = visitaComUsuario(7L, 42L);
        visita.setStatusVisita(StatusVisita.AGENDADA);
        when(repository.findById(7L)).thenReturn(Optional.of(visita));
        when(repository.save(any(VisitaTecnica.class))).thenAnswer(invocation -> invocation.getArgument(0));

        DiagnosticoRequest diag = new DiagnosticoRequest("Solo", Criticidade.ALTA, "obs", null);
        EncaminhamentoRequest enc = new EncaminhamentoRequest("Refazer análise", "Zé", null, Verificacao.VISITA, null);
        FinalizarVisitaRequest req = new FinalizarVisitaRequest(List.of(diag), List.of(enc), "geral");

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::isAdmin).thenReturn(false);
            security.when(SecurityUtils::getCurrentUserId).thenReturn(42L);
            security.when(SecurityUtils::getCurrentUserIdOrNull).thenReturn(42L);

            service.finalizar(7L, req);

            assertEquals(StatusVisita.CONCLUIDA, visita.getStatusVisita());
            assertEquals(1, visita.getEncaminhamentos().size());
            assertEquals(Prioridade.CRITICA, visita.getEncaminhamentos().get(0).getPrioridade());
        }
    }

    @Test
    void finalizarDeveLancarBusinessExceptionQuandoVerificacaoNaoVisitaSemPrazo() {
        VisitaTecnica visita = visitaComUsuario(7L, 42L);
        visita.setStatusVisita(StatusVisita.AGENDADA);
        when(repository.findById(7L)).thenReturn(Optional.of(visita));

        DiagnosticoRequest diag = new DiagnosticoRequest("Solo", Criticidade.ALTA, "obs", null);
        EncaminhamentoRequest enc = new EncaminhamentoRequest("Ligar para produtor", "Zé", null, Verificacao.LIGACAO, null);
        FinalizarVisitaRequest req = new FinalizarVisitaRequest(List.of(diag), List.of(enc), null);

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::isAdmin).thenReturn(false);
            security.when(SecurityUtils::getCurrentUserId).thenReturn(42L);

            BusinessException ex = assertThrows(BusinessException.class, () -> service.finalizar(7L, req));
            assertTrue(ex.getMessage().contains("requer um prazo definido"));
        }
        verify(repository, never()).save(any());
    }

    @Test
    void cancelarDeveLancarBusinessExceptionQuandoVisitaJaConcluida() {
        VisitaTecnica visita = visitaComUsuario(7L, 42L);
        visita.setStatusVisita(StatusVisita.CONCLUIDA);
        when(repository.findById(7L)).thenReturn(Optional.of(visita));

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::isAdmin).thenReturn(false);
            security.when(SecurityUtils::getCurrentUserId).thenReturn(42L);

            BusinessException ex = assertThrows(BusinessException.class, () -> service.cancelar(7L));
            assertEquals("Visita concluída não pode ser cancelada", ex.getMessage());
        }
        verify(repository, never()).save(any());
    }

    @Test
    void cancelarDeveCancelarQuandoVisitaAgendada() {
        VisitaTecnica visita = visitaComUsuario(7L, 42L);
        visita.setStatusVisita(StatusVisita.AGENDADA);
        when(repository.findById(7L)).thenReturn(Optional.of(visita));
        when(repository.save(any(VisitaTecnica.class))).thenAnswer(invocation -> invocation.getArgument(0));

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::isAdmin).thenReturn(false);
            security.when(SecurityUtils::getCurrentUserId).thenReturn(42L);
            security.when(SecurityUtils::getCurrentUserIdOrNull).thenReturn(42L);

            service.cancelar(7L);

            assertEquals(StatusVisita.CANCELADA, visita.getStatusVisita());
        }
    }
}
