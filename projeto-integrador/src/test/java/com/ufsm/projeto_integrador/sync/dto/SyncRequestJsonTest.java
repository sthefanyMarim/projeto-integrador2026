package com.ufsm.projeto_integrador.sync.dto;

import org.junit.jupiter.api.Test;
import tools.jackson.databind.ObjectMapper;
import tools.jackson.databind.json.JsonMapper;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

class SyncRequestJsonTest {

    private final ObjectMapper objectMapper = JsonMapper.builder()
            .findAndAddModules()
            .build();

    @Test
    void shouldDeserializeOperationsPayloadAsJsonNode() throws Exception {
        String json = """
                {
                  "deviceId": "android-dev-01",
                  "lastSyncToken": 12,
                  "appVersion": "1.0.0",
                  "operations": [
                    {
                      "operationId": "op-1",
                      "entityType": "VISITA",
                      "action": "FINALIZE_VISITA",
                      "localId": "local-visita-1",
                      "serverId": 99,
                      "baseVersion": 4,
                      "dependsOn": [],
                      "payload": {
                        "observacoes": "Visita finalizada offline",
                        "diagnosticos": [
                          {
                            "categoria": "SOLO",
                            "criticidade": "ALTA",
                            "observacoes": "Necessita correcao"
                          }
                        ],
                        "encaminhamentos": [
                          {
                            "acaoRealizada": "Aplicar calcario",
                            "responsavel": "Produtor",
                            "prazo": "2026-06-10",
                            "verificacao": "Nova vistoria",
                            "prioridade": "ALTA"
                          }
                        ],
                        "attachmentIds": [
                          "att-1"
                        ]
                      }
                    }
                  ]
                }
                """;

        SyncRequest request = objectMapper.readValue(json, SyncRequest.class);

        assertEquals("android-dev-01", request.deviceId());
        assertNotNull(request.operations());
        assertEquals(1, request.operations().size());
        assertNotNull(request.operations().getFirst().payload());
        assertTrue(request.operations().getFirst().payload().isObject());
        assertEquals(
                "Visita finalizada offline",
                request.operations().getFirst().payload().get("observacoes").asText()
        );
    }
}
