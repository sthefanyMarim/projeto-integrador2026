import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/app_theme.dart';
import 'data/services/token_service.dart';
import 'routes/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const PoliVisitasApp());
}

class PoliVisitasApp extends StatelessWidget {
  const PoliVisitasApp({super.key});

  @override
  Widget build(BuildContext context) {
    final tokenService = TokenService();
    final router = buildRouter(tokenService);

    return MaterialApp.router(
      title: 'PoliVisitas',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
