package com.ufsm.projeto_integrador.repository;

import com.ufsm.projeto_integrador.domain.entity.Encaminhamento;
import com.ufsm.projeto_integrador.domain.enums.StatusEncaminhamento;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;

@Repository
public interface EncaminhamentoRepository extends JpaRepository<Encaminhamento, Long>, JpaSpecificationExecutor<Encaminhamento> {

    List<Encaminhamento> findByVisitaIdOrderByPrazoAsc(Long visitaId);

    long countByVisitaUsuarioIdAndStatus(Long userId, StatusEncaminhamento status);

    @Modifying
    @Query("UPDATE Encaminhamento e SET e.status = 'ATRASADO' " +
           "WHERE e.prazo < :hoje AND e.status = 'PENDENTE'")
    int marcarComoAtrasados(@Param("hoje") LocalDate hoje);
}
