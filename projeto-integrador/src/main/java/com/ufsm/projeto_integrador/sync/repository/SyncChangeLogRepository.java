package com.ufsm.projeto_integrador.sync.repository;

import com.ufsm.projeto_integrador.sync.domain.entity.SyncChangeLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface SyncChangeLogRepository extends JpaRepository<SyncChangeLog, Long> {

    @Query("""
            select c
            from SyncChangeLog c
            where c.changeId > :afterToken
              and (c.ownerUserId is null or c.ownerUserId = :userId)
            order by c.changeId asc
            """)
    List<SyncChangeLog> findVisibleChangesAfter(
            @Param("afterToken") Long afterToken,
            @Param("userId") Long userId
    );
}
