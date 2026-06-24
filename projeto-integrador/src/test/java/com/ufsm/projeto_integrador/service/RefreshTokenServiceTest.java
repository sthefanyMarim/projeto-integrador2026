package com.ufsm.projeto_integrador.service;

import com.ufsm.projeto_integrador.domain.entity.RefreshToken;
import com.ufsm.projeto_integrador.domain.entity.Usuario;
import com.ufsm.projeto_integrador.exception.BusinessException;
import com.ufsm.projeto_integrador.repository.RefreshTokenRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import java.time.Instant;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class RefreshTokenServiceTest {

    @Mock private RefreshTokenRepository repository;

    @InjectMocks private RefreshTokenService refreshTokenService;

    private static final long EXPIRATION_MS = 7L * 24 * 60 * 60 * 1000;

    private void comExpiracaoConfigurada() {
        ReflectionTestUtils.setField(refreshTokenService, "refreshTokenExpiration", EXPIRATION_MS);
    }

    @Test
    void create_deveRevogarTokensAntigosECriarNovoComExpiracaoFutura() {
        comExpiracaoConfigurada();
        Usuario usuario = Usuario.builder().id(1L).build();
        when(repository.save(any(RefreshToken.class))).thenAnswer(invocation -> invocation.getArgument(0));

        Instant antes = Instant.now();
        RefreshToken criado = refreshTokenService.create(usuario);

        verify(repository).revogarTodosPorUsuario(1L);
        ArgumentCaptor<RefreshToken> captor = ArgumentCaptor.forClass(RefreshToken.class);
        verify(repository).save(captor.capture());
        assertThat(captor.getValue().getToken()).isNotBlank();
        assertThat(captor.getValue().getUsuario()).isEqualTo(usuario);
        assertThat(criado.getExpiraEm()).isAfter(antes.plusMillis(EXPIRATION_MS - 5000));
    }

    @Test
    void verificar_deveLancarBusinessException_quandoTokenNaoEncontrado() {
        when(repository.findByToken("inexistente")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> refreshTokenService.verificar("inexistente"))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("inválido");
    }

    @Test
    void verificar_deveLancarBusinessException_quandoTokenRevogado() {
        RefreshToken rt = RefreshToken.builder().token("rev").revogado(true).expiraEm(Instant.now().plusSeconds(60)).build();
        when(repository.findByToken("rev")).thenReturn(Optional.of(rt));

        assertThatThrownBy(() -> refreshTokenService.verificar("rev"))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("revogado");
        verify(repository, never()).save(any());
    }

    @Test
    void verificar_deveLancarERevogarToken_quandoExpirado() {
        RefreshToken rt = RefreshToken.builder().token("exp").revogado(false).expiraEm(Instant.now().minusSeconds(1)).build();
        when(repository.findByToken("exp")).thenReturn(Optional.of(rt));

        assertThatThrownBy(() -> refreshTokenService.verificar("exp"))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("expirado");

        ArgumentCaptor<RefreshToken> captor = ArgumentCaptor.forClass(RefreshToken.class);
        verify(repository).save(captor.capture());
        assertThat(captor.getValue().getRevogado()).isTrue();
    }

    @Test
    void verificar_deveRetornarToken_quandoValidoENaoExpirado() {
        RefreshToken rt = RefreshToken.builder().token("ok").revogado(false).expiraEm(Instant.now().plusSeconds(60)).build();
        when(repository.findByToken("ok")).thenReturn(Optional.of(rt));

        RefreshToken resultado = refreshTokenService.verificar("ok");

        assertThat(resultado).isSameAs(rt);
        verify(repository, never()).save(any());
    }

    @Test
    void revogar_deveMarcarTokenComoRevogado_quandoExiste() {
        RefreshToken rt = RefreshToken.builder().token("alvo").revogado(false).build();
        when(repository.findByToken("alvo")).thenReturn(Optional.of(rt));

        refreshTokenService.revogar("alvo");

        assertThat(rt.getRevogado()).isTrue();
        verify(repository).save(rt);
    }

    @Test
    void revogar_naoDeveLancarErro_quandoTokenNaoExiste() {
        when(repository.findByToken("fantasma")).thenReturn(Optional.empty());

        refreshTokenService.revogar("fantasma");

        verify(repository, never()).save(any());
    }
}
