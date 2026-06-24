package com.ufsm.projeto_integrador.service;

import com.ufsm.projeto_integrador.domain.dto.auth.LoginRequest;
import com.ufsm.projeto_integrador.domain.dto.auth.LoginResponse;
import com.ufsm.projeto_integrador.domain.entity.RefreshToken;
import com.ufsm.projeto_integrador.domain.entity.Usuario;
import com.ufsm.projeto_integrador.domain.enums.TipoUsuario;
import com.ufsm.projeto_integrador.exception.ResourceNotFoundException;
import com.ufsm.projeto_integrador.repository.UsuarioRepository;
import com.ufsm.projeto_integrador.security.JwtService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @Mock private AuthenticationManager authManager;
    @Mock private UsuarioRepository usuarioRepository;
    @Mock private JwtService jwtService;
    @Mock private RefreshTokenService refreshTokenService;

    @InjectMocks private AuthService authService;

    private Usuario usuarioPadrao() {
        return Usuario.builder()
                .id(1L)
                .nome("Técnico Teste")
                .matricula("12345")
                .email("tecnico@ufsm.br")
                .senha("hash")
                .tipo(TipoUsuario.TECNICO)
                .ativo(true)
                .build();
    }

    @Test
    void login_deveAutenticarERetornarTokens_quandoCredenciaisValidas() {
        Usuario usuario = usuarioPadrao();
        RefreshToken refreshToken = RefreshToken.builder().token("refresh-abc").usuario(usuario).build();

        when(usuarioRepository.findByMatricula("12345")).thenReturn(Optional.of(usuario));
        when(jwtService.generateAccessToken(usuario)).thenReturn("access-token");
        when(refreshTokenService.create(usuario)).thenReturn(refreshToken);

        LoginResponse response = authService.login(new LoginRequest("12345", "senha123"));

        assertThat(response.accessToken()).isEqualTo("access-token");
        assertThat(response.refreshToken()).isEqualTo("refresh-abc");
        assertThat(response.tipo()).isEqualTo(TipoUsuario.TECNICO);
        assertThat(response.userId()).isEqualTo(1L);
        verify(authManager).authenticate(new UsernamePasswordAuthenticationToken("12345", "senha123"));
    }

    @Test
    void login_devePropagarExcecao_quandoCredenciaisInvalidas() {
        when(authManager.authenticate(any())).thenThrow(new BadCredentialsException("Credenciais inválidas"));

        assertThatThrownBy(() -> authService.login(new LoginRequest("12345", "errada")))
                .isInstanceOf(BadCredentialsException.class);

        verifyNoInteractions(usuarioRepository, jwtService, refreshTokenService);
    }

    @Test
    void login_deveLancarResourceNotFound_quandoUsuarioNaoEncontradoAposAutenticar() {
        when(usuarioRepository.findByMatricula("99999")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> authService.login(new LoginRequest("99999", "senha123")))
                .isInstanceOf(ResourceNotFoundException.class);

        verifyNoInteractions(jwtService, refreshTokenService);
    }

    @Test
    void refresh_deveGerarNovoAccessTokenERefreshToken() {
        Usuario usuario = usuarioPadrao();
        RefreshToken tokenAtual = RefreshToken.builder().token("antigo").usuario(usuario).build();
        RefreshToken novoToken = RefreshToken.builder().token("novo").usuario(usuario).build();

        when(refreshTokenService.verificar("antigo")).thenReturn(tokenAtual);
        when(jwtService.generateAccessToken(usuario)).thenReturn("novo-access-token");
        when(refreshTokenService.create(usuario)).thenReturn(novoToken);

        LoginResponse response = authService.refresh("antigo");

        assertThat(response.accessToken()).isEqualTo("novo-access-token");
        assertThat(response.refreshToken()).isEqualTo("novo");
    }

    @Test
    void logout_deveDelegarRevogacaoAoRefreshTokenService() {
        authService.logout("token-x");

        verify(refreshTokenService).revogar("token-x");
    }
}
