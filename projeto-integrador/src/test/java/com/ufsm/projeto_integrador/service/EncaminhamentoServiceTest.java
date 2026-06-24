package com.ufsm.projeto_integrador.service;

import com.ufsm.projeto_integrador.domain.dto.encaminhamento.EncaminhamentoResponse;
import com.ufsm.projeto_integrador.domain.entity.Encaminhamento;
import com.ufsm.projeto_integrador.domain.entity.Propriedade;
import com.ufsm.projeto_integrador.domain.entity.Usuario;
import com.ufsm.projeto_integrador.domain.entity.VisitaTecnica;
import com.ufsm.projeto_integrador.domain.enums.StatusEncaminhamento;
import com.ufsm.projeto_integrador.exception.BusinessException;
import com.ufsm.projeto_integrador.exception.ResourceNotFoundException;
import com.ufsm.projeto_integrador.repository.EncaminhamentoRepository;
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
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class EncaminhamentoServiceTest {

    @Mock
    private EncaminhamentoRepository repository;

    @Mock
    private SyncChangeService syncChangeService;

    @InjectMocks
    private EncaminhamentoService service;

    private Encaminhamento encaminhamentoDoTecnico(Long id, Long tecnicoId, StatusEncaminhamento status) {
        Usuario tecnico = new Usuario();
        tecnico.setId(tecnicoId);

        Propriedade propriedade = new Propriedade();
        propriedade.setId(1L);
        propriedade.setNome("Sitio Boa Vista");

        VisitaTecnica visita = new VisitaTecnica();
        visita.setId(50L);
        visita.setUsuario(tecnico);
        visita.setPropriedade(propriedade);

        Encaminhamento enc = new Encaminhamento();
        enc.setId(id);
        enc.setVisita(visita);
        enc.setAcaoRealizada("Refazer analise de solo");
        enc.setStatus(status);
        return enc;
    }

    @Test
    void concluirDeveLancarBusinessExceptionQuandoJaConcluido() {
        Encaminhamento enc = encaminhamentoDoTecnico(1L, 42L, StatusEncaminhamento.CONCLUIDO);
        when(repository.findById(1L)).thenReturn(Optional.of(enc));

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::isAdmin).thenReturn(false);
            security.when(SecurityUtils::getCurrentUserId).thenReturn(42L);

            BusinessException ex = assertThrows(BusinessException.class, () -> service.concluir(1L));
            assertEquals("Encaminhamento já concluído", ex.getMessage());
        }
    }

    @Test
    void concluirDeveLancarBusinessExceptionQuandoCancelado() {
        Encaminhamento enc = encaminhamentoDoTecnico(1L, 42L, StatusEncaminhamento.CANCELADO);
        when(repository.findById(1L)).thenReturn(Optional.of(enc));

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::isAdmin).thenReturn(false);
            security.when(SecurityUtils::getCurrentUserId).thenReturn(42L);

            BusinessException ex = assertThrows(BusinessException.class, () -> service.concluir(1L));
            assertEquals("Encaminhamento cancelado", ex.getMessage());
        }
    }

    @Test
    void concluirDeveLancarBusinessExceptionQuandoAcessoNegado() {
        Encaminhamento enc = encaminhamentoDoTecnico(1L, 42L, StatusEncaminhamento.PENDENTE);
        when(repository.findById(1L)).thenReturn(Optional.of(enc));

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::isAdmin).thenReturn(false);
            security.when(SecurityUtils::getCurrentUserId).thenReturn(99L);

            BusinessException ex = assertThrows(BusinessException.class, () -> service.concluir(1L));
            assertEquals("Acesso negado a este encaminhamento", ex.getMessage());
        }
        verify(repository, never()).save(any());
    }

    @Test
    void concluirDeveConcluirComSucessoQuandoPendente() {
        Encaminhamento enc = encaminhamentoDoTecnico(1L, 42L, StatusEncaminhamento.PENDENTE);
        when(repository.findById(1L)).thenReturn(Optional.of(enc));
        when(repository.save(any(Encaminhamento.class))).thenAnswer(invocation -> invocation.getArgument(0));

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::isAdmin).thenReturn(false);
            security.when(SecurityUtils::getCurrentUserId).thenReturn(42L);
            security.when(SecurityUtils::getCurrentUserIdOrNull).thenReturn(42L);

            EncaminhamentoResponse response = service.concluir(1L);

            assertEquals(StatusEncaminhamento.CONCLUIDO, response.status());
        }
    }

    @Test
    void concluirDeveLancarResourceNotFoundQuandoNaoExiste() {
        when(repository.findById(404L)).thenReturn(Optional.empty());

        assertThrows(ResourceNotFoundException.class, () -> service.concluir(404L));
    }

    @Test
    void cancelarDeveLancarBusinessExceptionQuandoJaConcluido() {
        Encaminhamento enc = encaminhamentoDoTecnico(1L, 42L, StatusEncaminhamento.CONCLUIDO);
        when(repository.findById(1L)).thenReturn(Optional.of(enc));

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::isAdmin).thenReturn(false);
            security.when(SecurityUtils::getCurrentUserId).thenReturn(42L);

            BusinessException ex = assertThrows(BusinessException.class, () -> service.cancelar(1L));
            assertEquals("Encaminhamento já concluído não pode ser cancelado", ex.getMessage());
        }
        verify(repository, never()).save(any());
    }

    @Test
    void cancelarDeveLancarBusinessExceptionQuandoJaCancelado() {
        Encaminhamento enc = encaminhamentoDoTecnico(1L, 42L, StatusEncaminhamento.CANCELADO);
        when(repository.findById(1L)).thenReturn(Optional.of(enc));

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::isAdmin).thenReturn(false);
            security.when(SecurityUtils::getCurrentUserId).thenReturn(42L);

            BusinessException ex = assertThrows(BusinessException.class, () -> service.cancelar(1L));
            assertEquals("Encaminhamento já cancelado", ex.getMessage());
        }
        verify(repository, never()).save(any());
    }

    @Test
    void cancelarDeveCancelarComSucessoQuandoPendente() {
        Encaminhamento enc = encaminhamentoDoTecnico(1L, 42L, StatusEncaminhamento.PENDENTE);
        when(repository.findById(1L)).thenReturn(Optional.of(enc));
        when(repository.save(any(Encaminhamento.class))).thenAnswer(invocation -> invocation.getArgument(0));

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::isAdmin).thenReturn(false);
            security.when(SecurityUtils::getCurrentUserId).thenReturn(42L);
            security.when(SecurityUtils::getCurrentUserIdOrNull).thenReturn(42L);

            service.cancelar(1L);

            assertEquals(StatusEncaminhamento.CANCELADO, enc.getStatus());
        }
    }
}
