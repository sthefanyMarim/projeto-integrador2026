import '../models/usuario_model.dart';
import '../models/page_response.dart';
import 'api_client.dart';
import 'network_service.dart';
import 'offline_data_service.dart';
import 'token_service.dart';

class UsuarioService {
  UsuarioService(TokenService tokenService)
    : _tokenService = tokenService,
      _apiClient = ApiClient(tokenService);

  final TokenService _tokenService;
  final ApiClient _apiClient;
  final OfflineDataService _offlineDataService = OfflineDataService.instance;

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
    try {
      final response = await _apiClient.dio.get('/api/usuarios/me');
      final raw = Map<String, dynamic>.from(response.data as Map);
      await _offlineDataService.cacheCurrentUserProfile(raw);
      final usuario = UsuarioModel.fromJson(raw);
      await _tokenService.saveUserIdentity(
        nome: usuario.nome,
        userId: usuario.id,
        tipo: usuario.tipo,
      );
      return usuario;
    } catch (error) {
      if (!NetworkService.isOfflineError(error)) {
        rethrow;
      }

      final userInfo = await _tokenService.getUserInfo();
      final cached = await _offlineDataService.readCachedCurrentUserProfile(
        userInfo.userId,
      );
      if (cached != null) {
        return cached;
      }

      if (userInfo.userId != null &&
          userInfo.nome != null &&
          userInfo.tipo != null) {
        return UsuarioModel(
          id: userInfo.userId!,
          nome: userInfo.nome!,
          matricula: '',
          email: '',
          tipo: userInfo.tipo!,
          ativo: true,
        );
      }

      rethrow;
    }
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
    final raw = Map<String, dynamic>.from(response.data as Map);
    final usuario = UsuarioModel.fromJson(raw);
    final current = await _tokenService.getUserInfo();
    if (current.userId == usuario.id) {
      await _offlineDataService.cacheCurrentUserProfile(raw);
      await _tokenService.saveUserIdentity(
        nome: usuario.nome,
        userId: usuario.id,
        tipo: usuario.tipo,
      );
    }
    return usuario;
  }

  Future<void> alternarStatus(int id) async {
    await _apiClient.dio.patch('/api/usuarios/$id/status');
  }

  Future<void> deletar(int id) async {
    await _apiClient.dio.delete('/api/usuarios/$id');
  }
}
