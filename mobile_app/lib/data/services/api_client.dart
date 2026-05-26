import 'package:dio/dio.dart';

import '../../core/env.dart';
import '../models/auth_model.dart';
import 'token_service.dart';

class ApiClient {
  ApiClient(this._tokenService) {
    _dio = Dio(
      BaseOptions(
        baseUrl: Env.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenService.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (!_deveTentarRefresh(error)) {
            return handler.next(error);
          }

          final refreshed = await _refreshWithQueue();
          if (!refreshed) {
            await _tokenService.clearTokens();
            return handler.next(error);
          }

          try {
            final retry = await _repeatRequest(error.requestOptions);
            return handler.resolve(retry);
          } on DioException catch (retryError) {
            return handler.next(retryError);
          }
        },
      ),
    );
  }

  late final Dio _dio;
  final TokenService _tokenService;
  Future<bool>? _refreshFuture;

  Dio get dio => _dio;

  bool _deveTentarRefresh(DioException error) {
    final statusCode = error.response?.statusCode;
    final path = error.requestOptions.path;
    final alreadyRetried = error.requestOptions.extra['retried'] == true;

    if (statusCode != 401 || alreadyRetried) {
      return false;
    }

    return !_isAuthPath(path);
  }

  bool _isAuthPath(String path) {
    return path.contains('/api/auth/login') ||
        path.contains('/api/auth/refresh') ||
        path.contains('/api/auth/logout');
  }

  Future<bool> _refreshWithQueue() async {
    _refreshFuture ??= _doRefresh().whenComplete(() {
      _refreshFuture = null;
    });
    return _refreshFuture!;
  }

  Future<bool> _doRefresh() async {
    final refreshToken = await _tokenService.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return false;
    }

    final response = await Dio().post(
      '${Env.baseUrl}/api/auth/refresh',
      data: {'refreshToken': refreshToken},
      options: Options(receiveTimeout: const Duration(seconds: 8)),
    );

    final loginResponse = LoginResponse.fromJson(
      response.data as Map<String, dynamic>,
    );
    await _tokenService.saveTokens(loginResponse);
    return true;
  }

  Future<Response<dynamic>> _repeatRequest(RequestOptions options) async {
    final token = await _tokenService.getAccessToken();
    final headers = Map<String, dynamic>.from(options.headers);
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return _dio.request<dynamic>(
      options.path,
      data: options.data,
      queryParameters: options.queryParameters,
      cancelToken: options.cancelToken,
      onReceiveProgress: options.onReceiveProgress,
      onSendProgress: options.onSendProgress,
      options: Options(
        method: options.method,
        headers: headers,
        sendTimeout: options.sendTimeout,
        receiveTimeout: options.receiveTimeout,
        contentType: options.contentType,
        responseType: options.responseType,
        validateStatus: options.validateStatus,
        extra: {...options.extra, 'retried': true},
      ),
    );
  }
}
