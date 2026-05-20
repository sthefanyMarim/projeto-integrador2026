package com.ufsm.projeto_integrador.domain.entity;

import com.ufsm.projeto_integrador.audit.AuditListener;
import com.ufsm.projeto_integrador.domain.enums.Criticidade;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.JdbcType;
import org.hibernate.dialect.type.PostgreSQLEnumJdbcType;

import java.io.Serializable;
import java.time.LocalDateTime;

@Entity
@Table(name = "diagnosticos")
@EntityListeners(AuditListener.class)
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor
@Builder
public class Diagnostico implements Serializable {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "diagnostico_id")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "visita_id", nullable = false)
    private VisitaTecnica visita;

    @Column(nullable = false, length = 100)
    private String categoria;

    @Enumerated(EnumType.STRING)
    @JdbcType(PostgreSQLEnumJdbcType.class)
    @Column(nullable = false, columnDefinition = "criticidade_tipo")
    @Builder.Default
    private Criticidade criticidade = Criticidade.BAIXA;

    @Column(columnDefinition = "TEXT")
    private String observacoes;

    @CreationTimestamp
    @Column(name = "criado_em", nullable = false, updatable = false)
    private LocalDateTime criadoEm;
}
