import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'env.dart';

class OnlineOnlyGuard {
  static Future<bool> ensureServerReachable(
    BuildContext context, {
    required String actionLabel,
  }) async {
    try {
      final response = await Dio(
        BaseOptions(
          baseUrl: Env.baseUrl,
          connectTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 4),
          validateStatus: (status) => status != null && status < 500,
        ),
      ).get('/actuator/health');

      if (response.statusCode == 200) {
        return true;
      }
    } on DioException {
    } catch (_) {
    }

    if (context.mounted) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(
            '$actionLabel fica disponivel apenas online nesta fase do aplicativo.',
          ),
        ),
      );
    }

    return false;
  }
}
