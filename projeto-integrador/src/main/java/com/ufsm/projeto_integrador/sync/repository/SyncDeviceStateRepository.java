package com.ufsm.projeto_integrador.sync.repository;

import com.ufsm.projeto_integrador.sync.domain.entity.SyncDeviceState;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface SyncDeviceStateRepository extends JpaRepository<SyncDeviceState, Long> {

    Optional<SyncDeviceState> findByUsuarioIdAndDeviceId(Long userId, String deviceId);
}
