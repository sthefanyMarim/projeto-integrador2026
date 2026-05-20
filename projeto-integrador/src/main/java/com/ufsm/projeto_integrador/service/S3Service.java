package com.ufsm.projeto_integrador.service;

import com.ufsm.projeto_integrador.exception.BusinessException;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.DeleteObjectRequest;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class S3Service {

    private final S3Client s3Client;

    @Value("${aws.s3.bucket-name}") private String bucket;
    @Value("${aws.s3.region}")      private String region;
    @Value("${aws.s3.endpoint:}")   private String endpoint;

    private static final long MAX_SIZE = 5 * 1024 * 1024;
    private static final List<String> TIPOS = List.of("image/jpeg", "image/png", "image/webp");

    public String upload(MultipartFile file, String pasta) {
        validar(file);
        String chave = pasta + "/" + UUID.randomUUID() + "." + extensao(file);
        try {
            s3Client.putObject(
                    PutObjectRequest.builder()
                            .bucket(bucket).key(chave)
                            .contentType(file.getContentType())
                            .build(),
                    RequestBody.fromInputStream(file.getInputStream(), file.getSize()));
            return buildUrl(chave);
        } catch (Exception e) {
            throw new BusinessException("Erro ao fazer upload: " + e.getMessage());
        }
    }

    public void deletar(String url) {
        String chave = url.substring(url.indexOf(bucket + "/") + bucket.length() + 1);
        s3Client.deleteObject(DeleteObjectRequest.builder().bucket(bucket).key(chave).build());
    }

    private void validar(MultipartFile file) {
        if (file.isEmpty())               throw new BusinessException("Arquivo vazio");
        if (file.getSize() > MAX_SIZE)    throw new BusinessException("Arquivo maior que 5MB");
        if (!TIPOS.contains(file.getContentType()))
            throw new BusinessException("Use JPEG, PNG ou WebP");
    }

    private String buildUrl(String chave) {
        if (endpoint != null && !endpoint.isBlank())
            return endpoint + "/" + bucket + "/" + chave;
        return "https://" + bucket + ".s3." + region + ".amazonaws.com/" + chave;
    }

    private String extensao(MultipartFile file) {
        String n = file.getOriginalFilename();
        return (n != null && n.contains(".")) ? n.substring(n.lastIndexOf('.') + 1).toLowerCase() : "jpg";
    }
}
