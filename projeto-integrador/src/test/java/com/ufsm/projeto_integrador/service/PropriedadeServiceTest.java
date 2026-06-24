package com.ufsm.projeto_integrador.service;

import com.ufsm.projeto_integrador.domain.dto.propriedade.PropriedadeRequest;
import com.ufsm.projeto_integrador.domain.dto.propriedade.PropriedadeResponse;
import com.ufsm.projeto_integrador.domain.entity.Propriedade;
import com.ufsm.projeto_integrador.domain.enums.TipoProducao;
import com.ufsm.projeto_integrador.exception.BusinessException;
import com.ufsm.projeto_integrador.exception.ResourceNotFoundException;
import com.ufsm.projeto_integrador.repository.PropriedadeRepository;
import com.ufsm.projeto_integrador.repository.VisitaTecnicaRepository;
import com.ufsm.projeto_integrador.sync.service.SyncChangeService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class PropriedadeServiceTest {

    @Mock
    private PropriedadeRepository repository;

    @Mock
    private VisitaTecnicaRepository visitaTecnicaRepository;

    @Mock
    private SyncChangeService syncChangeService;

    @InjectMocks
    private PropriedadeService service;

    private PropriedadeRequest requestValido(String estado, Boolean ativa) {
        return new PropriedadeRequest("Sitio Boa Vista", "Zé", "(55) 99999-9999", "Linha 5", "Santa Maria",
                estado, new BigDecimal("-29.6868"), new BigDecimal("-53.8149"), TipoProducao.PECUARIA, ativa);
    }

    @Test
    void criarDeveUsarEstadoPadraoRSQuandoEstadoNaoInformado() {
        when(repository.save(any(Propriedade.class))).thenAnswer(invocation -> invocation.getArgument(0));

        PropriedadeResponse response = service.criar(requestValido(null, null));

        assertEquals("RS", response.estado());
        assertTrue(response.ativa());
    }

    @Test
    void criarDeveManterEstadoInformadoQuandoNaoNulo() {
        when(repository.save(any(Propriedade.class))).thenAnswer(invocation -> invocation.getArgument(0));

        PropriedadeResponse response = service.criar(requestValido("SC", false));

        assertEquals("SC", response.estado());
        assertFalse(response.ativa());
    }

    @Test
    void criarDeveNormalizarCoordenadasParaEscalaSete() {
        when(repository.save(any(Propriedade.class))).thenAnswer(invocation -> invocation.getArgument(0));
        PropriedadeRequest req = new PropriedadeRequest("Sitio", "Zé", null, null, null, null,
                new BigDecimal("-29.123456789"), new BigDecimal("-53.987654321"), null, null);

        PropriedadeResponse response = service.criar(req);

        assertEquals(7, response.latitude().scale());
        assertEquals(new BigDecimal("-29.1234568"), response.latitude());
    }

    @Test
    void buscarPorIdDeveLancarResourceNotFoundQuandoNaoExiste() {
        when(repository.findById(99L)).thenReturn(Optional.empty());

        assertThrows(ResourceNotFoundException.class, () -> service.buscarPorId(99L));
    }

    @Test
    void atualizarDeveManterAtivaAtualQuandoAtivaNulaNoRequest() {
        Propriedade existente = Propriedade.builder().id(1L).nome("Antigo").nomeProprietario("Zé")
                .estado("RS").ativa(false).build();
        when(repository.findById(1L)).thenReturn(Optional.of(existente));
        when(repository.save(any(Propriedade.class))).thenAnswer(invocation -> invocation.getArgument(0));

        service.atualizar(1L, requestValido(null, null));

        assertFalse(existente.getAtiva());
    }

    @Test
    void atualizarDeveAtualizarAtivaQuandoInformadaNoRequest() {
        Propriedade existente = Propriedade.builder().id(1L).nome("Antigo").nomeProprietario("Zé")
                .estado("RS").ativa(false).build();
        when(repository.findById(1L)).thenReturn(Optional.of(existente));
        when(repository.save(any(Propriedade.class))).thenAnswer(invocation -> invocation.getArgument(0));

        service.atualizar(1L, requestValido("RS", true));

        assertTrue(existente.getAtiva());
    }

    @Test
    void deletarDeveLancarBusinessExceptionQuandoPropriedadeTemVisitasRegistradas() {
        Propriedade propriedade = Propriedade.builder().id(1L).build();
        when(repository.findById(1L)).thenReturn(Optional.of(propriedade));
        when(visitaTecnicaRepository.countByPropriedadeId(1L)).thenReturn(5L);

        BusinessException ex = assertThrows(BusinessException.class, () -> service.deletar(1L));
        assertTrue(ex.getMessage().contains("5 visita(s) registrada(s)"));
        verify(repository, never()).deleteById(any());
    }

    @Test
    void deletarDeveExcluirQuandoSemVisitasRegistradas() {
        Propriedade propriedade = Propriedade.builder().id(1L).version(2L).build();
        when(repository.findById(1L)).thenReturn(Optional.of(propriedade));
        when(visitaTecnicaRepository.countByPropriedadeId(1L)).thenReturn(0L);

        service.deletar(1L);

        verify(repository).deleteById(1L);
        verify(syncChangeService).recordPropriedadeDelete(1L, 2L, null);
    }
}
