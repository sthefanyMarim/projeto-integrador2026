import '../models/encaminhamento_model.dart';
import '../models/page_response.dart';
import 'api_client.dart';
import 'token_service.dart';

class EncaminhamentoService {
  EncaminhamentoService(TokenService tokenService)
    : _apiClient = ApiClient(tokenService);

  final ApiClient _apiClient;

  Future<List<EncaminhamentoModel>> listar({
    String? status,
    int size = 100,
  }) async {
    final response = await _apiClient.dio.get(
      '/api/encaminhamentos',
      queryParameters: {
        'size': size,
        ...?status == null ? null : {'status': status},
      },
    );

    final page = PageResponse.fromJson(
      response.data as Map<String, dynamic>,
      EncaminhamentoModel.fromJson,
    );
    return page.content;
  }

  Future<EncaminhamentoModel> concluir(int id) async {
    final response = await _apiClient.dio.post(
      '/api/encaminhamentos/$id/concluir',
    );
    return EncaminhamentoModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> cancelar(int id) async {
    await _apiClient.dio.delete('/api/encaminhamentos/$id');
  }
}
