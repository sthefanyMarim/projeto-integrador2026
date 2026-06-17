package com.ufsm.projeto_integrador.sync.service;

import com.ufsm.projeto_integrador.domain.dto.encaminhamento.EncaminhamentoResponse;
import com.ufsm.projeto_integrador.domain.dto.propriedade.PropriedadeResponse;
import com.ufsm.projeto_integrador.domain.dto.usuario.UsuarioResponse;
import com.ufsm.projeto_integrador.domain.dto.visita.VisitaDetalheResponse;
import com.ufsm.projeto_integrador.domain.entity.Encaminhamento;
import com.ufsm.projeto_integrador.domain.entity.Propriedade;
import com.ufsm.projeto_integrador.domain.entity.Usuario;
import com.ufsm.projeto_integrador.domain.entity.VisitaTecnica;
import com.ufsm.projeto_integrador.repository.UsuarioRepository;
import com.ufsm.projeto_integrador.sync.domain.entity.SyncChangeLog;
import com.ufsm.projeto_integrador.sync.domain.entity.SyncDeviceState;
import com.ufsm.projeto_integrador.sync.dto.SyncServerChange;
import com.ufsm.projeto_integrador.sync.enums.SyncChangeType;
import com.ufsm.projeto_integrador.sync.enums.SyncEntityType;
import com.ufsm.projeto_integrador.sync.repository.SyncChangeLogRepository;
import com.ufsm.projeto_integrador.sync.repository.SyncDeviceStateRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class SyncChangeService {

    private final SyncChangeLogRepository changeLogRepository;
    private final SyncDeviceStateRepository deviceStateRepository;
    private final UsuarioRepository usuarioRepository;
    private final SyncPayloadMapper payloadMapper;

    @Transactional
    public void recordPropriedadeUpsert(Propriedade propriedade, Long changedByUserId) {
        recordUpsert(
                SyncEntityType.PROPRIEDADE,
                propriedade.getId(),
                null,
                changedByUserId,
                propriedade.getVersion(),
                PropriedadeResponse.from(propriedade)
        );
    }

    @Transactional
    public void recordPropriedadeDelete(Long propriedadeId, Long entityVersion, Long changedByUserId) {
        recordDelete(SyncEntityType.PROPRIEDADE, propriedadeId, null, changedByUserId, entityVersion);
    }

    @Transactional
    public void recordVisitaUpsert(VisitaTecnica visita, Long changedByUserId) {
        recordUpsert(
                SyncEntityType.VISITA,
                visita.getId(),
                visita.getUsuario().getId(),
                changedByUserId,
                visita.getVersion(),
                VisitaDetalheResponse.from(visita)
        );
    }

    @Transactional
    public void recordEncaminhamentoUpsert(Encaminhamento encaminhamento, Long changedByUserId) {
        recordUpsert(
                SyncEntityType.ENCAMINHAMENTO,
                encaminhamento.getId(),
                encaminhamento.getVisita().getUsuario().getId(),
                changedByUserId,
                encaminhamento.getVersion(),
                EncaminhamentoResponse.from(encaminhamento)
        );
    }

    @Transactional
    public void recordUsuarioUpsert(Usuario usuario, Long changedByUserId) {
        recordUpsert(
                SyncEntityType.USUARIO,
                usuario.getId(),
                usuario.getId(),
                changedByUserId,
                usuario.getVersion(),
                UsuarioResponse.from(usuario)
        );
    }

    @Transactional
    public void recordUsuarioDelete(Long usuarioId, Long entityVersion, Long changedByUserId) {
        recordDelete(SyncEntityType.USUARIO, usuarioId, usuarioId, changedByUserId, entityVersion);
    }

    @Transactional(readOnly = true)
    public List<SyncServerChange> fetchVisibleChangesAfter(Long lastSyncToken, Long userId) {
        long after = lastSyncToken == null ? 0L : lastSyncToken;
        return changeLogRepository.findVisibleChangesAfter(after, userId)
                .stream()
                .map(change -> new SyncServerChange(
                        change.getChangeId(),
                        change.getEntityType(),
                        change.getEntityId(),
                        change.getChangeType(),
                        change.getEntityVersion(),
                        change.getChangedAt(),
                        payloadMapper.parse(change.getSnapshot())
                ))
                .toList();
    }

    @Transactional
    public void updateDeviceState(
            Long userId,
            String deviceId,
            Long lastSyncToken,
            UUID sessionId,
            String appVersion
    ) {
        SyncDeviceState state = deviceStateRepository.findByUsuarioIdAndDeviceId(userId, deviceId)
                .orElseGet(() -> SyncDeviceState.builder()
                        .usuario(usuarioRepository.getReferenceById(userId))
                        .deviceId(deviceId)
                        .build());

        state.setLastSyncToken(lastSyncToken);
        state.setLastSessionId(sessionId);
        state.setLastSyncedAt(LocalDateTime.now());
        state.setAppVersion(appVersion);
        deviceStateRepository.save(state);
    }

    private void recordUpsert(
            SyncEntityType entityType,
            Long entityId,
            Long ownerUserId,
            Long changedByUserId,
            Long entityVersion,
            Object snapshot
    ) {
        changeLogRepository.save(
                SyncChangeLog.builder()
                        .entityType(entityType)
                        .entityId(entityId)
                        .ownerUserId(ownerUserId)
                        .changedByUserId(changedByUserId)
                        .changeType(SyncChangeType.UPSERT)
                        .entityVersion(entityVersion)
                        .snapshot(payloadMapper.toJsonString(snapshot))
                        .build()
        );
    }

    private void recordDelete(
            SyncEntityType entityType,
            Long entityId,
            Long ownerUserId,
            Long changedByUserId,
            Long entityVersion
    ) {
        changeLogRepository.save(
                SyncChangeLog.builder()
                        .entityType(entityType)
                        .entityId(entityId)
                        .ownerUserId(ownerUserId)
                        .changedByUserId(changedByUserId)
                        .changeType(SyncChangeType.DELETE)
                        .entityVersion(entityVersion)
                        .snapshot(null)
                        .build()
        );
    }
}
