package com.ufsm.projeto_integrador.sync.service;

import com.ufsm.projeto_integrador.domain.entity.Usuario;
import com.ufsm.projeto_integrador.exception.BusinessException;
import com.ufsm.projeto_integrador.service.S3Service;
import com.ufsm.projeto_integrador.sync.domain.entity.SyncAttachment;
import com.ufsm.projeto_integrador.sync.dto.SyncAttachmentUploadResponse;
import com.ufsm.projeto_integrador.sync.enums.SyncAttachmentPurpose;
import com.ufsm.projeto_integrador.sync.enums.SyncAttachmentStatus;
import com.ufsm.projeto_integrador.sync.enums.SyncEntityType;
import com.ufsm.projeto_integrador.sync.enums.SyncErrorCode;
import com.ufsm.projeto_integrador.sync.repository.SyncAttachmentRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.security.MessageDigest;
import java.time.LocalDateTime;
import java.util.HexFormat;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class SyncAttachmentService {

    private final SyncAttachmentRepository attachmentRepository;
    private final S3Service s3Service;

    @Transactional
    public SyncAttachmentUploadResponse upload(
            Long userId,
            String deviceId,
            String clientAttachmentId,
            SyncAttachmentPurpose purpose,
            MultipartFile arquivo
    ) {
        String contentHash = hash(arquivo);

        if (clientAttachmentId != null && !clientAttachmentId.isBlank()) {
            var existente = attachmentRepository.findByUsuarioIdAndDeviceIdAndClientAttachmentId(
                    userId,
                    deviceId,
                    clientAttachmentId
            );
            if (existente.isPresent()) {
                validateReusedAttachment(existente.get(), purpose, arquivo, contentHash);
                return toResponse(existente.get());
            }
        }

        String storageUrl = s3Service.upload(arquivo, "sync/" + userId);
        Usuario usuario = new Usuario();
        usuario.setId(userId);

        SyncAttachment attachment = SyncAttachment.builder()
                .id(UUID.randomUUID())
                .usuario(usuario)
                .deviceId(deviceId)
                .clientAttachmentId(clientAttachmentId)
                .purpose(purpose)
                .status(SyncAttachmentStatus.UPLOADED)
                .storageUrl(storageUrl)
                .contentType(arquivo.getContentType())
                .fileSize(arquivo.getSize())
                .contentHash(contentHash)
                .build();

        return toResponse(attachmentRepository.save(attachment));
    }

    @Transactional(readOnly = true)
    public String resolveUploadedUrl(UUID attachmentId, Long userId, String deviceId) {
        SyncAttachment attachment = attachmentRepository.findByIdAndUsuarioIdAndDeviceId(attachmentId, userId, deviceId)
                .orElseThrow(() -> SyncProcessException.failed(
                        SyncErrorCode.ATTACHMENT_NOT_READY,
                        "Anexo de sync nao encontrado"
                ));

        if (attachment.getStatus() != SyncAttachmentStatus.UPLOADED
            && attachment.getStatus() != SyncAttachmentStatus.LINKED) {
            throw SyncProcessException.failed(
                    SyncErrorCode.ATTACHMENT_NOT_READY,
                    "Anexo ainda nao esta pronto para sincronizacao"
            );
        }

        return attachment.getStorageUrl();
    }

    @Transactional
    public void linkToVisita(UUID attachmentId, Long userId, String deviceId, Long visitaId) {
        SyncAttachment attachment = attachmentRepository.findByIdAndUsuarioIdAndDeviceId(attachmentId, userId, deviceId)
                .orElseThrow(() -> SyncProcessException.failed(
                        SyncErrorCode.ATTACHMENT_NOT_READY,
                        "Anexo de sync nao encontrado"
                ));

        if (attachment.getStatus() == SyncAttachmentStatus.LINKED) {
            if (attachment.getLinkedEntityType() == SyncEntityType.VISITA
                && visitaId.equals(attachment.getLinkedEntityId())) {
                return;
            }
            throw SyncProcessException.failed(
                    SyncErrorCode.ATTACHMENT_NOT_READY,
                    "Anexo ja foi vinculado a outro registro"
            );
        }

        attachment.setStatus(SyncAttachmentStatus.LINKED);
        attachment.setLinkedEntityType(SyncEntityType.VISITA);
        attachment.setLinkedEntityId(visitaId);
        attachment.setLinkedAt(LocalDateTime.now());
        attachmentRepository.save(attachment);
    }

    private void validateReusedAttachment(
            SyncAttachment existing,
            SyncAttachmentPurpose purpose,
            MultipartFile arquivo,
            String contentHash
    ) {
        boolean samePurpose = existing.getPurpose() == purpose;
        boolean sameContentType = equalsNullable(existing.getContentType(), arquivo.getContentType());
        boolean sameFileSize = equalsNullable(existing.getFileSize(), arquivo.getSize());
        boolean sameHash = equalsNullable(existing.getContentHash(), contentHash);

        if (!samePurpose || !sameContentType || !sameFileSize || !sameHash) {
            throw new BusinessException(
                    "clientAttachmentId ja foi utilizado com outro arquivo neste dispositivo"
            );
        }
    }

    private boolean equalsNullable(Object left, Object right) {
        return left == null ? right == null : left.equals(right);
    }

    private String hash(MultipartFile arquivo) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] rawHash = digest.digest(arquivo.getBytes());
            return HexFormat.of().formatHex(rawHash);
        } catch (Exception ex) {
            throw new BusinessException("Nao foi possivel calcular o hash do anexo de sync");
        }
    }

    private SyncAttachmentUploadResponse toResponse(SyncAttachment attachment) {
        return new SyncAttachmentUploadResponse(
                attachment.getId(),
                attachment.getClientAttachmentId(),
                attachment.getDeviceId(),
                attachment.getPurpose(),
                attachment.getStatus(),
                attachment.getStorageUrl()
        );
    }
}
