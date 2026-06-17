import '../models/propriedade_model.dart';
import '../models/page_response.dart';
import 'api_client.dart';
import 'network_service.dart';
import 'offline_data_service.dart';
import 'token_service.dart';

class PropriedadeService {
  PropriedadeService(TokenService tokenService)
    : _apiClient = ApiClient(tokenService);

  final ApiClient _apiClient;
  final OfflineDataService _offlineDataService = OfflineDataService.instance;

  Future<List<PropriedadeModel>> listarAtivas() async {
    try {
      final response = await _apiClient.dio.get('/api/propriedades/ativas');
      final rawList = _asRawList(response.data);
      await _offlineDataService.cachePropriedades(rawList);
      return _offlineDataService.readCachedPropriedades(ativa: true);
    } catch (error) {
      if (!NetworkService.isOfflineError(error)) {
        rethrow;
      }
      return _offlineDataService.readCachedPropriedades(ativa: true);
    }
  }

  Future<List<PropriedadeModel>> listar({bool? ativa}) async {
    final params = <String, dynamic>{'size': 500, 'sort': 'nome'};
    if (ativa != null) params['ativa'] = ativa;

    try {
      final response = await _apiClient.dio.get(
        '/api/propriedades',
        queryParameters: params,
      );
      final data = response.data;
      final rawList = data is List<dynamic>
          ? _asRawList(data)
          : (PageResponse.fromJson(
              data as Map<String, dynamic>,
              (json) => json,
            ).content);
      await _offlineDataService.cachePropriedades(rawList);
      return _offlineDataService.readCachedPropriedades(ativa: ativa);
    } catch (error) {
      if (!NetworkService.isOfflineError(error)) {
        rethrow;
      }
      return _offlineDataService.readCachedPropriedades(ativa: ativa);
    }
  }

  Future<PropriedadeModel> buscarPorId(int id) async {
    try {
      final response = await _apiClient.dio.get('/api/propriedades/$id');
      final raw = Map<String, dynamic>.from(response.data as Map);
      await _offlineDataService.upsertPropriedadeSnapshot(raw);
      return PropriedadeModel.fromJson(raw);
    } catch (error) {
      if (!NetworkService.isOfflineError(error)) {
        rethrow;
      }
      final cached = await _offlineDataService.findCachedPropriedade(id);
      if (cached != null) {
        return cached;
      }
      rethrow;
    }
  }

  Future<PropriedadeModel> criar(Map<String, dynamic> data) async {
    final response = await _apiClient.dio.post('/api/propriedades', data: data);
    final raw = Map<String, dynamic>.from(response.data as Map);
    await _offlineDataService.upsertPropriedadeSnapshot(raw);
    return PropriedadeModel.fromJson(raw);
  }

  Future<PropriedadeModel> atualizar(int id, Map<String, dynamic> data) async {
    final response = await _apiClient.dio.put(
      '/api/propriedades/$id',
      data: data,
    );
    final raw = Map<String, dynamic>.from(response.data as Map);
    await _offlineDataService.upsertPropriedadeSnapshot(raw);
    return PropriedadeModel.fromJson(raw);
  }

  Future<void> excluir(int id) async {
    await _apiClient.dio.delete('/api/propriedades/$id');
    await _offlineDataService.deletePropriedadeByServerId(id);
  }

  List<Map<String, dynamic>> _asRawList(Object? data) {
    return (data as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}
