import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Wrapper padrão para todas as telas do app.
/// Aplica SafeArea, cor de fundo e Scaffold de forma consistente.
///
/// Uso básico:
/// ```dart
/// AppScreen(
///   appBar: AppBar(title: Text('Título')),
///   child: MeuConteudo(),
/// )
/// ```
class AppScreen extends StatelessWidget {
  const AppScreen({
    super.key,
    required this.child,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.backgroundColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    this.safeAreaTop = true,
    this.safeAreaBottom = true,
    this.resizeToAvoidBottomInset = true,
    this.scrollable = false,
  });

  final Widget child;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final Color? backgroundColor;

  /// Padding padrão aplicado ao conteúdo. Passe EdgeInsets.zero para remover.
  final EdgeInsetsGeometry padding;

  /// Controla se SafeArea protege o topo (status bar). Desative em telas com
  /// header que deve ir até o topo da tela (ex.: tela de login com gradiente).
  final bool safeAreaTop;
  final bool safeAreaBottom;

  final bool resizeToAvoidBottomInset;

  /// Se true, envolve o conteúdo em SingleChildScrollView.
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    Widget body = padding != EdgeInsets.zero
        ? Padding(padding: padding, child: child)
        : child;

    if (scrollable) {
      body = SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: body,
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor ?? AppColors.background,
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: SafeArea(
        top: safeAreaTop,
        bottom: safeAreaBottom,
        child: body,
      ),
    );
  }
}

/// Versão scrollável pré-configurada — atalho para telas que precisam rolar.
class AppScrollScreen extends StatelessWidget {
  const AppScrollScreen({
    super.key,
    required this.child,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.backgroundColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    this.safeAreaTop = true,
    this.safeAreaBottom = true,
  });

  final Widget child;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final Color? backgroundColor;
  final EdgeInsetsGeometry padding;
  final bool safeAreaTop;
  final bool safeAreaBottom;

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      backgroundColor: backgroundColor,
      padding: padding,
      safeAreaTop: safeAreaTop,
      safeAreaBottom: safeAreaBottom,
      scrollable: true,
      child: child,
    );
  }
}
