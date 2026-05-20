package com.ufsm.projeto_integrador.repository;

import com.ufsm.projeto_integrador.domain.entity.VisitaTecnica;
import com.ufsm.projeto_integrador.domain.enums.StatusVisita;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;

@Repository
public interface VisitaTecnicaRepository extends JpaRepository<VisitaTecnica, Long>, JpaSpecificationExecutor<VisitaTecnica> {

    List<VisitaTecnica> findByUsuarioIdAndDataVisitaOrderByHoraVisitaAsc(
            Long usuarioId, LocalDate data);

    long countByUsuarioIdAndStatusVisita(Long usuarioId, StatusVisita status);

    long countByUsuarioId(Long usuarioId);

    @Query("SELECT COUNT(v) FROM VisitaTecnica v WHERE v.usuario.id = :userId " +
           "AND v.dataVisita < :hoje AND v.statusVisita = 'AGENDADA'")
    long countAtrasadasPorUsuario(@Param("userId") Long userId,
                                  @Param("hoje") LocalDate hoje);

    @Modifying
    @Query("UPDATE VisitaTecnica v SET v.statusVisita = 'ATRASADA' " +
           "WHERE v.dataVisita < :hoje AND v.statusVisita = 'AGENDADA'")
    int marcarComoAtrasadas(@Param("hoje") LocalDate hoje);
}
