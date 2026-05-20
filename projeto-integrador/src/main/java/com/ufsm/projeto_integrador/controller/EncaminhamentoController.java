package com.ufsm.projeto_integrador.controller;

import com.ufsm.projeto_integrador.domain.dto.common.PageResponse;
import com.ufsm.projeto_integrador.domain.dto.encaminhamento.EncaminhamentoResponse;
import com.ufsm.projeto_integrador.domain.enums.StatusEncaminhamento;
import com.ufsm.projeto_integrador.service.EncaminhamentoService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/encaminhamentos")
@RequiredArgsConstructor
@Tag(name = "Encaminhamentos", description = "Gestão de pendências das visitas técnicas")
public class EncaminhamentoController {

    private final EncaminhamentoService service;

    @GetMapping
    @Operation(summary = "Listar encaminhamentos do usuário logado com filtro de status")
    public ResponseEntity<PageResponse<EncaminhamentoResponse>> listar(
            @RequestParam(required = false) StatusEncaminhamento status,
            @PageableDefault(size = 20, sort = "prazo") Pageable pageable) {
        return ResponseEntity.ok(service.listarMeus(status, pageable));
    }

    @PostMapping("/{id}/concluir")
    @Operation(summary = "Marcar encaminhamento como concluído")
    public ResponseEntity<EncaminhamentoResponse> concluir(@PathVariable Long id) {
        return ResponseEntity.ok(service.concluir(id));
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Cancelar encaminhamento")
    public ResponseEntity<Void> cancelar(@PathVariable Long id) {
        service.cancelar(id);
        return ResponseEntity.noContent().build();
    }
}
