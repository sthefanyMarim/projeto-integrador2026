package com.ufsm.projeto_integrador.exception;

import jakarta.servlet.http.HttpServletRequest;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.DisabledException;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<ErrorResponse> handleNotFound(ResourceNotFoundException ex, HttpServletRequest request) {
        log.warn("Recurso não encontrado em {}: {}", requestContext(request), ex.getMessage());
        return build(HttpStatus.NOT_FOUND, ex.getMessage());
    }

    @ExceptionHandler(BusinessException.class)
    public ResponseEntity<ErrorResponse> handleBusiness(BusinessException ex, HttpServletRequest request) {
        log.warn("Regra de negócio bloqueou {}: {}", requestContext(request), ex.getMessage());
        return build(HttpStatus.BAD_REQUEST, ex.getMessage());
    }

    @ExceptionHandler(BadCredentialsException.class)
    public ResponseEntity<ErrorResponse> handleBadCredentials(BadCredentialsException ex, HttpServletRequest request) {
        log.warn("Falha de autenticação em {}: {}", requestContext(request), ex.getMessage());
        return build(HttpStatus.UNAUTHORIZED, "Matrícula ou senha inválidos");
    }

    @ExceptionHandler(DisabledException.class)
    public ResponseEntity<ErrorResponse> handleDisabled(DisabledException ex, HttpServletRequest request) {
        log.warn("Conta inativa em {}: {}", requestContext(request), ex.getMessage());
        return build(HttpStatus.UNAUTHORIZED, "Conta inativa");
    }

    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<ErrorResponse> handleForbidden(AccessDeniedException ex, HttpServletRequest request) {
        log.warn("Acesso negado em {}: {}", requestContext(request), ex.getMessage());
        return build(HttpStatus.FORBIDDEN, "Acesso negado");
    }

    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<ErrorResponse> handleMalformedJson(HttpMessageNotReadableException ex, HttpServletRequest request) {
        log.warn("Corpo da requisição inválido em {}: {}", requestContext(request), ex.getMessage());
        return ResponseEntity.status(422)
                .body(new ErrorResponse(422,
                        "Dados inválidos: verifique se os campos enviados (ex: tipos e status) têm valores aceitos.",
                        null));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorResponse> handleValidation(MethodArgumentNotValidException ex, HttpServletRequest request) {
        Map<String, String> erros = new HashMap<>();
        for (FieldError field : ex.getBindingResult().getFieldErrors()) {
            erros.put(field.getField(), field.getDefaultMessage());
        }
        log.warn("Erro de validação em {}: {}", requestContext(request), erros);
        return ResponseEntity.status(422)
                .body(new ErrorResponse(422, "Erro de validação", erros));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorResponse> handleGeneric(Exception ex, HttpServletRequest request) {
        log.error("Erro interno não tratado em {}", requestContext(request), ex);
        return build(HttpStatus.INTERNAL_SERVER_ERROR, "Erro interno do servidor");
    }

    private ResponseEntity<ErrorResponse> build(HttpStatus status, String message) {
        return ResponseEntity.status(status)
                .body(new ErrorResponse(status.value(), message, null));
    }

    private String requestContext(HttpServletRequest request) {
        return request.getMethod() + " " + request.getRequestURI();
    }

    public record ErrorResponse(
            int status,
            String message,
            Map<String, String> erros
    ) {
        public ErrorResponse(int status, String message) {
            this(status, message, null);
        }

        public LocalDateTime timestamp() {
            return LocalDateTime.now();
        }
    }
}
