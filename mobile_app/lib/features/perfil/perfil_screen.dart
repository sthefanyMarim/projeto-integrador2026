import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_error.dart';
import '../../core/app_colors.dart';
import '../../core/app_feedback.dart';
import '../../core/env.dart';
import '../../core/app_screen.dart';
import '../../core/online_only_guard.dart';
import '../../data/models/usuario_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/dashboard_service.dart';
import '../../data/services/token_service.dart';
import '../../data/services/usuario_service.dart';
import '../../data/services/visita_service.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _tokenService = TokenService();
  late final UsuarioService _usuarioService;
  late final DashboardService _dashboardService;
  late final VisitaService _visitaService;

  UsuarioModel? _usuario;
  int _totalPropriedades = 0;
  int _totalVisitas = 0;
  int _totalPendencias = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _usuarioService = UsuarioService(_tokenService);
    _dashboardService = DashboardService(_tokenService);
    _visitaService = VisitaService(_tokenService);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final userInfo = await _tokenService.getUserInfo();
      final isTecnico = userInfo.tipo != 'ADMIN';
      final usuario = await _usuarioService.buscarMe();

      var totalPropriedades = 0;
      var totalVisitas = 0;
      var totalPendencias = 0;

      if (isTecnico) {
        try {
          final results = await Future.wait([
            _dashboardService.fetchDashboard(),
            _visitaService.contarTotal(),
          ]);
          final dashboard = results[0] as dynamic;
          totalPropriedades = dashboard.totalPropriedades as int;
          totalPendencias = dashboard.pendenciasUrgentes as int;
          totalVisitas = results[1] as int;
        } catch (_) {
          totalVisitas = await _visitaService.contarTotal().catchError(
            (_) => 0,
          );
        }
      }

      if (!mounted) return;
      setState(() {
        _usuario = usuario;
        _totalPropriedades = totalPropriedades;
        _totalVisitas = totalVisitas;
        _totalPendencias = totalPendencias;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = ApiError.message(
          e,
          fallback: 'Não foi possível carregar o perfil.',
        );
      });
    }
  }

  bool get _isTecnico => _usuario?.tipo != 'ADMIN';

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      safeAreaTop: false,
      safeAreaBottom: true,
      backgroundColor: AppColors.background,
      padding: EdgeInsets.zero,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildError()
          : _buildContent(context),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _load,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final u = _usuario!;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context, u),
          if (_isTecnico) _buildStats(),
          const SizedBox(height: 20),
          _buildSection(label: 'INFORMAÇÕES', child: _buildInfoCard(u)),
          const SizedBox(height: 12),
          _buildSection(
            label: 'CONFIGURAÇÕES',
            child: _buildConfigCard(context, u),
          ),
          const SizedBox(height: 12),
          _buildSection(label: 'CONTA', child: _buildContaCard(context)),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UsuarioModel u) {
    final initials = _initials(u.nome);
    final hasBack = Navigator.canPop(context);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: AppColors.primaryGradient,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  const Text(
                    'Meu Perfil',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (hasBack)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: InkWell(
                        onTap: () => context.pop(),
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _avatarBgColor(u.nome),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4),
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: u.fotoUrl != null
                        ? ClipOval(
                            child: Image.network(
                              Env.rewriteMediaUrl(u.fotoUrl!),
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              cacheWidth: 240,
                              cacheHeight: 240,
                              errorBuilder: (_, e, s) => Text(
                                initials,
                                style: TextStyle(
                                  color: _avatarTextColor(u.nome),
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          )
                        : Text(
                            initials,
                            style: TextStyle(
                              color: _avatarTextColor(u.nome),
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: -2,
                    child: GestureDetector(
                      onTap: () => _openUserEdit(u),
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit,
                          size: 14,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                u.nome,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                u.tipo == 'ADMIN' ? 'Administrador' : 'Técnico / Bolsista',
                style: const TextStyle(color: Color(0xFFCCF2D9), fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStats() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStatItem(
            _totalPropriedades.toString(),
            'Propriedades\nem que atua',
          ),
          _buildStatDivider(),
          _buildStatItem(_totalVisitas.toString(), 'Visitas'),
          _buildStatDivider(),
          _buildStatItem(_totalPendencias.toString(), 'Pendências'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(width: 1, height: 36, color: const Color(0xFFEEEEEE));
  }

  Widget _buildSection({required String label, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoCard(UsuarioModel u) {
    final rows = <_InfoRow>[
      _InfoRow(label: 'Matrícula', value: u.matricula),
      _InfoRow(label: 'E-mail', value: u.email),
      if (u.telefone != null && u.telefone!.isNotEmpty)
        _InfoRow(label: 'Telefone', value: u.telefone!),
      const _InfoRow(label: 'Instituição', value: 'UFSM — Colégio Politécnico'),
      if (u.criadoEm != null)
        _InfoRow(label: 'Membro desde', value: _formatDate(u.criadoEm!)),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: rows.asMap().entries.map((entry) {
          final isLast = entry.key == rows.length - 1;
          final row = entry.value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.label,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      row.value,
                      style: const TextStyle(
                        color: Color(0xFF111111),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                const Divider(
                  height: 1,
                  color: Color(0xFFF5F5F5),
                  indent: 20,
                  endIndent: 20,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildConfigCard(BuildContext context, UsuarioModel u) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildConfigItem(
            iconBg: const Color(0xFFDBEDF7),
            icon: Icons.person_outline,
            iconColor: const Color(0xFF2980BA),
            title: 'Editar Perfil',
            subtitle: 'Alterar foto, nome e e-mail',
            onTap: () => _openUserEdit(u),
          ),
          const Divider(
            height: 1,
            color: Color(0xFFF5F5F5),
            indent: 20,
            endIndent: 20,
          ),
          _buildConfigItem(
            iconBg: const Color(0xFFEDE7F6),
            icon: Icons.lock_outline,
            iconColor: const Color(0xFF7E57C2),
            title: 'Alterar Senha',
            subtitle: 'Segurança da conta',
            onTap: () => _showAlterarSenhaSheet(context, u.id),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigItem({
    required Color iconBg,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
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
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111111),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textHint,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContaCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _logout(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.errorSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.logout,
                  color: AppColors.error,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sair da Conta',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Encerrar sessão atual',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textHint,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openUserEdit(UsuarioModel usuario) async {
    final canProceed = await OnlineOnlyGuard.ensureServerReachable(
      context,
      actionLabel: 'A edicao de perfil',
    );
    if (!canProceed || !mounted) return;

    await context.push('/usuarios/${usuario.id}/editar', extra: usuario);
    if (mounted) {
      _load();
    }
  }

  Future<void> _showAlterarSenhaSheet(BuildContext context, int userId) async {
    final canProceed = await OnlineOnlyGuard.ensureServerReachable(
      context,
      actionLabel: 'A alteracao de senha',
    );
    if (!canProceed || !context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) =>
          _AlterarSenhaSheet(userId: userId, service: _usuarioService),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final confirm = await AppFeedback.confirm(
      context,
      title: 'Sair da conta',
      message: 'Deseja encerrar a sessão atual?',
      confirmLabel: 'Sair',
      isDanger: true,
    );
    if (!confirm || !context.mounted) return;
    await AuthService(_tokenService).logout();
    if (context.mounted) context.go('/login');
  }

  String _formatDate(DateTime date) {
    const months = [
      'Janeiro',
      'Fevereiro',
      'Março',
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
    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.length >= 2
        ? name.substring(0, 2).toUpperCase()
        : name.toUpperCase();
  }

  Color _avatarBgColor(String name) {
    const palette = [
      Color(0xFFE0FAEB),
      Color(0xFFFAE5F5),
      Color(0xFFDBEDF7),
      Color(0xFFFCF5DB),
      Color(0xFFF5F5F5),
    ];
    final hash = name.codeUnits.fold(0, (a, c) => a + c);
    return palette[hash % palette.length];
  }

  Color _avatarTextColor(String name) {
    const palette = [
      Color(0xFF006A18),
      Color(0xFF9C2678),
      Color(0xFF2980BA),
      Color(0xFF996B0F),
      Color(0xFFCCCCCC),
    ];
    final hash = name.codeUnits.fold(0, (a, c) => a + c);
    return palette[hash % palette.length];
  }
}

class _AlterarSenhaSheet extends StatefulWidget {
  const _AlterarSenhaSheet({required this.userId, required this.service});

  final int userId;
  final UsuarioService service;

  @override
  State<_AlterarSenhaSheet> createState() => _AlterarSenhaSheetState();
}

class _AlterarSenhaSheetState extends State<_AlterarSenhaSheet> {
  final _senhaCtrl = TextEditingController();
  final _confirmarCtrl = TextEditingController();
  bool _obscureSenha = true;
  bool _obscureConfirmar = true;
  bool _loading = false;

  @override
  void dispose() {
    _senhaCtrl.dispose();
    _confirmarCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_senhaCtrl.text.length < 6) {
      AppFeedback.warning(context, 'A senha deve ter no mínimo 6 caracteres.');
      return;
    }
    if (_senhaCtrl.text != _confirmarCtrl.text) {
      AppFeedback.warning(context, 'As senhas não coincidem.');
      return;
    }
    final canProceed = await OnlineOnlyGuard.ensureServerReachable(
      context,
      actionLabel: 'A alteracao de senha',
    );
    if (!canProceed || !mounted) return;

    setState(() => _loading = true);
    try {
      await widget.service.atualizar(widget.userId, {'senha': _senhaCtrl.text});
      if (mounted) {
        Navigator.pop(context);
        AppFeedback.success(context, 'Senha alterada com sucesso.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        await AppFeedback.error(
          context,
          message: ApiError.message(
            e,
            fallback: 'Não foi possível alterar a senha.',
          ),
          title: 'Erro ao alterar senha',
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final bottomPad =
        MediaQuery.of(context).viewInsets.bottom +
        MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, bottomPad + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Alterar Senha',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Segurança da conta',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),
          _fieldLabel('Nova Senha'),
          const SizedBox(height: 6),
          _buildField(_senhaCtrl, 'Mínimo 6 caracteres', _obscureSenha, () {
            setState(() => _obscureSenha = !_obscureSenha);
          }),
          const SizedBox(height: 14),
          _fieldLabel('Confirmar Nova Senha'),
          const SizedBox(height: 6),
          _buildField(_confirmarCtrl, 'Repita a senha', _obscureConfirmar, () {
            setState(() => _obscureConfirmar = !_obscureConfirmar);
          }),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _loading ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _loading ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Salvar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    TextEditingController ctrl,
    String hint,
    bool obscure,
    VoidCallback toggleObscure,
  ) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: TextField(
        controller: ctrl,
        obscureText: obscure,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          suffixIcon: Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: toggleObscure,
              child: Icon(
                obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 18,
                color: AppColors.textMuted,
              ),
            ),
          ),
          suffixIconConstraints: const BoxConstraints(
            minWidth: 36,
            minHeight: 36,
          ),
        ),
        style: const TextStyle(color: Color(0xFF111111), fontSize: 13),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF666666),
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _InfoRow {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;
}
