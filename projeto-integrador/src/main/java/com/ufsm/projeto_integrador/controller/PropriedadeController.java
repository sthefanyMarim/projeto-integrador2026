package com.ufsm.projeto_integrador.controller;

import com.ufsm.projeto_integrador.domain.dto.common.PageResponse;
import com.ufsm.projeto_integrador.domain.dto.propriedade.PropriedadeRequest;
import com.ufsm.projeto_integrador.domain.dto.propriedade.PropriedadeResponse;
import com.ufsm.projeto_integrador.service.PropriedadeService;
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
@RequestMapping("/api/propriedades")
@RequiredArgsConstructor
@Tag(name = "Propriedades", description = "Gestão de propriedades rurais / feirantes")
public class PropriedadeController {

    private final PropriedadeService service;

    @GetMapping("/ativas")
    @Operation(summary = "Listar todas as propriedades ativas (sem paginação, para selects)")
    public ResponseEntity<List<PropriedadeResponse>> listarAtivas() {
        return ResponseEntity.ok(service.listarAtivas());
    }

    @GetMapping
    @Operation(summary = "Listar propriedades com filtro e paginação")
    public ResponseEntity<PageResponse<PropriedadeResponse>> listar(
            @RequestParam(required = false) String busca,
            @RequestParam(required = false) Boolean ativa,
            @PageableDefault(size = 20, sort = "nome") Pageable pageable) {
        return ResponseEntity.ok(service.listar(busca, ativa, pageable));
    }

    @GetMapping("/{id}")
    @Operation(summary = "Buscar propriedade por ID")
    public ResponseEntity<PropriedadeResponse> buscarPorId(@PathVariable Long id) {
        return ResponseEntity.ok(service.buscarPorId(id));
    }

    @PostMapping
    @Operation(summary = "Cadastrar nova propriedade")
    public ResponseEntity<PropriedadeResponse> criar(@Valid @RequestBody PropriedadeRequest request) {
        PropriedadeResponse response = service.criar(request);
        return ResponseEntity.created(URI.create("/api/propriedades/" + response.id())).body(response);
    }

    @PutMapping("/{id}")
    @Operation(summary = "Atualizar dados da propriedade")
    public ResponseEntity<PropriedadeResponse> atualizar(
            @PathVariable Long id,
            @Valid @RequestBody PropriedadeRequest request) {
        return ResponseEntity.ok(service.atualizar(id, request));
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Excluir propriedade")
    public ResponseEntity<Void> deletar(@PathVariable Long id) {
        service.deletar(id);
        return ResponseEntity.noContent().build();
    }
}
