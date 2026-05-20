package com.ufsm.projeto_integrador.repository;

import com.ufsm.projeto_integrador.domain.entity.Diagnostico;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface DiagnosticoRepository extends JpaRepository<Diagnostico, Long> {

    List<Diagnostico> findByVisitaIdOrderByCriadoEmAsc(Long visitaId);

    void deleteByVisitaId(Long visitaId);
}
