package com.ufsm.projeto_integrador.domain.entity;

import com.ufsm.projeto_integrador.audit.AuditListener;
import com.ufsm.projeto_integrador.domain.enums.StatusVisita;
import com.ufsm.projeto_integrador.domain.enums.TipoVisita;
import com.ufsm.projeto_integrador.domain.enums.Urgencia;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.JdbcType;
import org.hibernate.annotations.UpdateTimestamp;
import org.hibernate.dialect.type.PostgreSQLEnumJdbcType;

import java.io.Serializable;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "visitas_tecnicas")
@EntityListeners(AuditListener.class)
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor
@Builder
public class VisitaTecnica implements Serializable {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "visita_id")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private Usuario usuario;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "prop_id", nullable = false)
    private Propriedade propriedade;

    @Column(name = "data_visita", nullable = false)
    private LocalDate dataVisita;

    @Column(name = "hora_visita", nullable = false)
    private LocalTime horaVisita;

    @Enumerated(EnumType.STRING)
    @JdbcType(PostgreSQLEnumJdbcType.class)
    @Column(name = "tipo_visita", nullable = false,
            columnDefinition = "tipo_visita")
    private TipoVisita tipoVisita;

    @Column(name = "tema_principal", length = 200)
    private String temaPrincipal;

    @Column(columnDefinition = "TEXT")
    private String observacoes;

    @Enumerated(EnumType.STRING)
    @JdbcType(PostgreSQLEnumJdbcType.class)
    @Column(name = "status_visita", nullable = false,
            columnDefinition = "status_visita")
    @Builder.Default
    private StatusVisita statusVisita = StatusVisita.AGENDADA;

    @Enumerated(EnumType.STRING)
    @JdbcType(PostgreSQLEnumJdbcType.class)
    @Column(nullable = false, columnDefinition = "urgencia_tipo")
    @Builder.Default
    private Urgencia urgencia = Urgencia.BAIXA;

    @OneToMany(mappedBy = "visita", cascade = CascadeType.ALL, orphanRemoval = true)
    @Builder.Default
    private List<Diagnostico> diagnosticos = new ArrayList<>();

    @OneToMany(mappedBy = "visita", cascade = CascadeType.ALL, orphanRemoval = true)
    @Builder.Default
    private List<Encaminhamento> encaminhamentos = new ArrayList<>();

    @Version
    @Column(nullable = false)
    @Builder.Default
    private Long version = 0L;

    @CreationTimestamp
    @Column(name = "criado_em", nullable = false, updatable = false)
    private LocalDateTime criadoEm;

    @UpdateTimestamp
    @Column(name = "atualizado_em")
    private LocalDateTime atualizadoEm;
}
