package com.ufsm.projeto_integrador.domain.dto.encaminhamento;

import com.ufsm.projeto_integrador.domain.enums.Prioridade;
import com.ufsm.projeto_integrador.domain.enums.Verificacao;
import jakarta.validation.constraints.NotBlank;

import java.time.LocalDate;

public record EncaminhamentoRequest(
        @NotBlank(message = "Ação realizada obrigatória") String acaoRealizada,
        String responsavel,
        LocalDate prazo,
        Verificacao verificacao,
        Prioridade prioridade
) {}
