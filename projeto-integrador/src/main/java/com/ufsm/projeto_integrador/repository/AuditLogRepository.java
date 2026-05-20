package com.ufsm.projeto_integrador.repository;

import com.ufsm.projeto_integrador.domain.entity.AuditLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface AuditLogRepository extends JpaRepository<AuditLog, Long>, JpaSpecificationExecutor<AuditLog> {

    List<AuditLog> findByTabelaAndRegistroIdOrderByAlteradoEmDesc(
            String tabela, Long registroId);
}
