package com.ufsm.projeto_integrador.controller;

import com.ufsm.projeto_integrador.domain.dto.common.DashboardResponse;
import com.ufsm.projeto_integrador.security.SecurityUtils;
import com.ufsm.projeto_integrador.service.DashboardService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/dashboard")
@RequiredArgsConstructor
@Tag(name = "Dashboard", description = "Tela principal — resumo do dia do técnico")
public class DashboardController {

    private final DashboardService service;

    @GetMapping
    @Operation(summary = "Retorna dados do dashboard do usuário logado")
    public ResponseEntity<DashboardResponse> getDashboard() {
        return ResponseEntity.ok(service.getDashboard(SecurityUtils.getCurrentUserId()));
    }
}
