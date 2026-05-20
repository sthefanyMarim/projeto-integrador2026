package com.ufsm.projeto_integrador.repository;

import com.ufsm.projeto_integrador.domain.entity.Usuario;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface UsuarioRepository extends JpaRepository<Usuario, Long>, JpaSpecificationExecutor<Usuario> {

    Optional<Usuario> findByMatricula(String matricula);

    Optional<Usuario> findByEmail(String email);

    boolean existsByMatricula(String matricula);

    boolean existsByEmail(String email);
}
