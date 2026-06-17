import 'package:dio/dio.dart';

import '../../core/env.dart';

class NetworkService {
  Future<bool> isServerReachable() async {
    try {
      final response = await Dio(
        BaseOptions(
          baseUrl: Env.baseUrl,
          connectTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 4),
          validateStatus: (status) => status != null && status < 500,
        ),
      ).get('/actuator/health');

      return response.statusCode == 200;
    } on DioException {
      return false;
    } catch (_) {
      return false;
    }
  }

  static bool isOfflineError(Object error) {
    if (error is! DioException) {
      return false;
    }

    return switch (error.type) {
      DioExceptionType.connectionError => true,
      DioExceptionType.connectionTimeout => true,
      DioExceptionType.receiveTimeout => true,
      DioExceptionType.sendTimeout => true,
      _ => error.response == null,
    };
  }
}
