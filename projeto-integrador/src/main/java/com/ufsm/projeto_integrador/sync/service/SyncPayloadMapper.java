package com.ufsm.projeto_integrador.sync.service;

import com.ufsm.projeto_integrador.exception.BusinessException;
import jakarta.validation.ConstraintViolation;
import jakarta.validation.Validator;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;

import java.util.Comparator;
import java.util.stream.Collectors;

@Component
@RequiredArgsConstructor
public class SyncPayloadMapper {

    private final ObjectMapper objectMapper;
    private final Validator validator;

    public <T> T read(JsonNode payload, Class<T> targetType) {
        if (payload == null || payload.isNull()) {
            throw new BusinessException("Payload de sync obrigatorio para " + targetType.getSimpleName());
        }

        try {
            T mapped = objectMapper.treeToValue(payload, targetType);
            if (mapped == null) {
                throw new BusinessException("Payload de sync obrigatorio para " + targetType.getSimpleName());
            }

            var violations = validator.validate(mapped);
            if (!violations.isEmpty()) {
                throw new BusinessException(buildValidationMessage(targetType, violations));
            }

            return mapped;
        } catch (Exception ex) {
            if (ex instanceof BusinessException businessException) {
                throw businessException;
            }
            throw new BusinessException("Payload de sync invalido para " + targetType.getSimpleName());
        }
    }

    public JsonNode toJsonNode(Object value) {
        return value == null ? null : objectMapper.valueToTree(value);
    }

    public String toJsonString(Object value) {
        try {
            return value == null ? null : objectMapper.writeValueAsString(value);
        } catch (Exception ex) {
            throw new BusinessException("Nao foi possivel serializar dados de sync");
        }
    }

    public JsonNode parse(String rawJson) {
        try {
            return rawJson == null || rawJson.isBlank() ? null : objectMapper.readTree(rawJson);
        } catch (Exception ex) {
            throw new BusinessException("Nao foi possivel ler snapshot de sync");
        }
    }

    private <T> String buildValidationMessage(
            Class<T> targetType,
            java.util.Set<ConstraintViolation<T>> violations
    ) {
        String detail = violations.stream()
                .sorted(Comparator.comparing(violation -> violation.getPropertyPath().toString()))
                .map(violation -> {
                    String path = violation.getPropertyPath().toString();
                    return (path == null || path.isBlank())
                            ? violation.getMessage()
                            : path + ": " + violation.getMessage();
                })
                .collect(Collectors.joining("; "));

        return "Payload de sync invalido para " + targetType.getSimpleName() + ": " + detail;
    }
}
