import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_colors.dart';
import '../../core/app_screen.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/token_service.dart';

class MaisScreen extends StatelessWidget {
  const MaisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      appBar: AppBar(title: const Text('Mais opções')),
      padding: EdgeInsets.zero,
      child: ListView(
        children: [

           const SizedBox(height: 16),
          _buildSection(context, 'GERENCIAMENTO', [
            _MenuItem(
              icon: Icons.person_outline,
              iconBg: AppColors.primarySurface,
              iconColor: AppColors.primary,
              title: 'Propriedade/Feirante',
              subtitle: 'Preferências do sistema',
              onTap: () {},
            ),
            _MenuItem(
              icon: Icons.logout,
              iconBg: const Color(0xFFFAEBE8),
              iconColor: AppColors.error,
              title: 'Relatório',
              subtitle: 'Encerrar sessão',
              titleColor: AppColors.error,
              onTap: () => _logout(context),
            ),
          ]),
          const SizedBox(height: 16),
          _buildSection(context, 'CONTA', [
            _MenuItem(
              icon: Icons.person_outline,
              iconBg: AppColors.primarySurface,
              iconColor: AppColors.primary,
              title: 'Perfil',
              subtitle: 'Preferências do sistema',
              onTap: () {},
            ),
            _MenuItem(
              icon: Icons.logout,
              iconBg: const Color(0xFFFAEBE8),
              iconColor: AppColors.error,
              title: 'Sair',
              subtitle: 'Encerrar sessão',
              titleColor: AppColors.error,
              onTap: () => _logout(context),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String label, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.grey200,
                  letterSpacing: 1.2,
                ),
          ),
        ),
        ...items,
        const SizedBox(height: 24),
      ],
    );
  }

  Future<void> _logout(BuildContext context) async {
    final tokenService = TokenService();
    await AuthService(tokenService).logout();
    if (context.mounted) context.go('/login');
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.titleColor,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: titleColor,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.grey200, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
