import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_error.dart';
import '../../core/api_error_dialog.dart';
import '../../core/app_colors.dart';
import '../../core/app_screen.dart';
import '../../data/models/usuario_model.dart';
import '../../data/services/token_service.dart';
import '../../data/services/usuario_service.dart';

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  static const _filters = ['Todos', 'TÃ©cnicos', 'Admins'];

  late final UsuarioService _service;
  String _selectedFilter = 'Todos';
  List<UsuarioModel> _all = [];
  String _search = '';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = UsuarioService(TokenService());
    _load();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        _loading = true;
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
          fallback: 'NÃ£o foi possÃ­vel carregar os usuÃ¡rios.',
        );
      });
    }
  }

  List<UsuarioModel> get _filtered {
    var list = _all;
    if (_selectedFilter == 'TÃ©cnicos') {
      list = list.where((u) => u.tipo == 'TECNICO').toList();
    } else if (_selectedFilter == 'Admins') {
      list = list.where((u) => u.tipo == 'ADMIN').toList();
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list
          .where(
            (u) =>
                u.nome.toLowerCase().contains(q) ||
                u.matricula.toLowerCase().contains(q),
          )
          .toList();
    }
    return list;
  }

  int _count(String filter) {
    if (filter == 'Todos') return _all.length;
    if (filter == 'TÃ©cnicos') {
      return _all.where((u) => u.tipo == 'TECNICO').length;
    }
    return _all.where((u) => u.tipo == 'ADMIN').length;
  }

  Future<void> _deletar(UsuarioModel u) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir usuÃ¡rio'),
        content: Text(
          'Deseja excluir "${u.nome}"? Esta aÃ§Ã£o nÃ£o pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('NÃ£o'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await _service.deletar(u.id);
      await _load(silent: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('UsuÃ¡rio excluÃ­do com sucesso.')),
        );
      }
    } catch (e) {
      if (mounted) {
        await ApiErrorDialog.show(
          context,
          e,
          title: 'Erro ao excluir',
          fallback: 'NÃ£o foi possÃ­vel excluir o usuÃ¡rio.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      safeAreaTop: false,
      safeAreaBottom: false,
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
                    ..._filtered.map(_buildUserCard),
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
                      'UsuÃ¡rios',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (!_loading)
                      Text(
                        '${_all.length} usuÃ¡rio${_all.length == 1 ? '' : 's'} cadastrado${_all.length == 1 ? '' : 's'}',
                        style: const TextStyle(
                          color: Color(0xFFD9F7E0),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () async {
                  await context.push('/usuarios/novo');
                  _load(silent: true);
                },
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
                    '+ Novo',
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
          hintText: 'Buscar por nome ou matrÃ­cula...',
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
                    'Filtrar por tipo',
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
    final isFiltered = _selectedFilter != 'Todos';
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
            onTap: () => setState(() => _selectedFilter = 'Todos'),
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

  Widget _buildUserCard(UsuarioModel u) {
    final initials = _initials(u.nome);
    final bgColor = _avatarBgColor(u.nome);
    final textColor = _avatarTextColor(u.nome);
    final isTecnico = u.tipo == 'TECNICO';

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
          Container(
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  u.nome,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  u.matricula,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isTecnico
                        ? const Color(0xFFDBEDF7)
                        : const Color(0xFFFCF0E8),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isTecnico ? 'TÃ©cnico' : 'Admin',
                    style: TextStyle(
                      color: isTecnico
                          ? const Color(0xFF2980BA)
                          : const Color(0xFFF57C00),
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: u.ativo
                          ? const Color(0xFF00AE56)
                          : AppColors.textHint,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    u.ativo ? 'Ativo' : 'Inativo',
                    style: TextStyle(
                      color: u.ativo
                          ? const Color(0xFF00AE56)
                          : AppColors.textHint,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      await context.push('/usuarios/${u.id}/editar', extra: u);
                      _load(silent: true);
                    },
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
                    onTap: () => _deletar(u),
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
        'Nenhum usuÃ¡rio encontrado.',
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
