package com.ufsm.projeto_integrador.domain.entity;

import com.ufsm.projeto_integrador.audit.AuditListener;
import com.ufsm.projeto_integrador.domain.enums.TipoProducao;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.JdbcType;
import org.hibernate.annotations.UpdateTimestamp;
import org.hibernate.dialect.type.PostgreSQLEnumJdbcType;

import java.io.Serializable;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "propriedades")
@EntityListeners(AuditListener.class)
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor
@Builder
public class Propriedade implements Serializable {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "prop_id")
    private Long id;

    @Column(nullable = false, length = 150)
    private String nome;

    @Column(name = "nome_proprietario", nullable = false, length = 150)
    private String nomeProprietario;

    @Column(length = 20)
    private String telefone;

    @Column(length = 255)
    private String endereco;

    @Column(length = 100)
    private String municipio;

    @Column(length = 2)
    @Builder.Default
    private String estado = "RS";

    @Column(precision = 10, scale = 7)
    private BigDecimal latitude;

    @Column(precision = 10, scale = 7)
    private BigDecimal longitude;

    @Enumerated(EnumType.STRING)
    @JdbcType(PostgreSQLEnumJdbcType.class)
    @Column(name = "tipo_producao", columnDefinition = "tipo_producao")
    private TipoProducao tipoProducao;

    @Column(nullable = false)
    @Builder.Default
    private Boolean ativa = true;

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
