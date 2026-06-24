package com.ufsm.projeto_integrador.service;

import com.ufsm.projeto_integrador.domain.dto.common.DashboardResponse;
import com.ufsm.projeto_integrador.domain.entity.Usuario;
import com.ufsm.projeto_integrador.domain.enums.StatusEncaminhamento;
import com.ufsm.projeto_integrador.exception.ResourceNotFoundException;
import com.ufsm.projeto_integrador.repository.EncaminhamentoRepository;
import com.ufsm.projeto_integrador.repository.PropriedadeRepository;
import com.ufsm.projeto_integrador.repository.UsuarioRepository;
import com.ufsm.projeto_integrador.repository.VisitaTecnicaRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class DashboardServiceTest {

    @Mock private UsuarioRepository usuarioRepository;
    @Mock private VisitaTecnicaRepository visitaRepository;
    @Mock private EncaminhamentoRepository encaminhamentoRepository;
    @Mock private PropriedadeRepository propriedadeRepository;

    @InjectMocks private DashboardService dashboardService;

    @Test
    void getDashboardDeveLancarResourceNotFoundQuandoUsuarioNaoExiste() {
        when(usuarioRepository.findById(404L)).thenReturn(Optional.empty());

        assertThrows(ResourceNotFoundException.class, () -> dashboardService.getDashboard(404L));
    }

    @Test
    void getDashboardDeveMontarResponseComDadosAgregados() {
        Usuario usuario = Usuario.builder().id(1L).nome("Joao Tecnico").build();
        when(usuarioRepository.findById(1L)).thenReturn(Optional.of(usuario));
        when(visitaRepository.findByUsuarioIdAndDataVisitaOrderByHoraVisitaAsc(eq(1L), any(LocalDate.class)))
                .thenReturn(List.of());
        when(visitaRepository.countAtrasadasPorUsuario(eq(1L), any(LocalDate.class), any(LocalTime.class)))
                .thenReturn(2L);
        when(encaminhamentoRepository.countByVisitaUsuarioIdAndStatus(1L, StatusEncaminhamento.PENDENTE))
                .thenReturn(3L);
        when(encaminhamentoRepository.countByVisitaUsuarioIdAndStatus(1L, StatusEncaminhamento.ATRASADO))
                .thenReturn(1L);
        when(propriedadeRepository.countByAtivaTrue()).thenReturn(15L);
        Page<com.ufsm.projeto_integrador.domain.entity.Encaminhamento> paginaVazia = new PageImpl<>(List.of());
        when(encaminhamentoRepository.findAll(any(org.springframework.data.jpa.domain.Specification.class), any(org.springframework.data.domain.Pageable.class)))
                .thenReturn(paginaVazia);

        DashboardResponse response = dashboardService.getDashboard(1L);

        assertEquals("Joao Tecnico", response.nomeUsuario());
        assertEquals(15L, response.totalPropriedades());
        assertEquals(2L, response.visitasAtrasadas());
        assertEquals(4L, response.pendenciasUrgentes());
    }
}
