package com.ufsm.projeto_integrador.controller;

import com.ufsm.projeto_integrador.security.SecurityUtils;
import com.ufsm.projeto_integrador.sync.dto.SyncAttachmentUploadResponse;
import com.ufsm.projeto_integrador.sync.dto.SyncRequest;
import com.ufsm.projeto_integrador.sync.dto.SyncResponse;
import com.ufsm.projeto_integrador.sync.enums.SyncAttachmentPurpose;
import com.ufsm.projeto_integrador.sync.service.SyncAttachmentService;
import com.ufsm.projeto_integrador.sync.service.SyncService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/sync")
@RequiredArgsConstructor
@Tag(name = "Sync", description = "Sincronizacao bloqueante para operacoes offline do aplicativo")
public class SyncController {

    private final SyncService syncService;
    private final SyncAttachmentService attachmentService;

    @PostMapping
    @Operation(summary = "Executa uma sessao bloqueante de sincronizacao")
    public ResponseEntity<SyncResponse> synchronize(@Valid @RequestBody SyncRequest request) {
        return ResponseEntity.ok(syncService.synchronize(request));
    }

    @PostMapping("/attachments")
    @Operation(summary = "Faz upload antecipado de anexos usados no sync offline")
    public ResponseEntity<SyncAttachmentUploadResponse> uploadAttachment(
            @RequestParam String deviceId,
            @RequestParam(required = false) String clientAttachmentId,
            @RequestParam SyncAttachmentPurpose purpose,
            @RequestParam("arquivo") MultipartFile arquivo
    ) {
        Long userId = SecurityUtils.getCurrentUserId();
        return ResponseEntity.ok(
                attachmentService.upload(userId, deviceId, clientAttachmentId, purpose, arquivo)
        );
    }
}
