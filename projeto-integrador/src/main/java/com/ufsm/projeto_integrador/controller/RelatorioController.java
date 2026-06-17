package com.ufsm.projeto_integrador.controller;

import com.ufsm.projeto_integrador.domain.dto.relatorio.RelatorioGeralResponse;
import com.ufsm.projeto_integrador.domain.dto.relatorio.RelatorioPropriedadeResponse;
import com.ufsm.projeto_integrador.service.RelatorioPdfService;
import com.ufsm.projeto_integrador.service.RelatorioService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;

@RestController
@RequestMapping("/api/relatorios")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
@Tag(name = "Relatorios", description = "Relatórios gerenciais — acesso restrito a administradores")
public class RelatorioController {

    private static final DateTimeFormatter FILE_FMT = DateTimeFormatter.ofPattern("yyyy-MM-dd");

    private final RelatorioService service;
    private final RelatorioPdfService pdfService;

    @GetMapping("/geral")
    @Operation(summary = "Dados do relatório geral em JSON")
    public ResponseEntity<RelatorioGeralResponse> geral(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate inicio,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate fim) {
        return ResponseEntity.ok(service.gerarGeral(inicio, fim));
    }

    @GetMapping("/geral/pdf")
    @Operation(summary = "Relatório geral em PDF")
    public ResponseEntity<byte[]> geralPdf(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate inicio,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate fim) {
        var data = service.gerarGeral(inicio, fim);
        byte[] pdf = pdfService.gerarRelatorioGeral(data);
        String filename = "relatorio-geral-" + inicio.format(FILE_FMT) + "-" + fim.format(FILE_FMT) + ".pdf";
        return ResponseEntity.ok()
                .contentType(MediaType.APPLICATION_PDF)
                .header(HttpHeaders.CONTENT_DISPOSITION,
                        ContentDisposition.attachment().filename(filename).build().toString())
                .body(pdf);
    }

    @GetMapping("/propriedade/{id}")
    @Operation(summary = "Dados do relatório de propriedade em JSON")
    public ResponseEntity<RelatorioPropriedadeResponse> propriedade(
            @PathVariable Long id,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate inicio,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate fim) {
        return ResponseEntity.ok(service.gerarPropriedade(id, inicio, fim));
    }

    @GetMapping("/propriedade/{id}/pdf")
    @Operation(summary = "Relatório de propriedade em PDF")
    public ResponseEntity<byte[]> propriedadePdf(
            @PathVariable Long id,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate inicio,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate fim) {
        var data = service.gerarPropriedade(id, inicio, fim);
        byte[] pdf = pdfService.gerarRelatorioPropriedade(data);
        String nome = data.propriedadeNome().toLowerCase().replace(' ', '-');
        String filename = "relatorio-" + nome + "-" + inicio.format(FILE_FMT) + ".pdf";
        return ResponseEntity.ok()
                .contentType(MediaType.APPLICATION_PDF)
                .header(HttpHeaders.CONTENT_DISPOSITION,
                        ContentDisposition.attachment().filename(filename).build().toString())
                .body(pdf);
    }
}
