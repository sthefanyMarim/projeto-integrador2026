package com.ufsm.projeto_integrador.repository;

import com.ufsm.projeto_integrador.domain.entity.VisitaTecnica;
import com.ufsm.projeto_integrador.domain.enums.StatusVisita;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import org.springframework.data.domain.Pageable;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;

@Repository
public interface VisitaTecnicaRepository extends JpaRepository<VisitaTecnica, Long>, JpaSpecificationExecutor<VisitaTecnica> {

    List<VisitaTecnica> findByUsuarioIdAndDataVisitaOrderByHoraVisitaAsc(
            Long usuarioId, LocalDate data);

    @Query("SELECT v FROM VisitaTecnica v WHERE v.statusVisita = 'AGENDADA' AND " +
           "(v.dataVisita < :hoje OR (v.dataVisita = :hoje AND v.horaVisita < :agora))")
    List<VisitaTecnica> findAtrasadas(@Param("hoje") LocalDate hoje, @Param("agora") LocalTime agora);

    long countByUsuarioIdAndStatusVisita(Long usuarioId, StatusVisita status);

    long countByUsuarioId(Long usuarioId);

    @Query("SELECT COUNT(v) FROM VisitaTecnica v WHERE v.usuario.id = :userId " +
           "AND v.statusVisita = 'AGENDADA' " +
           "AND (v.dataVisita < :hoje OR (v.dataVisita = :hoje AND v.horaVisita < :agora))")
    long countAtrasadasPorUsuario(@Param("userId") Long userId,
                                  @Param("hoje") LocalDate hoje,
                                  @Param("agora") LocalTime agora);

    @Query("SELECT v FROM VisitaTecnica v WHERE v.usuario.id = :userId " +
           "AND v.dataVisita = :data " +
           "AND v.statusVisita <> 'CANCELADA'")
    List<VisitaTecnica> findAtivasByUsuarioAndData(@Param("userId") Long userId,
                                                   @Param("data") LocalDate data);

    long countByPropriedadeId(Long propriedadeId);

    long countByUsuarioIdAndStatusVisitaAndDataVisitaGreaterThanEqual(
            Long usuarioId, StatusVisita statusVisita, LocalDate data);

    @Query("SELECT COUNT(v) FROM VisitaTecnica v WHERE v.dataVisita BETWEEN :inicio AND :fim")
    long countInPeriod(@Param("inicio") LocalDate inicio, @Param("fim") LocalDate fim);

    @Query("SELECT v.statusVisita, COUNT(v) FROM VisitaTecnica v WHERE v.dataVisita BETWEEN :inicio AND :fim GROUP BY v.statusVisita")
    List<Object[]> countByStatusInPeriod(@Param("inicio") LocalDate inicio, @Param("fim") LocalDate fim);

    @Query("SELECT v.tipoVisita, COUNT(v) FROM VisitaTecnica v WHERE v.dataVisita BETWEEN :inicio AND :fim GROUP BY v.tipoVisita")
    List<Object[]> countByTipoInPeriod(@Param("inicio") LocalDate inicio, @Param("fim") LocalDate fim);

    @Query("SELECT v.propriedade.id, v.propriedade.nome, COUNT(v) FROM VisitaTecnica v WHERE v.dataVisita BETWEEN :inicio AND :fim GROUP BY v.propriedade.id, v.propriedade.nome ORDER BY COUNT(v) DESC")
    List<Object[]> rankPropriedadesVisitadas(@Param("inicio") LocalDate inicio, @Param("fim") LocalDate fim, Pageable pageable);

    @Query("SELECT v.usuario.id, v.usuario.nome, COUNT(v) FROM VisitaTecnica v WHERE v.dataVisita BETWEEN :inicio AND :fim AND v.statusVisita = 'CONCLUIDA' GROUP BY v.usuario.id, v.usuario.nome ORDER BY COUNT(v) DESC")
    List<Object[]> rankTecnicosPorVisitasConcluidas(@Param("inicio") LocalDate inicio, @Param("fim") LocalDate fim, Pageable pageable);

    @Query("SELECT v FROM VisitaTecnica v WHERE v.propriedade.id = :propId AND v.dataVisita BETWEEN :inicio AND :fim ORDER BY v.dataVisita DESC, v.horaVisita DESC")
    List<VisitaTecnica> findByPropriedadeAndPeriod(@Param("propId") Long propId, @Param("inicio") LocalDate inicio, @Param("fim") LocalDate fim);

}
