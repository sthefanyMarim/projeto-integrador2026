package com.ufsm.projeto_integrador.config;

import com.ufsm.projeto_integrador.domain.entity.Usuario;
import com.ufsm.projeto_integrador.domain.enums.TipoUsuario;
import com.ufsm.projeto_integrador.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

@Slf4j
@Component
@RequiredArgsConstructor
public class AdminBootstrapRunner implements ApplicationRunner {

    private final UsuarioRepository usuarioRepository;
    private final PasswordEncoder passwordEncoder;
    private final AdminBootstrapProperties properties;

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        if (!properties.isEnabled()) {
            log.info("Bootstrap de admin desabilitado por configuracao.");
            return;
        }

        boolean jaExiste = usuarioRepository.findByMatricula(properties.getMatricula()).isPresent()
                || usuarioRepository.findByEmail(properties.getEmail()).isPresent();

        if (jaExiste) {
            log.info("Conta administrativa bootstrap ja existe; nenhum dado foi sobrescrito.");
            return;
        }

        usuarioRepository.save(novoAdmin());
        log.info("Conta administrativa bootstrap criada para matricula {}", properties.getMatricula());
    }

    private Usuario novoAdmin() {
        return Usuario.builder()
                .nome(properties.getNome())
                .matricula(properties.getMatricula())
                .email(properties.getEmail())
                .senha(passwordEncoder.encode(properties.getSenha()))
                .tipo(TipoUsuario.ADMIN)
                .ativo(true)
                .build();
    }
}
