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

    private boolean enabled = true;

    private String nome = "Admin UFSM";

    private String matricula = "999999999";

    private String email = "admin@polivisitas.ufsm.br";

    private String senha = "admin123";

}
