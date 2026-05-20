package com.ufsm.projeto_integrador.domain.dto.propriedade;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;

public record PropriedadeRequest(
        @NotBlank(message = "Nome obrigatório") @Size(max = 150) String nome,
        @NotBlank(message = "Nome do proprietário obrigatório") @Size(max = 150) String nomeProprietario,
        String telefone,
        String endereco,
        String municipio,
        String estado,
        @DecimalMin(value = "-90.0", message = "Latitude deve estar entre -90 e 90") @DecimalMax(value = "90.0", message = "Latitude deve estar entre -90 e 90") BigDecimal latitude,
        @DecimalMin(value = "-180.0", message = "Longitude deve estar entre -180 e 180") @DecimalMax(value = "180.0", message = "Longitude deve estar entre -180 e 180") BigDecimal longitude,
        String tipoProducao,
        Boolean ativa
) {}
