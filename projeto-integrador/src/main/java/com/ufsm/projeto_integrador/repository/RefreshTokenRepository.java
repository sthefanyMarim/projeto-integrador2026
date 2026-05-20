package com.ufsm.projeto_integrador.repository;

import com.ufsm.projeto_integrador.domain.entity.RefreshToken;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.Optional;

@Repository
public interface RefreshTokenRepository extends JpaRepository<RefreshToken, Long> {

    Optional<RefreshToken> findByToken(String token);

    @Modifying
    @Query("UPDATE RefreshToken r SET r.revogado = true WHERE r.usuario.id = :userId AND r.revogado = false")
    void revogarTodosPorUsuario(@Param("userId") Long userId);

    @Modifying
    @Query("DELETE FROM RefreshToken r WHERE r.expiraEm < :agora OR r.revogado = true")
    void deleteExpired(@Param("agora") Instant agora);
}
