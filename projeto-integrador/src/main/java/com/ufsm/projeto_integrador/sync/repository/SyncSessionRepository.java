package com.ufsm.projeto_integrador.sync.repository;

import com.ufsm.projeto_integrador.sync.domain.entity.SyncSession;
import com.ufsm.projeto_integrador.sync.enums.SyncSessionStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Collection;
import java.util.UUID;

public interface SyncSessionRepository extends JpaRepository<SyncSession, UUID> {

    boolean existsByUsuarioIdAndDeviceIdAndStatusIn(
            Long userId,
            String deviceId,
            Collection<SyncSessionStatus> statuses
    );

    @Transactional
    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("""
            update SyncSession s
               set s.status = :failedStatus,
                   s.finishedAt = :finishedAt,
                   s.serverTime = :finishedAt,
                   s.errorType = :errorType,
                   s.errorMessage = :errorMessage
             where s.usuario.id = :userId
               and s.deviceId = :deviceId
               and s.status in :activeStatuses
               and s.startedAt < :cutoff
            """)
    int expireStaleSessions(
            @Param("userId") Long userId,
            @Param("deviceId") String deviceId,
            @Param("activeStatuses") Collection<SyncSessionStatus> activeStatuses,
            @Param("cutoff") LocalDateTime cutoff,
            @Param("failedStatus") SyncSessionStatus failedStatus,
            @Param("finishedAt") LocalDateTime finishedAt,
            @Param("errorType") String errorType,
            @Param("errorMessage") String errorMessage
    );
}
