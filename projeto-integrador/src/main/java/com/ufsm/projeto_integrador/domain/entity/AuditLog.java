package com.ufsm.projeto_integrador.domain.entity;

import com.ufsm.projeto_integrador.domain.enums.AuditAction;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

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

    @Column(name = "dados_antigos", columnDefinition = "jsonb")
    private String dadosAntigos;

    @Column(name = "dados_novos", columnDefinition = "jsonb")
    private String dadosNovos;

    @Column(name = "alterado_por")
    private Long alteradoPor;

    @Column(name = "alterado_em")
    @Builder.Default
    private LocalDateTime alteradoEm = LocalDateTime.now();

    @Column(name = "ip_origem", length = 45)
    private String ipOrigem;
}
