package com.ufsm.projeto_integrador.sync.domain.entity;

import com.ufsm.projeto_integrador.domain.entity.Usuario;
import com.ufsm.projeto_integrador.sync.enums.SyncAttachmentPurpose;
import com.ufsm.projeto_integrador.sync.enums.SyncAttachmentStatus;
import com.ufsm.projeto_integrador.sync.enums.SyncEntityType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "sync_attachments")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SyncAttachment {

    @Id
    @Column(name = "attachment_id", nullable = false, updatable = false)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private Usuario usuario;

    @Column(name = "device_id", nullable = false, length = 120)
    private String deviceId;

    @Column(name = "client_attachment_id", length = 120)
    private String clientAttachmentId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 40)
    private SyncAttachmentPurpose purpose;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 40)
    private SyncAttachmentStatus status;

    @Column(name = "storage_url", nullable = false, length = 500)
    private String storageUrl;

    @Column(name = "content_type", length = 120)
    private String contentType;

    @Column(name = "file_size")
    private Long fileSize;

    @Column(name = "content_hash", length = 128)
    private String contentHash;

    @Enumerated(EnumType.STRING)
    @Column(name = "linked_entity_type", length = 40)
    private SyncEntityType linkedEntityType;

    @Column(name = "linked_entity_id")
    private Long linkedEntityId;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "linked_at")
    private LocalDateTime linkedAt;
}
