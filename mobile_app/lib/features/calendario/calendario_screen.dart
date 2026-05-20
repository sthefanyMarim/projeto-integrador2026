import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/app_colors.dart';
import '../../core/app_screen.dart';
import '../visita/visita_tecnica_screen.dart';

// ---------------------------------------------------------------------------
// Mock data — substituir por chamada de API
// ---------------------------------------------------------------------------

class _Visita {
  const _Visita({
    required this.hora,
    required this.propriedade,
    required this.tipo,
    required this.atrasada,
  });
  final String hora;
  final String propriedade;
  final String tipo;
  final bool atrasada;
}

const _mockVisitas = <int, List<_Visita>>{
  3: [
    _Visita(
      hora: '09:00',
      propriedade: 'Chácara Leme',
      tipo: 'Rotina',
      atrasada: false,
    ),
  ],
  7: [
    _Visita(
      hora: '08:00',
      propriedade: 'Sítio São João',
      tipo: 'Rotina',
      atrasada: true,
    ),
    _Visita(
      hora: '11:00',
      propriedade: 'Fazenda Monte Verde',
      tipo: 'Acompanhamento',
      atrasada: false,
    ),
  ],
  8: [
    _Visita(
      hora: '08:30',
      propriedade: 'Sítio Santa Rosa',
      tipo: 'Rotina',
      atrasada: false,
    ),
    _Visita(
      hora: '10:00',
      propriedade: 'Chácara Esperança',
      tipo: 'Acompanhamento',
      atrasada: true,
    ),
    _Visita(
      hora: '14:00',
      propriedade: 'Fazenda Bela Vista',
      tipo: 'Retorno',
      atrasada: true,
    ),
  ],
  9: [
    _Visita(
      hora: '09:30',
      propriedade: 'Sítio Esperança',
      tipo: 'Rotina',
      atrasada: false,
    ),
  ],
  13: [
    _Visita(
      hora: '08:00',
      propriedade: 'Fazenda Primavera',
      tipo: 'Rotina',
      atrasada: false,
    ),
  ],
  14: [
    _Visita(
      hora: '09:00',
      propriedade: 'Sítio Bom Jesus',
      tipo: 'Retorno',
      atrasada: false,
    ),
    _Visita(
      hora: '14:00',
      propriedade: 'Chácara Verde',
      tipo: 'Rotina',
      atrasada: false,
    ),
  ],
  16: [
    _Visita(
      hora: '10:00',
      propriedade: 'Fazenda Alegre',
      tipo: 'Acompanhamento',
      atrasada: false,
    ),
  ],
  20: [
    _Visita(
      hora: '08:30',
      propriedade: 'Sítio Cachoeira',
      tipo: 'Rotina',
      atrasada: false,
    ),
    _Visita(
      hora: '13:00',
      propriedade: 'Fazenda Nova',
      tipo: 'Retorno',
      atrasada: true,
    ),
  ],
  22: [
    _Visita(
      hora: '09:00',
      propriedade: 'Chácara Santa Fé',
      tipo: 'Rotina',
      atrasada: false,
    ),
  ],
  24: [
    _Visita(
      hora: '08:00',
      propriedade: 'Sítio Boa Vista',
      tipo: 'Rotina',
      atrasada: false,
    ),
    _Visita(
      hora: '11:00',
      propriedade: 'Fazenda Paraíso',
      tipo: 'Acompanhamento',
      atrasada: false,
    ),
  ],
  26: [
    _Visita(
      hora: '09:30',
      propriedade: 'Chácara Bonita',
      tipo: 'Retorno',
      atrasada: false,
    ),
  ],
  29: [
    _Visita(
      hora: '10:00',
      propriedade: 'Fazenda Bela Vista',
      tipo: 'Rotina',
      atrasada: false,
    ),
  ],
};

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class CalendarioScreen extends StatefulWidget {
  const CalendarioScreen({super.key});

  @override
  State<CalendarioScreen> createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends State<CalendarioScreen> {
  static const _meses = [
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

  late final Map<DateTime, List<_Visita>> _eventosPorData;
  late DateTime _mes; // primeiro dia do mês exibido
  late DateTime _diaSelecionado;

  @override
  void initState() {
    super.initState();
    final hoje = DateTime.now();
    _mes = DateTime(hoje.year, hoje.month);
    _diaSelecionado = hoje;
    _eventosPorData = Map.fromEntries(
      _mockVisitas.entries.map(
        (entry) =>
            MapEntry(DateTime(_mes.year, _mes.month, entry.key), entry.value),
      ),
    );
  }

  List<_Visita> _getEventosDoDia(DateTime dia) {
    return _eventosPorData[DateTime(dia.year, dia.month, dia.day)] ?? [];
  }

  List<_Visita> get _visitasDoDia => _getEventosDoDia(_diaSelecionado);

  String get _labelDiaSelecionado {
    return '${_diaSelecionado.day} de ${_meses[_diaSelecionado.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      safeAreaBottom: false,
      appBar: AppBar(title: const Text('Calendário')),
      backgroundColor: Colors.white,
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            _buildCalendar(),
            const SizedBox(height: 8),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            _buildListaVisitas(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ── Calendário ───────────────────────────────────────────────────────────

  Widget _buildCalendar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: TableCalendar<_Visita>(
        firstDay: DateTime.utc(2000, 1, 1),
        lastDay: DateTime.utc(2100, 12, 31),
        focusedDay: _mes,
        selectedDayPredicate: (day) => isSameDay(day, _diaSelecionado),
        onDaySelected: (selectedDay, focusedDay) => setState(() {
          _diaSelecionado = selectedDay;
          _mes = DateTime(focusedDay.year, focusedDay.month);
        }),
        onPageChanged: (focusedDay) => setState(() {
          _mes = DateTime(focusedDay.year, focusedDay.month);
        }),
        eventLoader: _getEventosDoDia,
        calendarFormat: CalendarFormat.month,
        availableCalendarFormats: const {CalendarFormat.month: 'Mês'},
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
            color: Color(0xFF00AE56),
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: Color(0xFFB8E5CE),
            shape: BoxShape.circle,
          ),
          markerDecoration: BoxDecoration(
            color: Color(0xFF00AE56),
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
                  (i) => Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSameDay(date, _diaSelecionado)
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

  // ── Lista de visitas do dia selecionado ──────────────────────────────────

  Widget _buildListaVisitas() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Visitas — $_labelDiaSelecionado',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          if (_visitasDoDia.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  'Nenhuma visita neste dia',
                  style: TextStyle(fontSize: 14, color: AppColors.textMuted),
                ),
              ),
            )
          else
            ...(_visitasDoDia.map((v) => _buildCardVisita(v))),
        ],
      ),
    );
  }

  void _abrirVisita(_Visita visita) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => VisitaTecnicaScreen(
          propriedade: visita.propriedade,
          dataVisita: _diaSelecionado,
          horario: visita.hora,
          tipo: visita.tipo,
        ),
      ),
    );
  }

  Widget _buildCardVisita(_Visita visita) {
    final cor = visita.atrasada
        ? const Color(0xFFE74C3C)
        : const Color(0xFF00AE56);

    return GestureDetector(
      onTap: () => _abrirVisita(visita),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
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
              // Barra lateral colorida
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: cor,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(14),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Hora
              SizedBox(
                width: 44,
                child: Text(
                  visita.hora,
                  style: TextStyle(
                    color: cor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Dados da visita
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        visita.propriedade,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        visita.tipo,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Ações
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.cancel_outlined,
                      size: 20,
                      color: AppColors.textHint,
                    ),
                    onPressed: () {},
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: AppColors.primaryLight,
                    ),
                    onPressed: () {},
                    visualDensity: VisualDensity.compact,
                  ),
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(
                      Icons.chevron_right,
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
}
