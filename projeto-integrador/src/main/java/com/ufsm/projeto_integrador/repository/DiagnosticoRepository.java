package com.ufsm.projeto_integrador.repository;

import com.ufsm.projeto_integrador.domain.entity.Diagnostico;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;

@Repository
public interface DiagnosticoRepository extends JpaRepository<Diagnostico, Long> {

    List<Diagnostico> findByVisitaIdOrderByCriadoEmAsc(Long visitaId);

    void deleteByVisitaId(Long visitaId);

    @Query("SELECT COUNT(d) FROM Diagnostico d WHERE d.visita.dataVisita BETWEEN :inicio AND :fim")
    long countInPeriod(@Param("inicio") LocalDate inicio, @Param("fim") LocalDate fim);

    @Query("SELECT d.categoria, COUNT(d) FROM Diagnostico d WHERE d.visita.dataVisita BETWEEN :inicio AND :fim GROUP BY d.categoria ORDER BY COUNT(d) DESC")
    List<Object[]> countByCategoriaInPeriod(@Param("inicio") LocalDate inicio, @Param("fim") LocalDate fim);

    @Query("SELECT d.criticidade, COUNT(d) FROM Diagnostico d WHERE d.visita.dataVisita BETWEEN :inicio AND :fim GROUP BY d.criticidade")
    List<Object[]> countByCriticidadeInPeriod(@Param("inicio") LocalDate inicio, @Param("fim") LocalDate fim);

    @Query("SELECT d.visita.propriedade.id, d.visita.propriedade.nome, COUNT(d) FROM Diagnostico d WHERE d.visita.dataVisita BETWEEN :inicio AND :fim AND d.criticidade IN ('ALTA', 'CRITICA') GROUP BY d.visita.propriedade.id, d.visita.propriedade.nome ORDER BY COUNT(d) DESC")
    List<Object[]> rankPropriedadesDiagnosticosCriticos(@Param("inicio") LocalDate inicio, @Param("fim") LocalDate fim, org.springframework.data.domain.Pageable pageable);

    @Query("SELECT d FROM Diagnostico d WHERE d.visita.propriedade.id = :propId AND d.visita.dataVisita BETWEEN :inicio AND :fim ORDER BY d.visita.dataVisita DESC")
    List<Diagnostico> findByPropriedadeAndPeriod(@Param("propId") Long propId, @Param("inicio") LocalDate inicio, @Param("fim") LocalDate fim);
}
