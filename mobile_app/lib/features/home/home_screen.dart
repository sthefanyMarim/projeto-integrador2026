import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_error.dart';
import '../../core/app_colors.dart';
import '../../core/app_refresh_bus.dart';
import '../../core/app_screen.dart';
import '../../data/models/dashboard_model.dart';
import '../../data/models/encaminhamento_model.dart';
import '../../data/models/visita_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/dashboard_service.dart';
import '../../data/services/token_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final TokenService _tokenService;
  late final DashboardService _dashboardService;
  DashboardModel? _dashboard;
  bool _loading = true;
  String? _error;
  bool _isAdmin = false;
  String _nomeUsuario = 'Usuario';

  static const _weekdays = [
    'Segunda',
    'TerÃ§a',
    'Quarta',
    'Quinta',
    'Sexta',
    'SÃ¡bado',
    'Domingo',
  ];

  static const _months = [
    'Janeiro',
    'Fevereiro',
    'MarÃ§o',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];

  @override
  void initState() {
    super.initState();
    _tokenService = TokenService();
    _dashboardService = DashboardService(_tokenService);
    AppRefreshBus.notifier.addListener(_handleRefreshBus);
    _loadInitialState();
  }

  @override
  void dispose() {
    AppRefreshBus.notifier.removeListener(_handleRefreshBus);
    super.dispose();
  }

  void _handleRefreshBus() {
    if (_isAdmin) {
      _loadInitialState(silent: true);
      return;
    }
    _loadDashboard(silent: true);
  }

  Future<void> _loadInitialState({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final userInfo = await _tokenService.getUserInfo();
      final isAdmin = userInfo.tipo == 'ADMIN';
      final nome = userInfo.nome?.trim();

      if (!mounted) {
        return;
      }

      setState(() {
        _isAdmin = isAdmin;
        _nomeUsuario = nome == null || nome.isEmpty ? 'Usuario' : nome;
      });

      if (isAdmin) {
        setState(() {
          _loading = false;
          _error = null;
        });
        return;
      }

      await _loadDashboard(silent: silent);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _error = ApiError.message(
          error,
          fallback: 'Nao foi possivel carregar seus dados.',
        );
      });
    }
  }

  Future<void> _loadDashboard({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final dashboard = await _dashboardService.fetchDashboard();
      if (!mounted) {
        return;
      }
      setState(() {
        _dashboard = dashboard;
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = ApiError.message(
          error,
          fallback: 'NÃ£o foi possÃ­vel carregar o dashboard.',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isAdmin) {
      return _buildAdminHome(context);
    }

    if (_loading && _dashboard == null) {
      return const AppScreen(
        backgroundColor: AppColors.background,
        padding: EdgeInsets.zero,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null && _dashboard == null) {
      return AppScreen(
        backgroundColor: AppColors.background,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                color: AppColors.textMuted,
                size: 36,
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadDashboard,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    final dashboard = _dashboard!;

    return AppScreen(
      safeAreaTop: false,
      safeAreaBottom: false,
      padding: EdgeInsets.zero,
      backgroundColor: AppColors.background,
      child: RefreshIndicator(
        onRefresh: _loadDashboard,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          children: [
            _buildHeader(context, dashboard),
            if (_error != null) _buildInlineError(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _buildMetricCards(dashboard),
                  const SizedBox(height: 24),
                  _buildSectionHeader(
                    'Visitas de Hoje',
                    'Ver todas',
                    onTap: () => context.go('/calendario'),
                  ),
                  const SizedBox(height: 12),
                  if (dashboard.visitasHoje.isEmpty)
                    _buildEmptyCard('Nenhuma visita agendada para hoje.')
                  else
                    ...dashboard.visitasHoje.map(_buildVisitCard),
                  const SizedBox(height: 24),
                  _buildSectionHeader(
                    'PendÃªncias Urgentes',
                    'Ver todas',
                    onTap: () => context.go('/encaminhamentos'),
                  ),
                  const SizedBox(height: 12),
                  if (dashboard.pendenciasUrgentesLista.isEmpty)
                    _buildEmptyCard('Nenhuma pendÃªncia urgente no momento.')
                  else
                    ...dashboard.pendenciasUrgentesLista.map(_buildPendingCard),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminHome(BuildContext context) {
    final actions = [
      _AdminActionData(
        icon: Icons.home_work_outlined,
        iconBg: AppColors.primarySurface,
        iconColor: AppColors.primary,
        title: 'Propriedades / Feirantes',
        subtitle: 'Gerenciar unidades produtoras',
        onTap: () => context.push('/propriedades'),
      ),
      _AdminActionData(
        icon: Icons.groups_2_outlined,
        iconBg: AppColors.infoSurface,
        iconColor: AppColors.info,
        title: 'Usuarios',
        subtitle: 'Gerenciar tecnicos, bolsistas e administradores',
        onTap: () => context.push('/usuarios'),
      ),
      _AdminActionData(
        icon: Icons.assessment_outlined,
        iconBg: AppColors.warningSurface,
        iconColor: AppColors.warning,
        title: 'Relatorios',
        subtitle: 'Consultar indicadores e historicos do sistema',
        onTap: () => context.push('/relatorios'),
      ),
      _AdminActionData(
        icon: Icons.person_outline,
        iconBg: AppColors.primarySurface,
        iconColor: AppColors.primary,
        title: 'Perfil',
        subtitle: 'Ver dados da sua conta',
        onTap: () => context.push('/perfil'),
      ),
      _AdminActionData(
        icon: Icons.logout,
        iconBg: AppColors.errorSurface,
        iconColor: AppColors.error,
        title: 'Sair',
        subtitle: 'Encerrar sessao',
        titleColor: AppColors.error,
        onTap: () => _logout(context),
      ),
    ];

    return AppScreen(
      safeAreaTop: false,
      safeAreaBottom: false,
      padding: EdgeInsets.zero,
      backgroundColor: AppColors.background,
      child: RefreshIndicator(
        onRefresh: () => _loadInitialState(silent: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          children: [
            _buildAdminHeader(context),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Acessos administrativos',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...actions.map(_buildAdminActionCard),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.primaryGradient,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Admin',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      color: Colors.white24,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings_outlined,
                      color: Colors.white,
                      size: 23,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                'Ola, $_nomeUsuario',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Painel administrativo do PoliVisitas',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.headerSubtitle,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminActionCard(_AdminActionData action) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: action.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: action.iconBg,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(action.icon, color: action.iconColor, size: 21),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        action.title,
                        style: TextStyle(
                          color: action.titleColor ?? AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        action.subtitle,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.grey200,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    await AuthService(_tokenService).logout();
    if (context.mounted) {
      context.go('/login');
    }
  }

  Widget _buildHeader(BuildContext context, DashboardModel dashboard) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.primaryGradient,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'TÃ©cnico/Bolsista',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      color: Colors.white24,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'OlÃ¡, ${dashboard.nomeUsuario}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _formatToday(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.headerSubtitle,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInlineError() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.warningSurface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.warning, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _error!,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCards(DashboardModel dashboard) {
    final cards = [
      _MetricCardData(
        value: '${dashboard.totalPropriedades}',
        label: 'Propriedades',
        color: AppColors.primary,
      ),
      _MetricCardData(
        value: '${dashboard.visitasAtrasadas}',
        label: 'Atrasadas',
        color: AppColors.error,
      ),
      _MetricCardData(
        value: '${dashboard.pendenciasUrgentes}',
        label: 'PendÃªncias',
        color: AppColors.warning,
      ),
    ];

    return Row(
      children: cards.map((card) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(left: card == cards.first ? 0 : 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: card.color,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  card.label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionHeader(
    String title,
    String action, {
    VoidCallback? onTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            action,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVisitCard(VisitaModel data) {
    final statusColor = data.concluida
        ? AppColors.success
        : data.atrasada
        ? AppColors.error
        : AppColors.primary;

    return GestureDetector(
      onTap: () => context.go('/calendario'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 84,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.propriedadeNome,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          data.horaCurta,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                        _buildChip(data.statusLabel, statusColor),
                        if (data.tipoLabel.isNotEmpty)
                          _buildChip(data.tipoLabel, AppColors.primaryLight),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingCard(EncaminhamentoModel data) {
    final levelColor = data.atrasado
        ? AppColors.error
        : data.prioridade == 'ALTA'
        ? AppColors.warning
        : AppColors.primaryLight;

    return GestureDetector(
      onTap: () => context.go('/encaminhamentos'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.propriedadeNome,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.acaoRealizada,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (data.responsavel != null &&
                      data.responsavel!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'ResponsÃ¡vel: ${data.responsavel}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            _buildChip(data.prioridadeLabel, levelColor),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        message,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _formatToday() {
    final now = DateTime.now();
    final weekday = _weekdays[now.weekday - 1];
    final month = _months[now.month - 1];
    return '$weekday, ${now.day} de $month';
  }
}

class _MetricCardData {
  const _MetricCardData({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;
}

class _AdminActionData {
  const _AdminActionData({
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
}
