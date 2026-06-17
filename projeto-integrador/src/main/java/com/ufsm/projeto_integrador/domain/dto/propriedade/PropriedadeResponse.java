package com.ufsm.projeto_integrador.domain.dto.propriedade;

import com.ufsm.projeto_integrador.domain.entity.Propriedade;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public record PropriedadeResponse(
        Long id,
        String nome,
        String nomeProprietario,
        String telefone,
        String endereco,
        String municipio,
        String estado,
        BigDecimal latitude,
        BigDecimal longitude,
        String tipoProducao,
        Boolean ativa,
        Long version,
        LocalDateTime criadoEm,
        LocalDateTime atualizadoEm
) {
    public static PropriedadeResponse from(Propriedade p) {
        return new PropriedadeResponse(
                p.getId(), p.getNome(), p.getNomeProprietario(),
                p.getTelefone(), p.getEndereco(), p.getMunicipio(),
                p.getEstado(), p.getLatitude(), p.getLongitude(),
                p.getTipoProducao(), p.getAtiva(), p.getVersion(),
                p.getCriadoEm(), p.getAtualizadoEm());
    }
}
