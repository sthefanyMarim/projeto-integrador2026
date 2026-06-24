package com.ufsm.projeto_integrador.domain.dto.diagnostico;

import com.ufsm.projeto_integrador.domain.enums.Criticidade;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record DiagnosticoRequest(
        @NotBlank(message = "Categoria obrigatória") @Size(max = 100) String categoria,
        @NotNull(message = "Criticidade obrigatória") Criticidade criticidade,
        String observacoes,
        String imagemUrl
) {}
