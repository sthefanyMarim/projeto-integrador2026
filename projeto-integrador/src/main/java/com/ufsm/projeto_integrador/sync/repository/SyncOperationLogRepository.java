package com.ufsm.projeto_integrador.sync.repository;

import com.ufsm.projeto_integrador.sync.domain.entity.SyncOperationLog;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface SyncOperationLogRepository extends JpaRepository<SyncOperationLog, Long> {

    Optional<SyncOperationLog> findByUsuarioIdAndDeviceIdAndOperationId(
            Long userId,
            String deviceId,
            String operationId
    );
}
