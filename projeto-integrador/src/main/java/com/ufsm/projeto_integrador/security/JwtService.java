package com.ufsm.projeto_integrador.security;

import com.ufsm.projeto_integrador.domain.entity.Usuario;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;

@Service
public class JwtService {

    @Value("${jwt.secret}")
    private String secret;

    @Value("${jwt.access-token-expiration}")
    private long accessTokenExpiration;

    public String generateAccessToken(Usuario usuario) {
        return Jwts.builder()
                .subject(usuario.getMatricula())
                .claim("userId", usuario.getId())
                .claim("tipo", usuario.getTipo().name())
                .claim("nome", usuario.getNome())
                .issuedAt(new Date())
                .expiration(new Date(System.currentTimeMillis() + accessTokenExpiration))
                .signWith(signingKey())
                .compact();
    }

    public String extractMatricula(String token) {
        return claims(token).getSubject();
    }

    public Long extractUserId(String token) {
        return claims(token).get("userId", Long.class);
    }

    public String extractTipo(String token) {
        return claims(token).get("tipo", String.class);
    }

    public boolean isValid(String token, UserDetails userDetails) {
        String matricula = extractMatricula(token);
        return matricula.equals(userDetails.getUsername())
                && !isExpired(token)
                && userDetails.isEnabled();
    }

    private boolean isExpired(String token) {
        return claims(token).getExpiration().before(new Date());
    }

    private Claims claims(String token) {
        return Jwts.parser()
                .verifyWith(signingKey())
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }

    private SecretKey signingKey() {
        return Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
    }
}
