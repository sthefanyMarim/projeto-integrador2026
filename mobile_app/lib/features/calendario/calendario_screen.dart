import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/api_error.dart';
import '../../core/app_colors.dart';
import '../../core/app_feedback.dart';
import '../../core/app_refresh_bus.dart';
import '../../core/app_screen.dart';
import '../../core/calendar_selection_bus.dart';
import '../../core/online_only_guard.dart';
import '../../data/models/visita_model.dart';
import '../../data/services/token_service.dart';
import '../../data/services/visita_service.dart';
import '../visita/agendamento_modal.dart';
import '../visita/visita_detalhe_modal.dart';
import '../visita/visita_form_options.dart';
import '../visita/visita_tecnica_screen.dart';

class CalendarioScreen extends StatefulWidget {
  const CalendarioScreen({super.key});

  @override
  State<CalendarioScreen> createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends State<CalendarioScreen> {
  late final VisitaService _service;
  late final TokenService _tokenService;
  late DateTime _focusedDay;
  late DateTime _selectedDay;

  int? _currentUserId;
  Map<DateTime, List<VisitaModel>> _eventsByDate = const {};
  bool _loading = true;
  bool _runningAction = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final today = DateUtils.dateOnly(DateTime.now());
    _focusedDay = today;
    _selectedDay = today;
    CalendarSelectionBus.selectedDate.value = today;
    _tokenService = TokenService();
    _service = VisitaService(_tokenService);
    AppRefreshBus.notifier.addListener(_handleRefreshBus);
    _loadVisits();
  }

  @override
  void dispose() {
    AppRefreshBus.notifier.removeListener(_handleRefreshBus);
    super.dispose();
  }

  void _handleRefreshBus() {
    _loadVisits(silent: true);
  }

  Future<void> _loadVisits({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      _currentUserId ??= (await _tokenService.getUserInfo()).userId;

      final visits = await _service.listar(size: 500);
      visits.sort(_compareVisits);

      final grouped = <DateTime, List<VisitaModel>>{};
      for (final visit in visits) {
        if (_currentUserId != null && visit.usuarioId != _currentUserId) {
          continue;
        }
        final dateKey = DateUtils.dateOnly(visit.dataVisita);
        grouped.putIfAbsent(dateKey, () => <VisitaModel>[]).add(visit);
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _eventsByDate = grouped;
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
          fallback: 'Não foi possível carregar as visitas.',
        );
      });
      if (!silent && mounted) {
        await AppFeedback.apiError(
          context,
          error,
          title: 'Erro ao carregar visitas',
          fallback: 'Não foi possível carregar as visitas.',
        );
      }
    }
  }

  int _compareVisits(VisitaModel a, VisitaModel b) {
    final dateCompare = DateUtils.dateOnly(
      a.dataVisita,
    ).compareTo(DateUtils.dateOnly(b.dataVisita));
    if (dateCompare != 0) {
      return dateCompare;
    }

    return a.horaVisita.compareTo(b.horaVisita);
  }

  List<VisitaModel> _eventsForDay(DateTime day) {
    return _eventsByDate[DateUtils.dateOnly(day)] ?? const [];
  }

  List<VisitaModel> get _selectedDayVisits => _eventsForDay(_selectedDay);

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }

  Color _statusColor(VisitaModel visit) {
    if (visit.concluida) return AppColors.success;
    if (visit.cancelada) return AppColors.textMuted;
    if (visit.atrasada) return AppColors.error;
    return AppColors.primary;
  }

  Color _urgenciaColor(String urgencia) {
    return switch (urgencia) {
      'CRITICA' => AppColors.error,
      'ALTA' => AppColors.warning,
      'MEDIA' => AppColors.info,
      _ => AppColors.success,
    };
  }

  Future<void> _cancelVisit(VisitaModel visit) async {
    final canProceed = await OnlineOnlyGuard.ensureServerReachable(
      context,
      actionLabel: 'O cancelamento de visitas',
    );
    if (!canProceed || !mounted) {
      return;
    }

    final confirmed = await AppFeedback.confirm(
      context,
      title: 'Cancelar visita',
      message: 'Deseja cancelar a visita em ${visit.propriedadeNome}?',
      confirmLabel: 'Cancelar',
      isDanger: true,
    );

    if (!confirmed || !mounted) {
      return;
    }

    setState(() => _runningAction = true);

    try {
      await _service.cancelar(visit.id);
      AppRefreshBus.notifyChanged();
      await _loadVisits(silent: true);
      if (mounted) {
        AppFeedback.success(context, 'Visita cancelada com sucesso.');
      }
    } catch (error) {
      if (mounted) {
        await AppFeedback.apiError(
          context,
          error,
          title: 'Erro ao cancelar visita',
          fallback: 'Não foi possível cancelar a visita.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _runningAction = false);
      }
    }
  }

  Future<void> _editVisit(VisitaModel visit) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AgendamentoModal(visit: visit),
    );

    if (changed == true && mounted) {
      await _loadVisits(silent: true);
    }
  }

  Future<void> _openVisit(VisitaModel visit) async {
    if (visit.podeFinalizar) {
      final visitDay = DateUtils.dateOnly(visit.dataVisita);
      final today = DateUtils.dateOnly(DateTime.now());
      if (visitDay.isAfter(today)) {
        final confirmed = await AppFeedback.confirm(
          context,
          title: 'Adiantar visita',
          message:
              'Esta visita está agendada para ${_formatDate(visit.dataVisita)}. '
              'Deseja adiantar essa visita técnica e realizá-la hoje?',
          confirmLabel: 'Adiantar',
        );
        if (!confirmed || !mounted) {
          return;
        }
      }

      final changed = await Navigator.of(context, rootNavigator: true)
          .push<bool>(
            MaterialPageRoute(
              builder: (_) => VisitaTecnicaScreen(visit: visit),
            ),
          );
      if (changed == true && mounted) {
        await _loadVisits(silent: true);
      }
    } else {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => VisitaDetalheModal(visit: visit),
      );
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
          _buildHeader(),
          Expanded(
            child: Stack(
              children: [
                RefreshIndicator(
                  onRefresh: _loadVisits,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      const SizedBox(height: 12),
                      _buildCalendar(),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildInfoCard(),
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: Color(0xFFF0F0F0)),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: _buildVisitsSection(),
                      ),
                    ],
                  ),
                ),
                if (_runningAction)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.08),
                        alignment: Alignment.center,
                        child: const CircularProgressIndicator(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
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
              const Text(
                'Calendário de Visitas',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${_monthName(_focusedDay.month)} ${_focusedDay.year}',
                style: const TextStyle(
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

  static const _months = [
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

  String _monthName(int month) => _months[month - 1];

  Widget _buildCalendar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: TableCalendar<VisitaModel>(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2100, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
        onDaySelected: (selectedDay, focusedDay) {
          final normalized = DateUtils.dateOnly(selectedDay);
          setState(() {
            _selectedDay = normalized;
            _focusedDay = focusedDay;
          });
          CalendarSelectionBus.selectedDate.value = normalized;
        },
        onPageChanged: (focusedDay) {
          setState(() => _focusedDay = focusedDay);
        },
        eventLoader: _eventsForDay,
        calendarFormat: CalendarFormat.month,
        availableCalendarFormats: const {CalendarFormat.month: 'Mes'},
        headerVisible: true,
        headerStyle: const HeaderStyle(
          titleCentered: true,
          formatButtonVisible: false,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          leftChevronIcon: Icon(
            Icons.chevron_left,
            color: Colors.black87,
            size: 20,
          ),
          rightChevronIcon: Icon(
            Icons.chevron_right,
            color: Colors.black87,
            size: 20,
          ),
          headerPadding: EdgeInsets.symmetric(vertical: 12),
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            color: AppColors.textHint,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          weekendStyle: TextStyle(
            color: AppColors.textHint,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        calendarStyle: const CalendarStyle(
          selectedDecoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: Color(0xFFB8E5CE),
            shape: BoxShape.circle,
          ),
          markerDecoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          markerSize: 5,
          outsideDaysVisible: false,
        ),
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, date, events) {
            if (events.isEmpty) {
              return const SizedBox.shrink();
            }

            return Padding(
              padding: const EdgeInsets.only(top: 36),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  events.length.clamp(1, 3),
                  (index) => Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSameDay(date, _selectedDay)
                          ? Colors.white
                          : const Color(0xFF00AE56),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        rowHeight: 52,
        daysOfWeekHeight: 24,
      ),
    );
  }

  Widget _buildInfoCard() {
    if (_loading) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Carregando visitas agendadas...',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
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
            const Text(
              'Não foi possível atualizar o calendário.',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _loadVisits,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    final visitsInMonth = _eventsByDate.entries
        .where(
          (entry) =>
              entry.key.year == _focusedDay.year &&
              entry.key.month == _focusedDay.month,
        )
        .fold<int>(0, (total, entry) => total + entry.value.length);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.event_note_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$visitsInMonth visitas neste mes',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_selectedDayVisits.length} visita(s) em ${_formatDate(_selectedDay)}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitsSection() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null && _selectedDayVisits.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    if (_selectedDayVisits.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            children: const [
              Icon(Icons.event_busy_outlined, color: AppColors.textMuted),
              SizedBox(height: 12),
              Text(
                'Nenhuma visita encontrada para este dia.',
                style: TextStyle(fontSize: 14, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Visitas em ${_formatDate(_selectedDay)}',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        ..._selectedDayVisits.map(_buildVisitCard),
      ],
    );
  }

  Widget _buildVisitCard(VisitaModel visit) {
    final statusColor = _statusColor(visit);
    final urgenciaColor = _urgenciaColor(visit.urgencia);

    return GestureDetector(
      onTap: () => _openVisit(visit),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(16),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 52,
                child: Text(
                  visit.horaCurta,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        visit.propriedadeNome,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        optionLabel(
                          tipoVisitaOptions,
                          visit.tipoVisita,
                          fallback: 'Tipo não informado',
                        ),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildChip(visit.statusLabel, statusColor),
                          _buildChip(
                            optionLabel(urgenciaOptions, visit.urgencia),
                            urgenciaColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (visit.podeCancelar)
                    IconButton(
                      icon: const Icon(
                        Icons.cancel_outlined,
                        size: 20,
                        color: AppColors.textHint,
                      ),
                      onPressed: _runningAction
                          ? null
                          : () => _cancelVisit(visit),
                      visualDensity: VisualDensity.compact,
                    ),
                  if (visit.podeEditar)
                    IconButton(
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: AppColors.primaryLight,
                      ),
                      onPressed: _runningAction
                          ? null
                          : () => _editVisit(visit),
                      visualDensity: VisualDensity.compact,
                    ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(
                      visit.podeFinalizar
                          ? Icons.chevron_right
                          : Icons.lock_outline,
                      color: AppColors.textHint,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
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
}
