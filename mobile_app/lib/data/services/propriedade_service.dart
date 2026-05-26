import '../models/propriedade_model.dart';
import '../models/page_response.dart';
import 'api_client.dart';
import 'token_service.dart';

class PropriedadeService {
  PropriedadeService(TokenService tokenService)
    : _apiClient = ApiClient(tokenService);

  final ApiClient _apiClient;

  Future<List<PropriedadeModel>> listarAtivas() async {
    final response = await _apiClient.dio.get('/api/propriedades/ativas');
    final rawList = response.data as List<dynamic>? ?? const [];
    return rawList
        .whereType<Map<String, dynamic>>()
        .map(PropriedadeModel.fromJson)
        .toList();
  }

  Future<List<PropriedadeModel>> listar({bool? ativa}) async {
    final params = <String, dynamic>{'size': 500, 'sort': 'nome'};
    if (ativa != null) params['ativa'] = ativa;
    final response = await _apiClient.dio.get(
      '/api/propriedades',
      queryParameters: params,
    );
    final data = response.data;

    if (data is List<dynamic>) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(PropriedadeModel.fromJson)
          .toList();
    }

    final page = PageResponse.fromJson(
      data as Map<String, dynamic>,
      PropriedadeModel.fromJson,
    );
    return page.content;
  }

  Future<PropriedadeModel> buscarPorId(int id) async {
    final response = await _apiClient.dio.get('/api/propriedades/$id');
    return PropriedadeModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PropriedadeModel> criar(Map<String, dynamic> data) async {
    final response = await _apiClient.dio.post('/api/propriedades', data: data);
    return PropriedadeModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PropriedadeModel> atualizar(int id, Map<String, dynamic> data) async {
    final response = await _apiClient.dio.put(
      '/api/propriedades/$id',
      data: data,
    );
    return PropriedadeModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> excluir(int id) async {
    await _apiClient.dio.delete('/api/propriedades/$id');
  }
}
