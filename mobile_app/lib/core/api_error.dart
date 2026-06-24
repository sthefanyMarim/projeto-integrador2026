import 'package:dio/dio.dart';

class ApiErrorDetails {
  const ApiErrorDetails({
    required this.message,
    required this.statusCode,
    this.fieldErrors = const {},
  });

  final String message;
  final int? statusCode;
  final Map<String, String> fieldErrors;

  String get statusCodeLabel => statusCode?.toString() ?? 'Sem resposta';

  String get fullMessage {
    if (fieldErrors.isEmpty) {
      return message;
    }

    final details = fieldErrors.entries
        .map((entry) => '${entry.key}: ${entry.value}')
        .join('\n');

    return '$message\n\n$details';
  }
}

class ApiError {
  static ApiErrorDetails details(
    Object error, {
    String fallback = 'Não foi possível concluir a operação.',
  }) {
    if (error is DioException) {
      final response = error.response;
      final data = response?.data;
      final statusCode = response?.statusCode ?? _statusFromBody(data);
      final fieldErrors = _fieldErrorsFromBody(data);
      final bodyMessage = _messageFromBody(data);

      final message = _isConnectivityError(error)
          ? fallback
          : bodyMessage ??
                (error.message != null && error.message!.trim().isNotEmpty
                    ? error.message!.trim()
                    : fallback);

      return ApiErrorDetails(
        message: message,
        statusCode: statusCode,
        fieldErrors: fieldErrors,
      );
    }

    return ApiErrorDetails(message: fallback, statusCode: null);
  }

  static String message(
    Object error, {
    String fallback = 'Não foi possível concluir a operação.',
  }) {
    return details(error, fallback: fallback).fullMessage;
  }

  static String? _messageFromBody(Object? data) {
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
    }

    return null;
  }

  static int? _statusFromBody(Object? data) {
    if (data is Map<String, dynamic>) {
      final status = data['status'];
      if (status is int) {
        return status;
      }
      if (status is num) {
        return status.toInt();
      }
    }

    return null;
  }

  static Map<String, String> _fieldErrorsFromBody(Object? data) {
    if (data is! Map<String, dynamic>) {
      return const {};
    }

    final errors = data['erros'];
    if (errors is! Map) {
      return const {};
    }

    final result = <String, String>{};
    for (final entry in errors.entries) {
      final key = entry.key?.toString();
      final value = entry.value?.toString();
      if (key == null || key.isEmpty || value == null || value.isEmpty) {
        continue;
      }
      result[key] = value;
    }
    return result;
  }

  static bool _isConnectivityError(DioException error) {
    return switch (error.type) {
      DioExceptionType.connectionError => true,
      DioExceptionType.connectionTimeout => true,
      DioExceptionType.receiveTimeout => true,
      DioExceptionType.sendTimeout => true,
      _ => error.response == null,
    };
  }
}
