import 'package:dio/dio.dart';
import '../models/auth_model.dart';
import 'api_client.dart';
import 'token_service.dart';

class AuthService {
  final TokenService _tokenService;
  late final ApiClient _apiClient;

  AuthService(this._tokenService) {
    _apiClient = ApiClient(_tokenService);
  }

  Dio get dio => _apiClient.dio;

  Future<LoginResponse> login(String matricula, String senha) async {
    final response = await dio.post(
      '/api/auth/login',
      data: LoginRequest(matricula: matricula, senha: senha).toJson(),
    );
    final loginResponse = LoginResponse.fromJson(
      response.data as Map<String, dynamic>,
    );
    await _tokenService.saveTokens(loginResponse);
    return loginResponse;
  }

  Future<void> logout() async {
    final refreshToken = await _tokenService.getRefreshToken();
    if (refreshToken != null) {
      try {
        await dio.post(
          '/api/auth/logout',
          data: {'refreshToken': refreshToken},
        );
      } catch (_) {}
    }
    await _tokenService.clearTokens();
  }
}
