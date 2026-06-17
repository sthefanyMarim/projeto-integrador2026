package com.ufsm.projeto_integrador.service;

import com.ufsm.projeto_integrador.domain.entity.Propriedade;
import com.ufsm.projeto_integrador.domain.entity.Usuario;
import com.ufsm.projeto_integrador.domain.entity.VisitaTecnica;
import com.ufsm.projeto_integrador.exception.BusinessException;
import com.ufsm.projeto_integrador.repository.PropriedadeRepository;
import com.ufsm.projeto_integrador.repository.VisitaTecnicaRepository;
import com.ufsm.projeto_integrador.security.SecurityUtils;
import com.ufsm.projeto_integrador.sync.service.SyncChangeService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class VisitaTecnicaServiceTest {

    @Mock
    private VisitaTecnicaRepository repository;

    @Mock
    private PropriedadeRepository propriedadeRepository;

    @Mock
    private SyncChangeService syncChangeService;

    @InjectMocks
    private VisitaTecnicaService service;

    @Test
    void buscarPorIdDeveNegarAcessoQuandoVisitaForDeOutroTecnico() {
        VisitaTecnica visita = visitaComUsuario(7L, 10L);
        when(repository.findById(7L)).thenReturn(Optional.of(visita));

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::isAdmin).thenReturn(false);
            security.when(SecurityUtils::getCurrentUserId).thenReturn(99L);

            BusinessException ex = assertThrows(BusinessException.class, () -> service.buscarPorId(7L));
            assertEquals("Acesso negado a esta visita", ex.getMessage());
        }
    }

    @Test
    void buscarPorIdDevePermitirAcessoQuandoVisitaForDoUsuarioLogado() {
        VisitaTecnica visita = visitaComUsuario(8L, 42L);
        when(repository.findById(8L)).thenReturn(Optional.of(visita));

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::isAdmin).thenReturn(false);
            security.when(SecurityUtils::getCurrentUserId).thenReturn(42L);

            assertEquals(8L, service.buscarPorId(8L).id());
            assertEquals(42L, service.buscarPorId(8L).usuarioId());
        }
    }

    private VisitaTecnica visitaComUsuario(Long visitaId, Long usuarioId) {
        Usuario usuario = new Usuario();
        usuario.setId(usuarioId);
        usuario.setNome("Tecnico Teste");

        Propriedade propriedade = new Propriedade();
        propriedade.setId(3L);
        propriedade.setNome("Propriedade Teste");

        VisitaTecnica visita = new VisitaTecnica();
        visita.setId(visitaId);
        visita.setUsuario(usuario);
        visita.setPropriedade(propriedade);
        return visita;
    }
}
