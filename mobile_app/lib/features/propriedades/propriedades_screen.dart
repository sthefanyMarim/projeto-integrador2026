import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_error.dart';
import '../../core/app_colors.dart';
import '../../core/app_feedback.dart';
import '../../core/app_screen.dart';
import '../../core/online_only_guard.dart';
import '../../data/models/propriedade_model.dart';
import '../../data/services/propriedade_service.dart';
import '../../data/services/token_service.dart';

class PropriedadesScreen extends StatefulWidget {
  const PropriedadesScreen({super.key});

  @override
  State<PropriedadesScreen> createState() => _PropriedadesScreenState();
}

class _PropriedadesScreenState extends State<PropriedadesScreen> {
  static const _filters = ['Todas', 'Ativas', 'Inativas'];

  late final PropriedadeService _service;
  String _selectedFilter = 'Todas';
  List<PropriedadeModel> _all = [];
  String _search = '';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = PropriedadeService(TokenService());
    _load();
  }

  Future<void> _load({bool silent = false}) async {
    if (mounted) {
      setState(() {
        if (!silent) _loading = true;
        _error = null;
      });
    }
    try {
      final list = await _service.listar();
      if (!mounted) return;
      setState(() {
        _all = list;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = ApiError.message(
          e,
          fallback: 'Não foi possível carregar as propriedades.',
        );
      });
      if (silent) {
        AppFeedback.warning(context, 'Não foi possível atualizar a lista.');
      }
    }
  }

  List<PropriedadeModel> get _filtered {
    var list = _all;
    if (_selectedFilter == 'Ativas') list = list.where((p) => p.ativa).toList();
    if (_selectedFilter == 'Inativas') {
      list = list.where((p) => !p.ativa).toList();
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list
          .where(
            (p) =>
                p.nome.toLowerCase().contains(q) ||
                p.nomeProprietario.toLowerCase().contains(q),
          )
          .toList();
    }
    return list;
  }

  int _count(String filter) {
    if (filter == 'Todas') return _all.length;
    if (filter == 'Ativas') return _all.where((p) => p.ativa).length;
    return _all.where((p) => !p.ativa).length;
  }

  Future<void> _openCreateForm() async {
    final canProceed = await OnlineOnlyGuard.ensureServerReachable(
      context,
      actionLabel: 'O cadastro de propriedades',
    );
    if (!canProceed || !mounted) return;

    await context.push('/propriedades/novo');
    if (mounted) {
      _load(silent: true);
    }
  }

  Future<void> _openEditForm(PropriedadeModel propriedade) async {
    final canProceed = await OnlineOnlyGuard.ensureServerReachable(
      context,
      actionLabel: 'A edição de propriedades',
    );
    if (!canProceed || !mounted) return;

    await context.push(
      '/propriedades/${propriedade.id}/editar',
      extra: propriedade,
    );
    if (mounted) {
      _load(silent: true);
    }
  }

  Future<void> _excluir(PropriedadeModel p) async {
    final canProceed = await OnlineOnlyGuard.ensureServerReachable(
      context,
      actionLabel: 'A exclusão de propriedades',
    );
    if (!canProceed || !mounted) return;

    final confirm = await AppFeedback.confirm(
      context,
      title: 'Excluir propriedade',
      message: 'Deseja excluir "${p.nome}"? Esta ação não pode ser desfeita.',
      confirmLabel: 'Excluir',
      isDanger: true,
    );
    if (!confirm || !mounted) return;
    try {
      await _service.excluir(p.id);
      await _load(silent: true);
      if (mounted) {
        AppFeedback.success(context, 'Propriedade excluída com sucesso.');
      }
    } catch (e) {
      if (mounted) {
        await AppFeedback.apiError(
          context,
          e,
          title: 'Erro ao excluir',
          fallback: 'Não foi possível excluir a propriedade.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      safeAreaTop: false,
      safeAreaBottom: true,
      backgroundColor: AppColors.background,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  _buildSearchBar(),
                  const SizedBox(height: 12),
                  _buildFilterChips(),
                  const SizedBox(height: 12),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.only(top: 48),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_error != null && _all.isEmpty)
                    _buildErrorCard()
                  else if (_filtered.isEmpty)
                    _buildEmptyCard()
                  else
                    ..._filtered.map(_buildPropertyCard),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Row(
            children: [
              InkWell(
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
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Propriedades',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (!_loading)
                      Text(
                        '${_all.length} unidade${_all.length == 1 ? '' : 's'} cadastrada${_all.length == 1 ? '' : 's'}',
                        style: const TextStyle(
                          color: Color(0xFFD9F7E0),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _openCreateForm,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    '+ Nova',
                    style: TextStyle(
                      color: Color(0xFF00AE56),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        onChanged: (v) => setState(() => _search = v),
        decoration: const InputDecoration(
          hintText: 'Buscar propriedade...',
          hintStyle: TextStyle(color: AppColors.textHint, fontSize: 13),
          prefixIcon: Icon(Icons.search, color: AppColors.textHint, size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  void _openFilterModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bottomPad = MediaQuery.of(ctx).padding.bottom;
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(24, 16, 24, bottomPad + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDDDDD),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Text(
                    'Filtrar por status',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => Navigator.pop(ctx),
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.close,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFF0F0F0)),
              const SizedBox(height: 8),
              ..._filters.map((filter) {
                final isActive = filter == _selectedFilter;
                final count = _loading ? null : _count(filter);
                return InkWell(
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _selectedFilter = filter);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 4,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isActive
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          size: 20,
                          color: isActive
                              ? AppColors.primary
                              : AppColors.textMuted,
                        ),
                        const SizedBox(width: 14),
                        Text(
                          count != null ? '$filter ($count)' : filter,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isActive
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isActive
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChips() {
    final isFiltered = _selectedFilter != 'Todas';
    return Row(
      children: [
        GestureDetector(
          onTap: _openFilterModal,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isFiltered ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isFiltered ? Colors.transparent : AppColors.border,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.tune,
                  size: 16,
                  color: isFiltered ? Colors.white : AppColors.textMuted,
                ),
                const SizedBox(width: 8),
                Text(
                  isFiltered ? _selectedFilter : 'Filtros',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isFiltered ? Colors.white : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: 16,
                  color: isFiltered ? Colors.white : AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
        if (isFiltered) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => _selectedFilter = 'Todas'),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.close,
                size: 16,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPropertyCard(PropriedadeModel p) {
    final initials = _initials(p.nome);
    final bgColor = _avatarBgColor(p.nome);
    final textColor = _avatarTextColor(p.nome);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 6,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.push('/propriedades/${p.id}', extra: p),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => context.push('/propriedades/${p.id}', extra: p),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.nome,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    p.nomeProprietario,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: p.ativa
                      ? const Color(0xFFE0FAEB)
                      : const Color(0xFFEDEDED),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  p.ativa ? 'Ativa' : 'Inativa',
                  style: TextStyle(
                    color: p.ativa
                        ? const Color(0xFF00AE56)
                        : AppColors.textHint,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _openEditForm(p),
                    child: Container(
                      width: 32,
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0FAEB),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.edit_outlined,
                        size: 14,
                        color: Color(0xFF00AE56),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => _excluir(p),
                    child: Container(
                      width: 32,
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAEBE8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.delete_outlined,
                        size: 14,
                        color: Color(0xFFD32F2F),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => context.push('/propriedades/${p.id}', extra: p),
            child: const Icon(
              Icons.chevron_right,
              color: AppColors.textHint,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_outlined, color: AppColors.textMuted),
          const SizedBox(height: 12),
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
    );
  }

  Widget _buildEmptyCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Text(
        'Nenhuma propriedade encontrada.',
        style: TextStyle(color: AppColors.textSecondary),
      ),
    );
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
