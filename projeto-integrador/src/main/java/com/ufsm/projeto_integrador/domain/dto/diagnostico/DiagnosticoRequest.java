package com.ufsm.projeto_integrador.domain.dto.diagnostico;

import com.ufsm.projeto_integrador.domain.enums.Criticidade;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record DiagnosticoRequest(
        @NotBlank(message = "Categoria obrigatória") String categoria,
        @NotNull(message = "Criticidade obrigatória") Criticidade criticidade,
        String observacoes
) {}
