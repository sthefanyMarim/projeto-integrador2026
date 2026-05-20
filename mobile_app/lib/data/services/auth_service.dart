import 'package:dio/dio.dart';
import '../../core/env.dart';
import '../models/auth_model.dart';
import 'token_service.dart';

class AuthService {
  late final Dio _dio;
  final TokenService _tokenService;
  bool _isRefreshing = false;

  AuthService(this._tokenService) {
    _dio = Dio(BaseOptions(
      baseUrl: Env.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _tokenService.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401 && !_isRefreshing) {
          _isRefreshing = true;
          try {
            final refreshed = await _doRefresh();
            if (refreshed) {
              final token = await _tokenService.getAccessToken();
              final opts = error.requestOptions;
              opts.headers['Authorization'] = 'Bearer $token';
              final retry = await _dio.fetch(opts);
              _isRefreshing = false;
              return handler.resolve(retry);
            }
          } catch (_) {}
          _isRefreshing = false;
          await _tokenService.clearTokens();
        }
        handler.next(error);
      },
    ));
  }

  Dio get dio => _dio;

  Future<LoginResponse> login(String matricula, String senha) async {
    final response = await _dio.post(
      '/api/auth/login',
      data: LoginRequest(matricula: matricula, senha: senha).toJson(),
    );
    final loginResponse = LoginResponse.fromJson(response.data as Map<String, dynamic>);
    await _tokenService.saveTokens(loginResponse);
    return loginResponse;
  }

  Future<bool> _doRefresh() async {
    final refreshToken = await _tokenService.getRefreshToken();
    if (refreshToken == null) return false;

    final response = await Dio().post(
      '${Env.baseUrl}/api/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    final loginResponse = LoginResponse.fromJson(response.data as Map<String, dynamic>);
    await _tokenService.saveTokens(loginResponse);
    return true;
  }

  Future<void> logout() async {
    final refreshToken = await _tokenService.getRefreshToken();
    if (refreshToken != null) {
      try {
        await _dio.post('/api/auth/logout', data: {'refreshToken': refreshToken});
      } catch (_) {}
    }
    await _tokenService.clearTokens();
  }
}
