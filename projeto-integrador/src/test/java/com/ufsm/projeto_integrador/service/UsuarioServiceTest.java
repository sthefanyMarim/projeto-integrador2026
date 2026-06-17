package com.ufsm.projeto_integrador.service;

import com.ufsm.projeto_integrador.domain.dto.usuario.UsuarioRequest;
import com.ufsm.projeto_integrador.domain.entity.Usuario;
import com.ufsm.projeto_integrador.domain.enums.TipoUsuario;
import com.ufsm.projeto_integrador.exception.BusinessException;
import com.ufsm.projeto_integrador.repository.UsuarioRepository;
import com.ufsm.projeto_integrador.sync.service.SyncChangeService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class UsuarioServiceTest {

    @Mock
    private UsuarioRepository repository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private SyncChangeService syncChangeService;

    @InjectMocks
    private UsuarioService service;

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
}
