package com.ufsm.projeto_integrador.service;

import com.ufsm.projeto_integrador.domain.dto.auth.LoginRequest;
import com.ufsm.projeto_integrador.domain.dto.auth.LoginResponse;
import com.ufsm.projeto_integrador.domain.entity.RefreshToken;
import com.ufsm.projeto_integrador.domain.entity.Usuario;
import com.ufsm.projeto_integrador.exception.ResourceNotFoundException;
import com.ufsm.projeto_integrador.repository.UsuarioRepository;
import com.ufsm.projeto_integrador.security.JwtService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final AuthenticationManager authManager;
    private final UsuarioRepository usuarioRepository;
    private final JwtService jwtService;
    private final RefreshTokenService refreshTokenService;

    public LoginResponse login(LoginRequest request) {
        authManager.authenticate(
                new UsernamePasswordAuthenticationToken(request.matricula(), request.senha()));

        Usuario usuario = usuarioRepository.findByMatricula(request.matricula())
                .orElseThrow(() -> new ResourceNotFoundException("Usuário não encontrado"));

        String accessToken   = jwtService.generateAccessToken(usuario);
        RefreshToken refresh = refreshTokenService.create(usuario);

        return new LoginResponse(accessToken, refresh.getToken(),
                usuario.getTipo(), usuario.getNome(), usuario.getId());
    }

    @Transactional
    public LoginResponse refresh(String refreshTokenStr) {
        RefreshToken rt      = refreshTokenService.verificar(refreshTokenStr);
        Usuario usuario      = rt.getUsuario();
        String accessToken   = jwtService.generateAccessToken(usuario);
        RefreshToken newRt   = refreshTokenService.create(usuario);

        return new LoginResponse(accessToken, newRt.getToken(),
                usuario.getTipo(), usuario.getNome(), usuario.getId());
    }

    public void logout(String refreshToken) {
        refreshTokenService.revogar(refreshToken);
    }
}
