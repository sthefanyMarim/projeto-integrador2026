package com.ufsm.projeto_integrador.controller;

import com.ufsm.projeto_integrador.security.SecurityUtils;
import com.ufsm.projeto_integrador.service.S3Service;
import com.ufsm.projeto_integrador.service.UsuarioService;
import com.ufsm.projeto_integrador.service.VisitaTecnicaService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.Map;

@RestController
@RequestMapping("/api/imagens")
@RequiredArgsConstructor
@Tag(name = "Imagens", description = "Upload de imagens para S3 / MinIO")
public class ImagemController {

    private final S3Service s3Service;
    private final UsuarioService usuarioService;
    private final VisitaTecnicaService visitaTecnicaService;

    @PostMapping("/perfil")
    @Operation(summary = "Upload da foto de perfil do usuário logado")
    public ResponseEntity<Map<String, String>> uploadPerfil(
            @RequestParam("arquivo") MultipartFile arquivo) {
        String url = s3Service.upload(arquivo, "perfil");
        usuarioService.atualizarFoto(SecurityUtils.getCurrentUserId(), url);
        return ResponseEntity.ok(Map.of("url", url));
    }

    @PostMapping("/visita/{visitaId}")
    @Operation(summary = "Upload de imagem vinculada a uma visita")
    public ResponseEntity<Map<String, String>> uploadVisita(
            @PathVariable Long visitaId,
            @RequestParam("arquivo") MultipartFile arquivo) {
        visitaTecnicaService.buscarAutorizada(visitaId);
        String url = s3Service.upload(arquivo, "visitas/" + visitaId);
        return ResponseEntity.ok(Map.of("url", url));
    }
}
