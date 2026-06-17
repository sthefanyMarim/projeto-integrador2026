import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/env.dart';
import '../core/jwt_utils.dart';
import '../data/models/auth_model.dart';
import '../data/models/propriedade_model.dart';
import '../data/services/token_service.dart';
import '../features/relatorios/relatorios_screen.dart';
import '../features/perfil/perfil_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/shell/app_shell.dart';
import '../features/home/home_screen.dart';
import '../features/calendario/calendario_screen.dart';
import '../features/encaminhamentos/encaminhamentos_screen.dart';
import '../features/mais/mais_screen.dart';
import '../features/propriedades/propriedades_screen.dart';
import '../features/propriedades/propriedade_perfil_screen.dart';
import '../features/propriedades/propriedade_form_screen.dart';
import '../features/usuarios/usuarios_screen.dart';
import '../features/usuarios/usuario_form_screen.dart';
import '../data/models/usuario_model.dart';

GoRouter buildRouter(TokenService tokenService) {
  return GoRouter(
    initialLocation: '/home',
    redirect: (context, state) => _validateSession(state, tokenService),
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/usuarios',
        builder: (context, state) => const UsuariosScreen(),
      ),
      GoRoute(
        path: '/usuarios/novo',
        builder: (context, state) => const UsuarioFormScreen(),
      ),
      GoRoute(
        path: '/usuarios/:id/editar',
        builder: (context, state) {
          final usuario = state.extra as UsuarioModel?;
          return UsuarioFormScreen(usuario: usuario);
        },
      ),
      GoRoute(
        path: '/relatorios',
        builder: (context, state) => const RelatoriosScreen(),
      ),
      GoRoute(
        path: '/perfil',
        builder: (context, state) => const PerfilScreen(),
      ),
      GoRoute(
        path: '/propriedades',
        builder: (context, state) => const PropriedadesScreen(),
      ),
      GoRoute(
        path: '/propriedades/novo',
        builder: (context, state) => const PropriedadeFormScreen(),
      ),
      GoRoute(
        path: '/propriedades/:id',
        builder: (context, state) {
          final prop = state.extra as PropriedadeModel?;
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (prop != null) return PropriedadePerfilScreen(propriedade: prop);
          return PropriedadePerfilScreen(
            propriedade: PropriedadeModel(
              id: id ?? 0,
              nome: '...',
              nomeProprietario: '',
              ativa: true,
            ),
          );
        },
      ),
      GoRoute(
        path: '/propriedades/:id/editar',
        builder: (context, state) {
          final prop = state.extra as PropriedadeModel?;
          return PropriedadeFormScreen(propriedade: prop);
        },
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

Future<String?> _redirectByRole(
  GoRouterState state,
  TokenService tokenService,
) async {
  final userInfo = await tokenService.getUserInfo();
  final isAdmin = userInfo.tipo == 'ADMIN';
  final location = state.matchedLocation;

  final tecnicoOnly = ['/calendario', '/encaminhamentos'];

  if (isAdmin && tecnicoOnly.any(location.startsWith)) {
    return '/home';
  }

  const adminOnlyExact = ['/usuarios', '/relatorios'];
  final isAdminOnlyArea = adminOnlyExact.any(
    (path) =>
        location == path ||
        location.startsWith('$path/novo') ||
        (path == '/relatorios' && location.startsWith(path)),
  );

  if (!isAdmin && isAdminOnlyArea) {
    return '/home';
  }

  return null;
}

Future<String?> _validateSession(
  GoRouterState state,
  TokenService tokenService,
) async {
  final isLogin = state.matchedLocation == '/login';

  final accessToken = await tokenService.getAccessToken();

  if (accessToken == null) {
    return isLogin ? null : '/login';
  }

  if (!JwtUtils.isExpired(accessToken)) {
    if (isLogin) return '/home';
    return _redirectByRole(state, tokenService);
  }

  final refreshToken = await tokenService.getRefreshToken();

  if (refreshToken == null || refreshToken.isEmpty) {
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
    if (isLogin) return '/home';
    return _redirectByRole(state, tokenService);
  } on DioException {
    await tokenService.clearTokens();
    return isLogin ? null : '/login';
  }
}
