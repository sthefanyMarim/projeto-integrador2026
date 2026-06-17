import 'package:flutter/material.dart';

import '../../core/api_error.dart';
import '../../core/app_colors.dart';
import '../../core/app_feedback.dart';
import '../../core/app_refresh_bus.dart';
import '../../core/app_screen.dart';
import '../../data/models/encaminhamento_model.dart';
import '../../data/services/encaminhamento_service.dart';
import '../../data/services/token_service.dart';

class EncaminhamentosScreen extends StatefulWidget {
  const EncaminhamentosScreen({super.key});

  @override
  State<EncaminhamentosScreen> createState() => _EncaminhamentosScreenState();
}

class _EncaminhamentosScreenState extends State<EncaminhamentosScreen> {
  static const _filters = [
    'Todos',
    'Pendentes',
    'Concluidos',
    'Atrasados',
    'Cancelados',
  ];
  static const _statusMap = {
    'Todos': null,
    'Pendentes': 'PENDENTE',
    'Concluidos': 'CONCLUIDO',
    'Atrasados': 'ATRASADO',
    'Cancelados': 'CANCELADO',
  };

  late final EncaminhamentoService _service;
  String _selectedFilter = 'Todos';
  String? _selectedPropriedade;
  List<EncaminhamentoModel> _tasks = const [];
  bool _loading = true;
  String? _error;

  List<EncaminhamentoModel> get _displayedTasks => _selectedPropriedade == null
      ? _tasks
      : _tasks.where((t) => t.propriedadeNome == _selectedPropriedade).toList();

  List<String> get _availablePropriedades {
    final nomes = _tasks.map((t) => t.propriedadeNome).toSet().toList();
    nomes.sort();
    return nomes;
  }

  @override
  void initState() {
    super.initState();
    _service = EncaminhamentoService(TokenService());
    AppRefreshBus.notifier.addListener(_handleRefreshBus);
    _loadTasks();
  }

  @override
  void dispose() {
    AppRefreshBus.notifier.removeListener(_handleRefreshBus);
    super.dispose();
  }

  void _handleRefreshBus() {
    _loadTasks(silent: true);
  }

  Future<void> _loadTasks({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final tasks = await _service.listar(status: _statusMap[_selectedFilter]);
      if (!mounted) {
        return;
      }
      setState(() {
        _tasks = tasks;
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
          fallback: 'Não foi possível carregar os encaminhamentos.',
        );
      });
    }
  }

  Future<void> _concluir(EncaminhamentoModel task) async {
    final confirmar = await AppFeedback.confirm(
      context,
      title: 'Concluir encaminhamento',
      message: 'Deseja marcar este encaminhamento como concluído?',
    );
    if (!confirmar || !mounted) {
      return;
    }

    try {
      await _service.concluir(task.id);
      AppRefreshBus.notifyChanged();
      await _loadTasks(silent: true);
      if (mounted) {
        AppFeedback.success(context, 'Encaminhamento concluído com sucesso.');
      }
    } catch (error) {
      if (mounted) {
        await AppFeedback.apiError(
          context,
          error,
          title: 'Erro ao concluir',
          fallback: 'Não foi possível concluir o encaminhamento.',
        );
      }
    }
  }

  Future<void> _cancelar(EncaminhamentoModel task) async {
    final confirmar = await AppFeedback.confirm(
      context,
      title: 'Cancelar encaminhamento',
      message: 'Deseja cancelar este encaminhamento?',
      confirmLabel: 'Cancelar',
      cancelLabel: 'Voltar',
      isDanger: true,
    );
    if (!confirmar || !mounted) {
      return;
    }

    try {
      await _service.cancelar(task.id);
      AppRefreshBus.notifyChanged();
      await _loadTasks(silent: true);
      if (mounted) {
        AppFeedback.success(context, 'Encaminhamento cancelado.');
      }
    } catch (error) {
      if (mounted) {
        await AppFeedback.apiError(
          context,
          error,
          title: 'Erro ao cancelar',
          fallback: 'Não foi possível cancelar o encaminhamento.',
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
              onRefresh: _loadTasks,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                children: [
                  _buildFilterBar(),
                  const SizedBox(height: 20),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.only(top: 48),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_error != null && _tasks.isEmpty)
                    _buildErrorCard()
                  else if (_displayedTasks.isEmpty)
                    _buildEmptyCard()
                  else
                    ..._displayedTasks.map(_buildTaskCard),
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
      width: double.infinity,
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
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (Navigator.canPop(context))
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => Navigator.maybePop(context),
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
              const Text(
                'Encaminhamentos',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Acompanhe e finalize as pendências',
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

  void _openFilterModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
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
                return InkWell(
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _selectedFilter = filter);
                    _loadTasks();
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
                          filter,
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

  void _openPropriedadeModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
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
                    'Filtrar por propriedade',
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
                      child: Icon(Icons.close, color: AppColors.textMuted, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFF0F0F0)),
              const SizedBox(height: 8),
              ..._availablePropriedades.map((nome) {
                final isActive = nome == _selectedPropriedade;
                return InkWell(
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _selectedPropriedade = nome);
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
                          color: isActive ? AppColors.primary : AppColors.textMuted,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            nome,
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

  Widget _buildFilterBar() {
    final isStatusFiltered = _selectedFilter != 'Todos';
    final isPropFiltered = _selectedPropriedade != null;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
      children: [
        GestureDetector(
          onTap: _openFilterModal,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isStatusFiltered ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isStatusFiltered ? Colors.transparent : AppColors.border,
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
                  color: isStatusFiltered ? Colors.white : AppColors.textMuted,
                ),
                const SizedBox(width: 8),
                Text(
                  isStatusFiltered ? _selectedFilter : 'Status',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isStatusFiltered
                        ? Colors.white
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: 16,
                  color: isStatusFiltered ? Colors.white : AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
        if (isStatusFiltered) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              setState(() => _selectedFilter = 'Todos');
              _loadTasks();
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.close, size: 16, color: AppColors.textMuted),
            ),
          ),
        ],
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _availablePropriedades.isEmpty ? null : _openPropriedadeModal,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isPropFiltered ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isPropFiltered ? Colors.transparent : AppColors.border,
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
                  Icons.location_on_outlined,
                  size: 16,
                  color: isPropFiltered ? Colors.white : AppColors.textMuted,
                ),
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 110),
                  child: Text(
                    isPropFiltered ? _selectedPropriedade! : 'Propriedade',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isPropFiltered
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: 16,
                  color: isPropFiltered ? Colors.white : AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
        if (isPropFiltered) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => _selectedPropriedade = null),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.close, size: 16, color: AppColors.textMuted),
            ),
          ),
        ],
      ],
      ),
    );
  }

  Widget _buildTaskCard(EncaminhamentoModel task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.propriedadeNome,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        task.responsavel == null || task.responsavel!.isEmpty
                            ? 'Responsável não informado'
                            : 'Responsável: ${task.responsavel}',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      if (task.verificacaoLabel.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Verificacao: ${task.verificacaoLabel}',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Text(
                  _deadlineLabel(task),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              task.acaoRealizada,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatusChip(task.prioridadeLabel, _priorityColor(task)),
                const SizedBox(width: 8),
                _buildStatusChip(task.statusLabel, _statusColor(task)),
                const Spacer(),
                if (task.podeCancelar) ...[
                  InkWell(
                    onTap: () => _cancelar(task),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.grey100,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: AppColors.textSecondary,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                if (task.podeConcluir)
                  InkWell(
                    onTap: () => _concluir(task),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'Concluir',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor(task).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      task.statusLabel,
                      style: TextStyle(
                        color: _statusColor(task),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
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
            onPressed: _loadTasks,
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
        'Nenhum encaminhamento encontrado para este filtro.',
        style: TextStyle(color: AppColors.textSecondary),
      ),
    );
  }

  Color _priorityColor(EncaminhamentoModel task) {
    return switch (task.prioridade) {
      'ALTA' => AppColors.error,
      'MEDIA' => AppColors.warning,
      'CRITICA' => AppColors.error,
      _ => AppColors.success,
    };
  }

  Color _statusColor(EncaminhamentoModel task) {
    return switch (task.status) {
      'CONCLUIDO' => AppColors.success,
      'ATRASADO' => AppColors.error,
      'CANCELADO' => AppColors.textMuted,
      _ => AppColors.warning,
    };
  }

  String _deadlineLabel(EncaminhamentoModel task) {
    if (task.prazo == null) {
      return 'Sem prazo';
    }

    final day = task.prazo!.day.toString().padLeft(2, '0');
    final month = task.prazo!.month.toString().padLeft(2, '0');
    return 'Prazo: $day/$month/${task.prazo!.year}';
  }
}
