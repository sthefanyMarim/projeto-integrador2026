package com.ufsm.projeto_integrador.sync.service;

import com.ufsm.projeto_integrador.sync.enums.SyncEntityType;
import lombok.RequiredArgsConstructor;

import java.util.HashMap;
import java.util.Map;

@RequiredArgsConstructor
public class SyncRuntimeContext {

    private final Long userId;
    private final String deviceId;
    private final Map<String, Long> localToServerIds = new HashMap<>();

    public Long userId() {
        return userId;
    }

    public String deviceId() {
        return deviceId;
    }

    public void registerMapping(SyncEntityType entityType, String localId, Long serverId) {
        if (localId == null || localId.isBlank() || serverId == null) {
            return;
        }
        localToServerIds.put(key(entityType, localId), serverId);
    }

    public Long resolveServerId(SyncEntityType entityType, String localId) {
        if (localId == null || localId.isBlank()) {
            return null;
        }
        return localToServerIds.get(key(entityType, localId));
    }

    private String key(SyncEntityType entityType, String localId) {
        return entityType.name() + "::" + localId;
    }
}
