package com.ufsm.projeto_integrador.service;

import com.ufsm.projeto_integrador.domain.dto.common.PageResponse;
import com.ufsm.projeto_integrador.domain.dto.usuario.UsuarioRequest;
import com.ufsm.projeto_integrador.domain.dto.usuario.UsuarioResponse;
import com.ufsm.projeto_integrador.domain.entity.Usuario;
import com.ufsm.projeto_integrador.domain.enums.TipoUsuario;
import com.ufsm.projeto_integrador.exception.BusinessException;
import com.ufsm.projeto_integrador.exception.ResourceNotFoundException;
import com.ufsm.projeto_integrador.repository.UsuarioRepository;
import com.ufsm.projeto_integrador.repository.spec.UsuarioSpecifications;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class UsuarioService {

    private final UsuarioRepository repository;
    private final PasswordEncoder passwordEncoder;

    public PageResponse<UsuarioResponse> listar(String busca, TipoUsuario tipo, Pageable pageable) {
        Specification<Usuario> specification = UsuarioSpecifications.comBusca(busca)
                .and(UsuarioSpecifications.comTipo(tipo));

        return PageResponse.from(repository.findAll(specification, pageable).map(UsuarioResponse::from));
    }

    public UsuarioResponse buscarPorId(Long id) {
        return UsuarioResponse.from(findOrThrow(id));
    }

    @Transactional
    public UsuarioResponse criar(UsuarioRequest req) {
        if (req.senha() == null || req.senha().isBlank()) {
            throw new BusinessException("Senha obrigatória");
        }
        if (repository.existsByMatricula(req.matricula())) {
            throw new BusinessException("Matricula ja cadastrada: " + req.matricula());
        }
        if (repository.existsByEmail(req.email())) {
            throw new BusinessException("Email ja cadastrado: " + req.email());
        }

        Usuario usuario = Usuario.builder()
                .nome(req.nome())
                .matricula(req.matricula())
                .email(req.email())
                .telefone(req.telefone())
                .senha(passwordEncoder.encode(req.senha()))
                .tipo(req.tipo())
                .ativo(true)
                .build();

        return UsuarioResponse.from(repository.save(usuario));
    }

    @Transactional
    public UsuarioResponse atualizar(Long id, UsuarioRequest req) {
        Usuario usuario = findOrThrow(id);

        if (!usuario.getMatricula().equals(req.matricula()) && repository.existsByMatricula(req.matricula())) {
            throw new BusinessException("Matricula ja em uso");
        }
        if (!usuario.getEmail().equals(req.email()) && repository.existsByEmail(req.email())) {
            throw new BusinessException("Email ja em uso");
        }

        usuario.setNome(req.nome());
        usuario.setMatricula(req.matricula());
        usuario.setEmail(req.email());
        usuario.setTelefone(req.telefone());
        usuario.setTipo(req.tipo());
        if (req.senha() != null && !req.senha().isBlank()) {
            usuario.setSenha(passwordEncoder.encode(req.senha()));
        }

        return UsuarioResponse.from(repository.save(usuario));
    }

    @Transactional
    public void alternarStatus(Long id) {
        Usuario usuario = findOrThrow(id);
        usuario.setAtivo(!usuario.getAtivo());
        repository.save(usuario);
    }

    @Transactional
    public void deletar(Long id) {
        findOrThrow(id);
        repository.deleteById(id);
    }

    @Transactional
    public void atualizarFoto(Long id, String fotoUrl) {
        Usuario usuario = findOrThrow(id);
        usuario.setFotoUrl(fotoUrl);
        repository.save(usuario);
    }

    private Usuario findOrThrow(Long id) {
        return repository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Usuario nao encontrado: " + id));
    }
}
