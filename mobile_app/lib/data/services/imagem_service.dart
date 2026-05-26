import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import 'api_client.dart';
import 'token_service.dart';

class ImagemService {
  ImagemService(TokenService tokenService) : _client = ApiClient(tokenService);

  final ApiClient _client;

  Future<String> uploadFotoPerfil(XFile foto) async {
    final formData = FormData.fromMap({
      'arquivo': await MultipartFile.fromFile(
        foto.path,
        filename: foto.name,
        contentType: DioMediaType.parse(_mimeType(foto.name)),
      ),
    });
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/api/imagens/perfil',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return (response.data?['url'] as String?) ?? '';
  }

  Future<String> uploadFotoVisita(int visitaId, XFile foto) async {
    final formData = FormData.fromMap({
      'arquivo': await MultipartFile.fromFile(
        foto.path,
        filename: foto.name,
        contentType: DioMediaType.parse(_mimeType(foto.name)),
      ),
    });
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/api/imagens/visita/$visitaId',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return (response.data?['url'] as String?) ?? '';
  }

  String _mimeType(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    return switch (ext) {
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
  }
}
