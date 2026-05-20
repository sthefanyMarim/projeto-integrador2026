package com.ufsm.projeto_integrador.domain.dto.visita;

import com.ufsm.projeto_integrador.domain.dto.diagnostico.DiagnosticoRequest;
import com.ufsm.projeto_integrador.domain.dto.encaminhamento.EncaminhamentoRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;

import java.util.List;

public record FinalizarVisitaRequest(
        @NotEmpty(message = "Ao menos um diagnóstico é obrigatório")
        @Valid List<DiagnosticoRequest> diagnosticos,

        @NotEmpty(message = "Ao menos um encaminhamento é obrigatório")
        @Valid List<EncaminhamentoRequest> encaminhamentos,

        String observacoesGerais
) {}
