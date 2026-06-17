package com.ufsm.projeto_integrador.sync.service;

import com.ufsm.projeto_integrador.domain.entity.Usuario;
import com.ufsm.projeto_integrador.exception.BusinessException;
import com.ufsm.projeto_integrador.service.S3Service;
import com.ufsm.projeto_integrador.sync.domain.entity.SyncAttachment;
import com.ufsm.projeto_integrador.sync.enums.SyncAttachmentPurpose;
import com.ufsm.projeto_integrador.sync.enums.SyncAttachmentStatus;
import com.ufsm.projeto_integrador.sync.enums.SyncEntityType;
import com.ufsm.projeto_integrador.sync.enums.SyncErrorCode;
import com.ufsm.projeto_integrador.sync.repository.SyncAttachmentRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.mock.web.MockMultipartFile;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.HexFormat;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class SyncAttachmentServiceTest {

    @Mock
    private SyncAttachmentRepository attachmentRepository;

    @Mock
    private S3Service s3Service;

    @InjectMocks
    private SyncAttachmentService service;

    @Test
    void uploadDeveRejeitarReusoDeClientAttachmentIdComOutroArquivo() {
        MockMultipartFile arquivo = new MockMultipartFile(
                "arquivo",
                "foto.png",
                "image/png",
                "arquivo-novo".getBytes(StandardCharsets.UTF_8)
        );
        SyncAttachment existente = SyncAttachment.builder()
                .id(UUID.randomUUID())
                .usuario(usuario(1L))
                .deviceId("device-1")
                .clientAttachmentId("client-1")
                .purpose(SyncAttachmentPurpose.VISITA_DIAGNOSTICO)
                .status(SyncAttachmentStatus.UPLOADED)
                .storageUrl("https://cdn.exemplo/arquivo-antigo.png")
                .contentType("image/png")
                .fileSize(arquivo.getSize())
                .contentHash(hash("arquivo-antigo"))
                .build();

        when(attachmentRepository.findByUsuarioIdAndDeviceIdAndClientAttachmentId(1L, "device-1", "client-1"))
                .thenReturn(Optional.of(existente));

        BusinessException ex = assertThrows(
                BusinessException.class,
                () -> service.upload(1L, "device-1", "client-1", SyncAttachmentPurpose.VISITA_DIAGNOSTICO, arquivo)
        );

        assertEquals(
                "clientAttachmentId ja foi utilizado com outro arquivo neste dispositivo",
                ex.getMessage()
        );
        verifyNoInteractions(s3Service);
    }

    @Test
    void resolveUploadedUrlDeveConsiderarMesmoDispositivoDoAnexo() {
        UUID attachmentId = UUID.randomUUID();
        SyncAttachment attachment = SyncAttachment.builder()
                .id(attachmentId)
                .usuario(usuario(3L))
                .deviceId("device-2")
                .status(SyncAttachmentStatus.UPLOADED)
                .storageUrl("https://cdn.exemplo/arquivo.png")
                .build();

        when(attachmentRepository.findByIdAndUsuarioIdAndDeviceId(attachmentId, 3L, "device-2"))
                .thenReturn(Optional.of(attachment));

        String url = service.resolveUploadedUrl(attachmentId, 3L, "device-2");

        assertEquals("https://cdn.exemplo/arquivo.png", url);
    }

    @Test
    void linkToVisitaDeveFalharQuandoAnexoNaoPertencerAoMesmoDispositivo() {
        UUID attachmentId = UUID.randomUUID();
        when(attachmentRepository.findByIdAndUsuarioIdAndDeviceId(attachmentId, 5L, "device-invalido"))
                .thenReturn(Optional.empty());

        SyncProcessException ex = assertThrows(
                SyncProcessException.class,
                () -> service.linkToVisita(attachmentId, 5L, "device-invalido", 44L)
        );

        assertEquals(SyncErrorCode.ATTACHMENT_NOT_READY, ex.getCode());
        verify(attachmentRepository, never()).save(org.mockito.ArgumentMatchers.any(SyncAttachment.class));
    }

    @Test
    void linkToVisitaDeveSerIdempotenteQuandoAnexoJaEstiverVinculadoNaMesmaVisita() {
        UUID attachmentId = UUID.randomUUID();
        SyncAttachment attachment = SyncAttachment.builder()
                .id(attachmentId)
                .usuario(usuario(8L))
                .deviceId("device-8")
                .status(SyncAttachmentStatus.LINKED)
                .linkedEntityType(SyncEntityType.VISITA)
                .linkedEntityId(77L)
                .build();

        when(attachmentRepository.findByIdAndUsuarioIdAndDeviceId(attachmentId, 8L, "device-8"))
                .thenReturn(Optional.of(attachment));

        service.linkToVisita(attachmentId, 8L, "device-8", 77L);

        verify(attachmentRepository, never()).save(org.mockito.ArgumentMatchers.any(SyncAttachment.class));
    }

    private Usuario usuario(Long id) {
        Usuario usuario = new Usuario();
        usuario.setId(id);
        return usuario;
    }

    private String hash(String value) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            return HexFormat.of().formatHex(digest.digest(value.getBytes(StandardCharsets.UTF_8)));
        } catch (Exception ex) {
            throw new IllegalStateException(ex);
        }
    }
}
