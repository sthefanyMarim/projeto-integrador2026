package com.ufsm.projeto_integrador.domain.dto.propriedade;

import com.ufsm.projeto_integrador.domain.enums.TipoProducao;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;

public record PropriedadeRequest(
        @NotBlank(message = "Nome obrigatório") @Size(max = 150) String nome,
        @NotBlank(message = "Nome do proprietário obrigatório") @Size(max = 150) String nomeProprietario,
        @NotBlank(message = "Telefone obrigatório")
        @Pattern(regexp = "^\\(\\d{2}\\) \\d{4,5}-\\d{4}$",
                message = "Telefone deve estar no formato (DD) 9999-9999 ou (DD) 99999-9999")
        String telefone,
        @Size(max = 255) String endereco,
        @Size(max = 100) String municipio,
        @Size(max = 2) String estado,
        @DecimalMin(value = "-90.0", message = "Latitude deve estar entre -90 e 90") @DecimalMax(value = "90.0", message = "Latitude deve estar entre -90 e 90") BigDecimal latitude,
        @DecimalMin(value = "-180.0", message = "Longitude deve estar entre -180 e 180") @DecimalMax(value = "180.0", message = "Longitude deve estar entre -180 e 180") BigDecimal longitude,
        TipoProducao tipoProducao,
        Boolean ativa
) {}
