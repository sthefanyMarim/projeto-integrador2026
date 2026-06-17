import '../models/encaminhamento_model.dart';
import 'api_client.dart';
import 'network_service.dart';
import 'offline_data_service.dart';
import 'token_service.dart';

class EncaminhamentoService {
  EncaminhamentoService(TokenService tokenService)
    : _apiClient = ApiClient(tokenService);

  final ApiClient _apiClient;
  final OfflineDataService _offlineDataService = OfflineDataService.instance;

  Future<List<EncaminhamentoModel>> listar({
    String? status,
    int size = 100,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/encaminhamentos',
        queryParameters: {
          'size': size,
          ...?status == null ? null : {'status': status},
        },
      );

      final rawPage = response.data as Map<String, dynamic>;
      final rawContent = (rawPage['content'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      await _offlineDataService.cacheEncaminhamentos(rawContent);
      return _offlineDataService.readCachedEncaminhamentos(status: status);
    } catch (error) {
      if (!NetworkService.isOfflineError(error)) {
        rethrow;
      }
      return _offlineDataService.readCachedEncaminhamentos(status: status);
    }
  }

  Future<EncaminhamentoModel> concluir(int id) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/encaminhamentos/$id/concluir',
      );
      final raw = Map<String, dynamic>.from(response.data as Map);
      await _offlineDataService.upsertEncaminhamentoSnapshot(raw);
      return EncaminhamentoModel.fromJson(raw);
    } catch (error) {
      if (!NetworkService.isOfflineError(error)) {
        rethrow;
      }
      final cached = await _offlineDataService.readCachedEncaminhamentos();
      final task = cached.firstWhere(
        (item) => item.id == id,
        orElse: () => throw error,
      );
      return _offlineDataService.saveOfflineConcludedTask(task);
    }
  }

  Future<void> cancelar(int id) async {
    try {
      await _apiClient.dio.delete('/api/encaminhamentos/$id');
      await _offlineDataService.updateCachedEncaminhamentoStatus(id, 'CANCELADO');
    } catch (error) {
      if (!NetworkService.isOfflineError(error)) {
        rethrow;
      }
      final cached = await _offlineDataService.readCachedEncaminhamentos();
      final task = cached.firstWhere(
        (item) => item.id == id,
        orElse: () => throw error,
      );
      await _offlineDataService.saveOfflineCancelledTask(task);
    }
  }
}
