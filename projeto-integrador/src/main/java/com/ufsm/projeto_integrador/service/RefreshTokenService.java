package com.ufsm.projeto_integrador.service;

import com.ufsm.projeto_integrador.domain.entity.RefreshToken;
import com.ufsm.projeto_integrador.domain.entity.Usuario;
import com.ufsm.projeto_integrador.exception.BusinessException;
import com.ufsm.projeto_integrador.repository.RefreshTokenRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class RefreshTokenService {

    @Value("${jwt.refresh-token-expiration}")
    private long refreshTokenExpiration;

    private final RefreshTokenRepository repository;

    @Transactional
    public RefreshToken create(Usuario usuario) {
        repository.revogarTodosPorUsuario(usuario.getId());
        return repository.save(RefreshToken.builder()
                .token(UUID.randomUUID().toString())
                .usuario(usuario)
                .expiraEm(Instant.now().plusMillis(refreshTokenExpiration))
                .build());
    }

    public RefreshToken verificar(String token) {
        RefreshToken rt = repository.findByToken(token)
                .orElseThrow(() -> new BusinessException("Refresh token inválido"));
        if (rt.getRevogado())
            throw new BusinessException("Refresh token revogado — faça login novamente");
        if (rt.getExpiraEm().isBefore(Instant.now())) {
            rt.setRevogado(true);
            repository.save(rt);
            throw new BusinessException("Refresh token expirado — faça login novamente");
        }
        return rt;
    }

    @Transactional
    public void revogar(String token) {
        repository.findByToken(token).ifPresent(rt -> {
            rt.setRevogado(true);
            repository.save(rt);
        });
    }
}
