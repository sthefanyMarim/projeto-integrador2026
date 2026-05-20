package com.ufsm.projeto_integrador.repository;

import com.ufsm.projeto_integrador.domain.entity.Propriedade;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface PropriedadeRepository extends JpaRepository<Propriedade, Long>, JpaSpecificationExecutor<Propriedade> {

    List<Propriedade> findByAtivaTrue();

    long countByAtivaTrue();
}
