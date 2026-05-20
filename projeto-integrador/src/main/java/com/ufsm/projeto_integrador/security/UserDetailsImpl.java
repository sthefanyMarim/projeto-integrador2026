package com.ufsm.projeto_integrador.security;

import com.ufsm.projeto_integrador.domain.entity.Usuario;
import com.ufsm.projeto_integrador.domain.enums.TipoUsuario;
import lombok.Getter;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

import java.util.Collection;
import java.util.List;

@Getter
public class UserDetailsImpl implements UserDetails {

    private final Long id;
    private final String matricula;
    private final String senha;
    private final TipoUsuario tipo;
    private final String nome;
    private final Boolean ativo;
    private final Collection<? extends GrantedAuthority> authorities;

    public UserDetailsImpl(Usuario usuario) {
        this.id          = usuario.getId();
        this.matricula   = usuario.getMatricula();
        this.senha       = usuario.getSenha();
        this.tipo        = usuario.getTipo();
        this.nome        = usuario.getNome();
        this.ativo       = usuario.getAtivo();
        this.authorities = List.of(new SimpleGrantedAuthority("ROLE_" + usuario.getTipo().name()));
    }

    @Override public String getUsername()               { return matricula; }
    @Override public String getPassword()               { return senha; }
    @Override public boolean isEnabled()                { return ativo; }
    @Override public boolean isAccountNonExpired()      { return true; }
    @Override public boolean isAccountNonLocked()       { return true; }
    @Override public boolean isCredentialsNonExpired()  { return true; }
}
