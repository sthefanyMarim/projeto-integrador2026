package com.ufsm.projeto_integrador.domain.dto.encaminhamento;

import com.ufsm.projeto_integrador.domain.enums.Prioridade;
import com.ufsm.projeto_integrador.domain.enums.Verificacao;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.LocalDate;

public record EncaminhamentoRequest(
        @NotBlank(message = "Ação realizada obrigatória") String acaoRealizada,
        @Size(max = 150) String responsavel,
        LocalDate prazo,
        @NotNull(message = "Forma de verificação obrigatória") Verificacao verificacao,
        Prioridade prioridade
) {}
