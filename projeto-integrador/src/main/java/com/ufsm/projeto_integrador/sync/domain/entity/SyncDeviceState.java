package com.ufsm.projeto_integrador.sync.domain.entity;

import com.ufsm.projeto_integrador.domain.entity.Usuario;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "sync_device_state")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SyncDeviceState {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private Usuario usuario;

    @Column(name = "device_id", nullable = false, length = 120)
    private String deviceId;

    @Column(name = "last_sync_token")
    private Long lastSyncToken;

    @Column(name = "last_session_id")
    private UUID lastSessionId;

    @Column(name = "last_synced_at")
    private LocalDateTime lastSyncedAt;

    @Column(name = "app_version", length = 40)
    private String appVersion;
}
