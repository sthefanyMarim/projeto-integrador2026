package com.ufsm.projeto_integrador.controller;

import com.ufsm.projeto_integrador.domain.dto.common.PageResponse;
import com.ufsm.projeto_integrador.domain.dto.visita.FinalizarVisitaRequest;
import com.ufsm.projeto_integrador.domain.dto.visita.VisitaDetalheResponse;
import com.ufsm.projeto_integrador.domain.dto.visita.VisitaRequest;
import com.ufsm.projeto_integrador.domain.dto.visita.VisitaResponse;
import com.ufsm.projeto_integrador.domain.enums.StatusVisita;
import com.ufsm.projeto_integrador.security.SecurityUtils;
import com.ufsm.projeto_integrador.service.VisitaTecnicaService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.net.URI;
import java.util.List;

@RestController
@RequestMapping("/api/visitas")
@RequiredArgsConstructor
@Tag(name = "Visitas Técnicas", description = "Agendamento, edição, finalização e cancelamento de visitas")
public class VisitaTecnicaController {

    private final VisitaTecnicaService service;

    @GetMapping("/hoje")
    @Operation(summary = "Visitas do dia do usuário logado")
    public ResponseEntity<List<VisitaResponse>> hoje() {
        return ResponseEntity.ok(service.listarHoje(SecurityUtils.getCurrentUserId()));
    }

    @GetMapping
    @Operation(summary = "Listar visitas com filtros e paginação")
    public ResponseEntity<PageResponse<VisitaResponse>> listar(
            @RequestParam(required = false) StatusVisita status,
            @RequestParam(required = false) Long propriedadeId,
            @PageableDefault(size = 20, sort = "dataVisita") Pageable pageable) {
        return ResponseEntity.ok(service.listar(status, propriedadeId, pageable));
    }

    @GetMapping("/{id}")
    @Operation(summary = "Buscar visita por ID")
    public ResponseEntity<VisitaResponse> buscarPorId(@PathVariable Long id) {
        return ResponseEntity.ok(service.buscarPorId(id));
    }

    @GetMapping("/{id}/detalhes")
    @Operation(summary = "Buscar detalhes completos de uma visita (diagnósticos e encaminhamentos)")
    public ResponseEntity<VisitaDetalheResponse> buscarDetalhes(@PathVariable Long id) {
        return ResponseEntity.ok(service.buscarDetalhes(id));
    }

    @PostMapping
    @Operation(summary = "Agendar nova visita")
    public ResponseEntity<VisitaResponse> agendar(@Valid @RequestBody VisitaRequest request) {
        VisitaResponse response = service.agendar(request);
        return ResponseEntity.created(URI.create("/api/visitas/" + response.id())).body(response);
    }

    @PutMapping("/{id}")
    @Operation(summary = "Editar dados do agendamento")
    public ResponseEntity<VisitaResponse> atualizar(
            @PathVariable Long id,
            @Valid @RequestBody VisitaRequest request) {
        return ResponseEntity.ok(service.atualizar(id, request));
    }

    @PostMapping("/{id}/finalizar")
    @Operation(summary = "Finalizar visita — preenche diagnósticos e encaminhamentos (3 etapas)")
    public ResponseEntity<VisitaResponse> finalizar(
            @PathVariable Long id,
            @Valid @RequestBody FinalizarVisitaRequest request) {
        return ResponseEntity.ok(service.finalizar(id, request));
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Cancelar visita")
    public ResponseEntity<Void> cancelar(@PathVariable Long id) {
        service.cancelar(id);
        return ResponseEntity.noContent().build();
    }
}
