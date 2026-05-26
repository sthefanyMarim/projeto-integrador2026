import 'package:flutter/material.dart';

import 'api_error.dart';
import 'app_colors.dart';

class ApiErrorDialog {
  static Future<void> show(
    BuildContext context,
    Object error, {
    String title = 'Erro na API',
    String fallback = 'Nao foi possivel concluir a operacao.',
  }) {
    final details = ApiError.details(error, fallback: fallback);
    return showDetails(context, title: title, details: details);
  }

  static Future<void> showDetails(
    BuildContext context, {
    required String title,
    required ApiErrorDetails details,
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.errorSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Status code: ${details.statusCodeLabel}',
                  style: const TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Mensagem',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              SelectableText(
                details.fullMessage,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }
}
