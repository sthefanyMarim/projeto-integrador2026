package com.ufsm.projeto_integrador.domain.entity;

import com.ufsm.projeto_integrador.domain.enums.AuditAction;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.LocalDateTime;
import java.util.Map;

@Entity
@Table(name = "audit_logs")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor
@Builder
public class AuditLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 100)
    private String tabela;

    @Column(name = "registro_id", nullable = false)
    private Long registroId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 10)
    private AuditAction acao;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "dados_antigos", columnDefinition = "jsonb")
    private Map<String, Object> dadosAntigos;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "dados_novos", columnDefinition = "jsonb")
    private Map<String, Object> dadosNovos;

    @Column(name = "alterado_por")
    private Long alteradoPor;

    @Column(name = "alterado_em")
    @Builder.Default
    private LocalDateTime alteradoEm = LocalDateTime.now();

    @Column(name = "ip_origem", length = 45)
    private String ipOrigem;
}
