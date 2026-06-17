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

    List<Encaminhamento> findByPrazoBeforeAndStatus(LocalDate hoje, StatusEncaminhamento status);

    long countByVisitaUsuarioIdAndStatus(Long userId, StatusEncaminhamento status);

    @Query("SELECT COUNT(e) FROM Encaminhamento e WHERE e.visita.dataVisita BETWEEN :inicio AND :fim")
    long countInPeriod(@Param("inicio") LocalDate inicio, @Param("fim") LocalDate fim);

    @Query("SELECT e.status, COUNT(e) FROM Encaminhamento e WHERE e.visita.dataVisita BETWEEN :inicio AND :fim GROUP BY e.status")
    List<Object[]> countByStatusInPeriod(@Param("inicio") LocalDate inicio, @Param("fim") LocalDate fim);

    @Query("SELECT COUNT(e) FROM Encaminhamento e WHERE e.visita.dataVisita BETWEEN :inicio AND :fim AND e.prazo IS NOT NULL")
    long countComPrazoInPeriod(@Param("inicio") LocalDate inicio, @Param("fim") LocalDate fim);

    @Query("SELECT e FROM Encaminhamento e WHERE e.visita.propriedade.id = :propId AND e.visita.dataVisita BETWEEN :inicio AND :fim ORDER BY e.prazo ASC NULLS LAST")
    List<Encaminhamento> findByPropriedadeAndPeriod(@Param("propId") Long propId, @Param("inicio") LocalDate inicio, @Param("fim") LocalDate fim);

    @Query("SELECT e FROM Encaminhamento e WHERE e.visita.dataVisita BETWEEN :inicio AND :fim AND e.status = 'CONCLUIDO' AND e.prazo IS NOT NULL AND e.concluidoEm IS NOT NULL")
    List<Encaminhamento> findConcluidosComPrazoInPeriod(@Param("inicio") LocalDate inicio, @Param("fim") LocalDate fim);

}
