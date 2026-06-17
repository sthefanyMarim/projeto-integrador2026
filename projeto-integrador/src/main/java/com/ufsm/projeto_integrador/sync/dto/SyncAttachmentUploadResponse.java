package com.ufsm.projeto_integrador.sync.dto;

import com.ufsm.projeto_integrador.sync.enums.SyncAttachmentPurpose;
import com.ufsm.projeto_integrador.sync.enums.SyncAttachmentStatus;

import java.util.UUID;

public record SyncAttachmentUploadResponse(
        UUID attachmentId,
        String clientAttachmentId,
        String deviceId,
        SyncAttachmentPurpose purpose,
        SyncAttachmentStatus status,
        String storageUrl
) {
}
