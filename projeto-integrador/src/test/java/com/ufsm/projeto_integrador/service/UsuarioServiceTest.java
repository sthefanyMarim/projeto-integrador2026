package com.ufsm.projeto_integrador.service;

import com.ufsm.projeto_integrador.domain.dto.usuario.UsuarioRequest;
import com.ufsm.projeto_integrador.domain.dto.usuario.UsuarioResponse;
import com.ufsm.projeto_integrador.domain.entity.Usuario;
import com.ufsm.projeto_integrador.domain.enums.StatusVisita;
import com.ufsm.projeto_integrador.domain.enums.TipoUsuario;
import com.ufsm.projeto_integrador.exception.BusinessException;
import com.ufsm.projeto_integrador.exception.ResourceNotFoundException;
import com.ufsm.projeto_integrador.repository.UsuarioRepository;
import com.ufsm.projeto_integrador.repository.VisitaTecnicaRepository;
import com.ufsm.projeto_integrador.security.SecurityUtils;
import com.ufsm.projeto_integrador.sync.service.SyncChangeService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.time.LocalDate;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class UsuarioServiceTest {

    @Mock
    private UsuarioRepository repository;

    @Mock
    private VisitaTecnicaRepository visitaTecnicaRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private SyncChangeService syncChangeService;

    @InjectMocks
    private UsuarioService service;

    private UsuarioRequest requestValido() {
        return new UsuarioRequest("Joao Tecnico", "2026010", "joao@ufsm.br", "55999999999", "senha123", TipoUsuario.TECNICO);
    }

    @Test
    void criarDeveExigirSenha() {
        UsuarioRequest request = new UsuarioRequest(
                "Tecnico",
                "2026001",
                "tecnico@ufsm.br",
                "55999999999",
                null,
                TipoUsuario.TECNICO
        );

        BusinessException ex = assertThrows(BusinessException.class, () -> service.criar(request));
        assertEquals("Senha obrigatória", ex.getMessage());
        verify(passwordEncoder, never()).encode(any());
        verify(repository, never()).save(any());
    }

    @Test
    void atualizarDevePermitirSenhaNulaSemAlterarSenhaAtual() {
        Usuario usuario = Usuario.builder()
                .id(5L)
                .nome("Tecnico Atual")
                .matricula("2026002")
                .email("atual@ufsm.br")
                .telefone("5551999999999")
                .senha("hash-antigo")
                .tipo(TipoUsuario.TECNICO)
                .ativo(true)
                .build();

        UsuarioRequest request = new UsuarioRequest(
                "Tecnico Atualizado",
                "2026002",
                "atual@ufsm.br",
                "5551888888888",
                null,
                TipoUsuario.ADMIN
        );

        when(repository.findById(5L)).thenReturn(Optional.of(usuario));
        when(repository.save(any(Usuario.class))).thenAnswer(invocation -> invocation.getArgument(0));

        var response = service.atualizar(5L, request);

        assertEquals("Tecnico Atualizado", response.nome());
        assertEquals(TipoUsuario.TECNICO, response.tipo());
        assertEquals("hash-antigo", usuario.getSenha());
        verify(passwordEncoder, never()).encode(any());
        assertNull(request.senha());
    }

    @Test
    void criarDeveLancarExceptionQuandoMatriculaJaCadastrada() {
        when(repository.existsByMatricula("2026010")).thenReturn(true);

        BusinessException ex = assertThrows(BusinessException.class, () -> service.criar(requestValido()));
        assertTrue(ex.getMessage().contains("Matricula ja cadastrada"));
        verify(repository, never()).save(any());
    }

    @Test
    void criarDeveLancarExceptionQuandoEmailJaCadastrado() {
        when(repository.existsByMatricula(any())).thenReturn(false);
        when(repository.existsByEmail("joao@ufsm.br")).thenReturn(true);

        BusinessException ex = assertThrows(BusinessException.class, () -> service.criar(requestValido()));
        assertTrue(ex.getMessage().contains("Email ja cadastrado"));
    }

    @Test
    void criarDeveCodificarSenhaEAtivarUsuarioPorPadrao() {
        when(repository.existsByMatricula(any())).thenReturn(false);
        when(repository.existsByEmail(any())).thenReturn(false);
        when(passwordEncoder.encode("senha123")).thenReturn("HASH(senha123)");
        when(repository.save(any(Usuario.class))).thenAnswer(invocation -> {
            Usuario u = invocation.getArgument(0);
            u.setId(10L);
            return u;
        });

        UsuarioResponse response = service.criar(requestValido());

        assertEquals(10L, response.id());
        assertTrue(response.ativo());
        verify(repository).save(argThatSenhaCodificada());
        verify(syncChangeService).recordUsuarioUpsert(any(), any());
    }

    private Usuario argThatSenhaCodificada() {
        return org.mockito.ArgumentMatchers.argThat(u -> "HASH(senha123)".equals(u.getSenha()) && u.getAtivo());
    }

    @Test
    void atualizarDeveLancarExceptionQuandoNovaMatriculaJaEmUsoPorOutroUsuario() {
        Usuario existente = Usuario.builder().id(5L).matricula("antiga").email("joao@ufsm.br")
                .senha("hash").tipo(TipoUsuario.TECNICO).ativo(true).build();
        when(repository.findById(5L)).thenReturn(Optional.of(existente));
        when(repository.existsByMatricula("2026010")).thenReturn(true);

        BusinessException ex = assertThrows(BusinessException.class, () -> service.atualizar(5L, requestValido()));
        assertTrue(ex.getMessage().contains("Matricula ja em uso"));
    }

    @Test
    void atualizarDeveLancarExceptionQuandoNovoEmailJaEmUsoPorOutroUsuario() {
        Usuario existente = Usuario.builder().id(5L).matricula("2026010").email("antigo@ufsm.br")
                .senha("hash").tipo(TipoUsuario.TECNICO).ativo(true).build();
        when(repository.findById(5L)).thenReturn(Optional.of(existente));
        when(repository.existsByEmail("joao@ufsm.br")).thenReturn(true);

        BusinessException ex = assertThrows(BusinessException.class, () -> service.atualizar(5L, requestValido()));
        assertTrue(ex.getMessage().contains("Email ja em uso"));
    }

    @Test
    void atualizarDeveAlterarTipoQuandoUsuarioLogadoEAdmin() {
        Usuario existente = Usuario.builder().id(5L).matricula("2026010").email("joao@ufsm.br")
                .senha("hash").tipo(TipoUsuario.TECNICO).ativo(true).build();
        when(repository.findById(5L)).thenReturn(Optional.of(existente));
        when(repository.save(any(Usuario.class))).thenAnswer(invocation -> invocation.getArgument(0));

        UsuarioRequest comTipoAdmin = new UsuarioRequest(
                "Joao Tecnico", "2026010", "joao@ufsm.br", "55999999999", null, TipoUsuario.ADMIN);

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::isAdmin).thenReturn(true);
            security.when(SecurityUtils::getCurrentUserIdOrNull).thenReturn(1L);

            UsuarioResponse response = service.atualizar(5L, comTipoAdmin);

            assertEquals(TipoUsuario.ADMIN, response.tipo());
        }
        assertEquals(TipoUsuario.ADMIN, existente.getTipo());
    }

    @Test
    void atualizarNaoDeveAlterarTipoQuandoUsuarioLogadoNaoEAdmin() {
        Usuario existente = Usuario.builder().id(5L).matricula("2026010").email("joao@ufsm.br")
                .senha("hash").tipo(TipoUsuario.TECNICO).ativo(true).build();
        when(repository.findById(5L)).thenReturn(Optional.of(existente));
        when(repository.save(any(Usuario.class))).thenAnswer(invocation -> invocation.getArgument(0));

        UsuarioRequest comTipoAdmin = new UsuarioRequest(
                "Joao Tecnico", "2026010", "joao@ufsm.br", "55999999999", null, TipoUsuario.ADMIN);

        service.atualizar(5L, comTipoAdmin);

        assertEquals(TipoUsuario.TECNICO, existente.getTipo());
    }

    @Test
    void alternarStatusDeveLancarExceptionQuandoInativarTecnicoComVisitasFuturasAgendadas() {
        Usuario tecnico = Usuario.builder().id(7L).ativo(true).build();
        when(repository.findById(7L)).thenReturn(Optional.of(tecnico));
        when(visitaTecnicaRepository.countByUsuarioIdAndStatusVisitaAndDataVisitaGreaterThanEqual(
                eq(7L), eq(StatusVisita.AGENDADA), any(LocalDate.class))).thenReturn(2L);

        BusinessException ex = assertThrows(BusinessException.class, () -> service.alternarStatus(7L));
        assertTrue(ex.getMessage().contains("2 visita(s) agendada(s)"));
        verify(repository, never()).save(any());
    }

    @Test
    void alternarStatusDeveInativarQuandoSemVisitasFuturasAgendadas() {
        Usuario tecnico = Usuario.builder().id(7L).ativo(true).build();
        when(repository.findById(7L)).thenReturn(Optional.of(tecnico));
        when(visitaTecnicaRepository.countByUsuarioIdAndStatusVisitaAndDataVisitaGreaterThanEqual(
                eq(7L), eq(StatusVisita.AGENDADA), any(LocalDate.class))).thenReturn(0L);
        when(repository.save(any(Usuario.class))).thenAnswer(invocation -> invocation.getArgument(0));

        service.alternarStatus(7L);

        assertFalse(tecnico.getAtivo());
    }

    @Test
    void alternarStatusDeveAtivarSemValidarVisitasQuandoEstavaInativo() {
        Usuario tecnico = Usuario.builder().id(7L).ativo(false).build();
        when(repository.findById(7L)).thenReturn(Optional.of(tecnico));
        when(repository.save(any(Usuario.class))).thenAnswer(invocation -> invocation.getArgument(0));

        service.alternarStatus(7L);

        assertTrue(tecnico.getAtivo());
        verify(visitaTecnicaRepository, never())
                .countByUsuarioIdAndStatusVisitaAndDataVisitaGreaterThanEqual(any(), any(), any());
    }

    @Test
    void deletarDeveLancarExceptionQuandoUsuarioTemVisitasRegistradas() {
        Usuario usuario = Usuario.builder().id(7L).build();
        when(repository.findById(7L)).thenReturn(Optional.of(usuario));
        when(visitaTecnicaRepository.countByUsuarioId(7L)).thenReturn(3L);

        BusinessException ex = assertThrows(BusinessException.class, () -> service.deletar(7L));
        assertTrue(ex.getMessage().contains("3 visita(s) registrada(s)"));
        verify(repository, never()).deleteById(any());
    }

    @Test
    void deletarDeveExcluirQuandoSemVisitasRegistradas() {
        Usuario usuario = Usuario.builder().id(7L).build();
        when(repository.findById(7L)).thenReturn(Optional.of(usuario));
        when(visitaTecnicaRepository.countByUsuarioId(7L)).thenReturn(0L);

        service.deletar(7L);

        verify(repository).deleteById(7L);
        verify(syncChangeService).recordUsuarioDelete(eq(7L), any(), any());
    }

    @Test
    void buscarPorIdDeveLancarResourceNotFoundQuandoNaoExiste() {
        when(repository.findById(404L)).thenReturn(Optional.empty());

        assertThrows(ResourceNotFoundException.class, () -> service.buscarPorId(404L));
    }
}
