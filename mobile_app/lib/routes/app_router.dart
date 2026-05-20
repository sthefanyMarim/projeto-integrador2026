import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';

import '../core/env.dart';
import '../core/jwt_utils.dart';
import '../data/models/auth_model.dart';
import '../data/services/token_service.dart';
import '../features/auth/login_screen.dart';
import '../features/shell/app_shell.dart';
import '../features/home/home_screen.dart';
import '../features/calendario/calendario_screen.dart';
import '../features/encaminhamentos/encaminhamentos_screen.dart';
import '../features/mais/mais_screen.dart';

GoRouter buildRouter(TokenService tokenService) {
  return GoRouter(
    initialLocation: '/home',
    redirect: (context, state) => _validateSession(state, tokenService),
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/calendario',
            builder: (context, state) => const CalendarioScreen(),
          ),
          GoRoute(
            path: '/encaminhamentos',
            builder: (context, state) => const EncaminhamentosScreen(),
          ),
          GoRoute(
            path: '/mais',
            builder: (context, state) => const MaisScreen(),
          ),
        ],
      ),
    ],
  );
}

// ── Validação de sessão ───────────────────────────────────────────────────────

Future<String?> _validateSession(
  GoRouterState state,
  TokenService tokenService,
) async {
  final isLogin = state.matchedLocation == '/login';

  final accessToken = await tokenService.getAccessToken();

  // Sem token → login
  if (accessToken == null) {
    return isLogin ? null : '/login';
  }

  // Token válido → não bloquear
  if (!JwtUtils.isExpired(accessToken)) {
    return isLogin ? '/home' : null;
  }

  // Access token expirado → tentar refresh
  final refreshToken = await tokenService.getRefreshToken();

  if (refreshToken == null || JwtUtils.isExpired(refreshToken)) {
    await tokenService.clearTokens();
    return isLogin ? null : '/login';
  }

  try {
    final response = await Dio().post(
      '${Env.baseUrl}/api/auth/refresh',
      data: {'refreshToken': refreshToken},
      options: Options(receiveTimeout: const Duration(seconds: 8)),
    );
    final loginResponse = LoginResponse.fromJson(
      response.data as Map<String, dynamic>,
    );
    await tokenService.saveTokens(loginResponse);
    return isLogin ? '/home' : null;
  } on DioException {
    // Refresh falhou (token inválido/revogado) → força login
    await tokenService.clearTokens();
    return isLogin ? null : '/login';
  }
}
