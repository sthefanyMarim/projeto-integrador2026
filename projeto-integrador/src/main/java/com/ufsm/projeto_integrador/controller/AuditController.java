package com.ufsm.projeto_integrador.controller;

import com.ufsm.projeto_integrador.domain.dto.common.PageResponse;
import com.ufsm.projeto_integrador.domain.entity.AuditLog;
import com.ufsm.projeto_integrador.repository.AuditLogRepository;
import com.ufsm.projeto_integrador.service.AuditService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/audit")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
@Tag(name = "Audit Log", description = "Histórico de todas as alterações no banco (somente ADMIN)")
public class AuditController {

    private final AuditLogRepository repository;
    private final AuditService service;

    @GetMapping
    @Operation(summary = "Listar audit logs com filtro de tabela e usuário")
    public ResponseEntity<PageResponse<AuditLog>> listar(
            @RequestParam(required = false) String tabela,
            @RequestParam(required = false) Long userId,
            @PageableDefault(size = 30, sort = "alteradoEm") Pageable pageable) {
        return ResponseEntity.ok(service.listar(tabela, userId, pageable));
    }

    @GetMapping("/{tabela}/{registroId}")
    @Operation(summary = "Histórico completo de um registro específico")
    public ResponseEntity<List<AuditLog>> historico(
            @PathVariable String tabela,
            @PathVariable Long registroId) {
        return ResponseEntity.ok(
                repository.findByTabelaAndRegistroIdOrderByAlteradoEmDesc(tabela, registroId));
    }
}
