package com.ufsm.projeto_integrador.sync.repository;

import com.ufsm.projeto_integrador.sync.domain.entity.SyncAttachment;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface SyncAttachmentRepository extends JpaRepository<SyncAttachment, UUID> {

    Optional<SyncAttachment> findByUsuarioIdAndDeviceIdAndClientAttachmentId(
            Long userId,
            String deviceId,
            String clientAttachmentId
    );

    Optional<SyncAttachment> findByIdAndUsuarioId(UUID id, Long userId);

    Optional<SyncAttachment> findByIdAndUsuarioIdAndDeviceId(UUID id, Long userId, String deviceId);
}
