package com.ufsm.projeto_integrador.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

@Getter
@Setter
@Component
@ConfigurationProperties(prefix = "app.bootstrap.admin")
public class AdminBootstrapProperties {

    /**
     * Habilita a garantia automatica de uma conta ADMIN valida na subida.
     */
    private boolean enabled = true;

    /**
     * Nome padrao da conta administrativa.
     */
    private String nome = "Admin UFSM";

    /**
     * Matricula usada no login do desktop e Swagger.
     */
    private String matricula = "999999999";

    /**
     * Email padrao da conta administrativa.
     */
    private String email = "admin@polivisitas.ufsm.br";

    /**
     * Senha padrao em texto puro; sera sempre salva criptografada.
     */
    private String senha = "admin123";

}
