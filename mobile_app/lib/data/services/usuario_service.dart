import '../models/usuario_model.dart';
import '../models/page_response.dart';
import 'api_client.dart';
import 'token_service.dart';

class UsuarioService {
  UsuarioService(TokenService tokenService)
    : _apiClient = ApiClient(tokenService);

  final ApiClient _apiClient;

  Future<List<UsuarioModel>> listar({String? busca, String? tipo}) async {
    final params = <String, dynamic>{'size': 500, 'sort': 'nome'};
    if (busca != null && busca.isNotEmpty) params['busca'] = busca;
    if (tipo != null && tipo != 'TODOS') params['tipo'] = tipo;

    final response = await _apiClient.dio.get(
      '/api/usuarios',
      queryParameters: params,
    );
    final data = response.data;

    if (data is List<dynamic>) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(UsuarioModel.fromJson)
          .toList();
    }

    final page = PageResponse.fromJson(
      data as Map<String, dynamic>,
      UsuarioModel.fromJson,
    );
    return page.content;
  }

  Future<UsuarioModel> buscarMe() async {
    final response = await _apiClient.dio.get('/api/usuarios/me');
    return UsuarioModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<UsuarioModel> buscarPorId(int id) async {
    final response = await _apiClient.dio.get('/api/usuarios/$id');
    return UsuarioModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<UsuarioModel> criar(Map<String, dynamic> data) async {
    final response = await _apiClient.dio.post('/api/usuarios', data: data);
    return UsuarioModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<UsuarioModel> atualizar(int id, Map<String, dynamic> data) async {
    final response = await _apiClient.dio.put('/api/usuarios/$id', data: data);
    return UsuarioModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> alternarStatus(int id) async {
    await _apiClient.dio.patch('/api/usuarios/$id/status');
  }

  Future<void> deletar(int id) async {
    await _apiClient.dio.delete('/api/usuarios/$id');
  }
}
