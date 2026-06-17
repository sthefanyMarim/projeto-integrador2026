package com.ufsm.projeto_integrador.service;

import com.ufsm.projeto_integrador.domain.dto.common.PageResponse;
import com.ufsm.projeto_integrador.domain.dto.propriedade.PropriedadeRequest;
import com.ufsm.projeto_integrador.domain.dto.propriedade.PropriedadeResponse;
import com.ufsm.projeto_integrador.domain.entity.Propriedade;
import com.ufsm.projeto_integrador.exception.BusinessException;
import com.ufsm.projeto_integrador.exception.ResourceNotFoundException;
import com.ufsm.projeto_integrador.repository.PropriedadeRepository;
import com.ufsm.projeto_integrador.repository.VisitaTecnicaRepository;
import com.ufsm.projeto_integrador.repository.spec.PropriedadeSpecifications;
import com.ufsm.projeto_integrador.security.SecurityUtils;
import com.ufsm.projeto_integrador.sync.service.SyncChangeService;
import lombok.RequiredArgsConstructor;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.List;

@Service
@RequiredArgsConstructor
public class PropriedadeService {

    private final PropriedadeRepository repository;
    private final VisitaTecnicaRepository visitaTecnicaRepository;
    private final SyncChangeService syncChangeService;

    @Cacheable(value = "propriedades", key = "'todas-ativas'")
    public List<PropriedadeResponse> listarAtivas() {
        return repository.findByAtivaTrue().stream().map(PropriedadeResponse::from).toList();
    }

    public PageResponse<PropriedadeResponse> listar(String busca, Boolean ativa, Pageable pageable) {
        Specification<Propriedade> specification = PropriedadeSpecifications.comBusca(busca)
                .and(PropriedadeSpecifications.comStatus(ativa));

        return PageResponse.from(repository.findAll(specification, pageable).map(PropriedadeResponse::from));
    }

    public PropriedadeResponse buscarPorId(Long id) {
        return PropriedadeResponse.from(findOrThrow(id));
    }

    @CacheEvict(value = {"propriedades", "dashboard"}, allEntries = true)
    @Transactional
    public PropriedadeResponse criar(PropriedadeRequest req) {
        Propriedade propriedade = Propriedade.builder()
                .nome(req.nome())
                .nomeProprietario(req.nomeProprietario())
                .telefone(req.telefone())
                .endereco(req.endereco())
                .municipio(req.municipio())
                .estado(req.estado() != null ? req.estado() : "RS")
                .latitude(normalizarCoordenada(req.latitude()))
                .longitude(normalizarCoordenada(req.longitude()))
                .tipoProducao(req.tipoProducao())
                .ativa(req.ativa() != null ? req.ativa() : true)
                .build();
        Propriedade salva = repository.save(propriedade);
        syncChangeService.recordPropriedadeUpsert(salva, SecurityUtils.getCurrentUserIdOrNull());
        return PropriedadeResponse.from(salva);
    }

    @CacheEvict(value = {"propriedades", "dashboard"}, allEntries = true)
    @Transactional
    public PropriedadeResponse atualizar(Long id, PropriedadeRequest req) {
        Propriedade propriedade = findOrThrow(id);
        propriedade.setNome(req.nome());
        propriedade.setNomeProprietario(req.nomeProprietario());
        propriedade.setTelefone(req.telefone());
        propriedade.setEndereco(req.endereco());
        propriedade.setMunicipio(req.municipio());
        if (req.estado() != null) {
            propriedade.setEstado(req.estado());
        }
        propriedade.setLatitude(normalizarCoordenada(req.latitude()));
        propriedade.setLongitude(normalizarCoordenada(req.longitude()));
        propriedade.setTipoProducao(req.tipoProducao());
        if (req.ativa() != null) {
            propriedade.setAtiva(req.ativa());
        }
        Propriedade salva = repository.save(propriedade);
        syncChangeService.recordPropriedadeUpsert(salva, SecurityUtils.getCurrentUserIdOrNull());
        return PropriedadeResponse.from(salva);
    }

    @CacheEvict(value = {"propriedades", "dashboard"}, allEntries = true)
    @Transactional
    public void deletar(Long id) {
        Propriedade propriedade = findOrThrow(id);
        long totalVisitas = visitaTecnicaRepository.countByPropriedadeId(id);
        if (totalVisitas > 0) {
            throw new BusinessException(
                "Não é possível excluir esta propriedade pois ela possui " + totalVisitas +
                " visita(s) registrada(s). Para removê-la do sistema, desative-a em vez de excluir."
            );
        }
        repository.deleteById(id);
        syncChangeService.recordPropriedadeDelete(
                id,
                propriedade.getVersion(),
                SecurityUtils.getCurrentUserIdOrNull()
        );
    }

    private Propriedade findOrThrow(Long id) {
        return repository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Propriedade nao encontrada: " + id));
    }

    private BigDecimal normalizarCoordenada(BigDecimal valor) {
        if (valor == null) {
            return null;
        }
        return valor.setScale(7, RoundingMode.HALF_UP);
    }
}
