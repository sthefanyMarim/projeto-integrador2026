package com.ufsm.projeto_integrador.domain.dto.common;

import com.ufsm.projeto_integrador.domain.dto.encaminhamento.EncaminhamentoResponse;
import com.ufsm.projeto_integrador.domain.dto.visita.VisitaResponse;

import java.util.List;

public record DashboardResponse(
        String nomeUsuario,
        long totalPropriedades,
        long visitasAtrasadas,
        long pendenciasUrgentes,
        List<VisitaResponse> visitasHoje,
        List<EncaminhamentoResponse> pendenciasUrgentesLista
) {}
