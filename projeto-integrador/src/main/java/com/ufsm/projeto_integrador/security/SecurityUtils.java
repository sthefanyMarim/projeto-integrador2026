package com.ufsm.projeto_integrador.security;

import com.ufsm.projeto_integrador.domain.enums.TipoUsuario;
import com.ufsm.projeto_integrador.exception.BusinessException;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

public final class SecurityUtils {

    private SecurityUtils() {}

    public static UserDetailsImpl getCurrentUser() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !auth.isAuthenticated() || !(auth.getPrincipal() instanceof UserDetailsImpl)) {
            throw new BusinessException("Nenhum usuário autenticado");
        }
        return (UserDetailsImpl) auth.getPrincipal();
    }

    public static Long getCurrentUserId() {
        return getCurrentUser().getId();
    }

    public static TipoUsuario getCurrentUserTipo() {
        return getCurrentUser().getTipo();
    }

    public static boolean isAdmin() {
        try {
            return getCurrentUserTipo() == TipoUsuario.ADMIN;
        } catch (Exception e) {
            return false;
        }
    }

    public static String getCurrentIp() {
        try {
            ServletRequestAttributes attrs =
                    (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();
            if (attrs == null) return null;
            HttpServletRequest req = attrs.getRequest();
            String forwarded = req.getHeader("X-Forwarded-For");
            return (forwarded != null) ? forwarded.split(",")[0].trim() : req.getRemoteAddr();
        } catch (Exception e) {
            return null;
        }
    }
}
