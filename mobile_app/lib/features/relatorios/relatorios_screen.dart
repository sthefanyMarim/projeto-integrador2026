import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/api_error.dart';
import '../../core/app_colors.dart';
import '../../core/app_feedback.dart';
import '../../data/models/propriedade_model.dart';
import '../../data/models/relatorio_model.dart';
import '../../data/services/relatorio_service.dart';
import '../../data/services/token_service.dart';

class RelatoriosScreen extends StatefulWidget {
  const RelatoriosScreen({super.key});

  @override
  State<RelatoriosScreen> createState() => _RelatoriosScreenState();
}

class _RelatoriosScreenState extends State<RelatoriosScreen> {
  // ── color maps ──────────────────────────────────────────────────────────────
  static const _statusColors = {
    'AGENDADA': Color(0xFF2196F3),
    'CONCLUIDA': Color(0xFF00AE56),
    'CANCELADA': Color(0xFF9E9E9E),
    'ATRASADA': Color(0xFFFF5722),
  };

  static const _criticidadeColors = {
    'BAIXA': Color(0xFF4CAF50),
    'MEDIA': Color(0xFFFFC107),
    'ALTA': Color(0xFFFF9800),
    'CRITICA': Color(0xFFF44336),
  };

  static const _encStatusColors = {
    'PENDENTE': Color(0xFF2196F3),
    'CONCLUIDO': Color(0xFF00AE56),
    'ATRASADO': Color(0xFFFF5722),
    'CANCELADO': Color(0xFF9E9E9E),
  };

  static const _fallbackColors = [
    Color(0xFF00AE56),
    Color(0xFF2196F3),
    Color(0xFFFF9800),
    Color(0xFF9C27B0),
    Color(0xFFFF5722),
    Color(0xFF607D8B),
  ];

  // ── state ───────────────────────────────────────────────────────────────────
  late final RelatorioService _service;

  final _periodos = RelatorioPeriodo.opcoesPadrao();
  int _periodoIdx = 0;
  DateTime? _customInicio;
  DateTime? _customFim;

  bool _modoGeral = true;
  bool _loading = false;
  bool _exportando = false;
  String? _error;

  RelatorioGeralModel? _dataGeral;
  RelatorioPropriedadeModel? _dataProp;

  List<PropriedadeModel> _propriedades = [];
  PropriedadeModel? _propSelecionada;

  RelatorioPeriodo get _periodoAtual {
    if (_periodoIdx == _periodos.length &&
        _customInicio != null &&
        _customFim != null) {
      return RelatorioPeriodo(
        label: 'Personalizado',
        inicio: _customInicio!,
        fim: _customFim!,
      );
    }
    return _periodos[_periodoIdx.clamp(0, _periodos.length - 1)];
  }

  @override
  void initState() {
    super.initState();
    _service = RelatorioService(TokenService());
    _carregarInicial();
  }

  Future<void> _carregarInicial() async {
    try {
      final props = await _service.listarPropriedades();
      if (!mounted) return;
      setState(() => _propriedades = props);
      await _carregar();
    } catch (e) {
      if (!mounted) return;
      setState(
        () => _error = ApiError.message(e, fallback: 'Erro ao carregar dados.'),
      );
    }
  }

  Future<void> _carregar() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_modoGeral) {
        final data = await _service.buscarGeral(_periodoAtual);
        if (!mounted) return;
        setState(() {
          _dataGeral = data;
          _loading = false;
        });
      } else {
        if (_propSelecionada == null) {
          setState(() => _loading = false);
          return;
        }
        final data = await _service.buscarPropriedade(
          _propSelecionada!.id,
          _periodoAtual,
        );
        if (!mounted) return;
        setState(() {
          _dataProp = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = ApiError.message(e, fallback: 'Erro ao gerar relatorio.');
      });
    }
  }

  Future<void> _exportar() async {
    setState(() => _exportando = true);
    try {
      if (_modoGeral) {
        await _service.exportarGeralPdf(_periodoAtual);
      } else {
        if (_propSelecionada == null) return;
        await _service.exportarPropriedadePdf(
          _propSelecionada!.id,
          _periodoAtual,
        );
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.error(
          context,
          message: 'Nao foi possivel exportar o relatorio.',
        );
      }
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  Future<void> _selecionarPeriodoCustom() async {
    final hoje = DateUtils.dateOnly(DateTime.now());
    final inicio = await showDatePicker(
      context: context,
      initialDate: hoje.subtract(const Duration(days: 30)),
      firstDate: DateTime(2020),
      lastDate: hoje,
      helpText: 'Data inicial',
      builder: _datePickerTheme,
    );
    if (inicio == null || !mounted) return;
    final fim = await showDatePicker(
      context: context,
      initialDate: hoje,
      firstDate: inicio,
      lastDate: hoje,
      helpText: 'Data final',
      builder: _datePickerTheme,
    );
    if (fim == null || !mounted) return;
    setState(() {
      _customInicio = inicio;
      _customFim = fim;
      _periodoIdx = _periodos.length;
    });
    _carregar();
  }

  Widget _datePickerTheme(BuildContext ctx, Widget? child) => Theme(
    data: Theme.of(ctx).copyWith(
      colorScheme: ColorScheme.fromSwatch().copyWith(
        primary: AppColors.primary,
        onPrimary: Colors.white,
      ),
    ),
    child: child!,
  );

  // ── build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _carregar,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  _buildToggle(),
                  const SizedBox(height: 12),
                  _buildPeriodoBar(),
                  const SizedBox(height: 12),
                  if (!_modoGeral) _buildPropSelector(),
                  if (!_modoGeral) const SizedBox(height: 12),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.only(top: 60),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_error != null)
                    _buildErro()
                  else if (_modoGeral && _dataGeral != null)
                    _buildGeralContent(_dataGeral!)
                  else if (!_modoGeral && _dataProp != null)
                    _buildPropContent(_dataProp!)
                  else if (!_modoGeral && _propSelecionada == null)
                    _buildInfoCard(
                      'Selecione uma propriedade para gerar o relatorio.',
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── header / controles ───────────────────────────────────────────────────────

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
          child: Row(
            children: [
              if (Navigator.canPop(context))
                InkWell(
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
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Relatórios',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Indicadores e históricos',
                      style: TextStyle(
                        color: Color(0xCCFFFFFF),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (!_loading)
                IconButton(
                  onPressed: _exportando ? null : _exportar,
                  icon: _exportando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.picture_as_pdf_outlined,
                          color: Colors.white,
                        ),
                  tooltip: 'Exportar PDF',
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(child: _toggleBtn('Geral', true)),
          Expanded(child: _toggleBtn('Por Propriedade', false)),
        ],
      ),
    );
  }

  Widget _toggleBtn(String label, bool isGeral) {
    final selected = _modoGeral == isGeral;
    return GestureDetector(
      onTap: () {
        if (_modoGeral == isGeral) return;
        setState(() {
          _modoGeral = isGeral;
          _error = null;
        });
        _carregar();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodoBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ..._periodos.asMap().entries.map(
            (e) => _periodoChip(e.value.label, e.key),
          ),
          _periodoChip(
            'Personalizado',
            _periodos.length,
            onTap: _selecionarPeriodoCustom,
          ),
        ],
      ),
    );
  }

  Widget _periodoChip(String label, int idx, {VoidCallback? onTap}) {
    final selected = _periodoIdx == idx;
    return GestureDetector(
      onTap:
          onTap ??
          () {
            if (_periodoIdx == idx) return;
            setState(() => _periodoIdx = idx);
            _carregar();
          },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.transparent : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildPropSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<PropriedadeModel>(
          value: _propSelecionada,
          hint: const Text(
            'Selecione a propriedade',
            style: TextStyle(color: AppColors.textMuted),
          ),
          isExpanded: true,
          items: _propriedades
              .map(
                (p) => DropdownMenuItem(
                  value: p,
                  child: Text(
                    p.nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: (p) {
            setState(() {
              _propSelecionada = p;
              _dataProp = null;
            });
            if (p != null) _carregar();
          },
        ),
      ),
    );
  }

  // ── conteúdo geral ───────────────────────────────────────────────────────────

  Widget _buildGeralContent(RelatorioGeralModel data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle('Visitas'),
        _summaryCard(data.totalVisitas, 'visitas no período'),
        _donutChart(data.visitasPorStatus, _statusColors,
            title: 'Por status'),
        _barChart(data.visitasPorTipo, const Color(0xFF3F51B5),
            title: 'Por tipo'),
        _sectionTitle('Diagnósticos'),
        _summaryCard(data.totalDiagnosticos, 'diagnósticos no período'),
        _barChart(data.diagnosticosPorCategoria, const Color(0xFF7B1FA2),
            title: 'Por categoria'),
        _donutChart(data.diagnosticosPorCriticidade, _criticidadeColors,
            title: 'Por criticidade'),
        _sectionTitle('Encaminhamentos'),
        _summaryCard(data.totalEncaminhamentos, 'encaminhamentos no período'),
        _donutChart(data.encaminhamentosPorStatus, _encStatusColors,
            title: 'Por status'),
        if (data.encaminhadosComPrazo > 0)
          _completionCard(
            data.encaminhadosConcluidosNoPrazo,
            data.encaminhadosComPrazo,
          ),
        _sectionTitle('Rankings'),
        _rankingBars(
          'Top propriedades visitadas',
          data.topPropriedadesVisitadas,
          'visitas',
        ),
        _rankingBars(
          'Top propriedades — diagnósticos críticos',
          data.topPropriedadesDiagnosticos,
          'diagnósticos',
        ),
        _rankingBars(
          'Visitas concluídas por técnico',
          data.visitasPorTecnico,
          'concluídas',
        ),
      ],
    );
  }

  // ── conteúdo por propriedade ─────────────────────────────────────────────────

  Widget _buildPropContent(RelatorioPropriedadeModel data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _infoCard(data),
        _sectionTitle('Visitas (${data.totalVisitas})'),
        _donutChart(data.visitasPorStatus, _statusColors, title: 'Por status'),
        _barChart(data.visitasPorTipo, const Color(0xFF3F51B5),
            title: 'Por tipo'),
        if (data.visitas.isNotEmpty) _visitasLista(data.visitas),
        _sectionTitle('Diagnósticos (${data.totalDiagnosticos})'),
        _barChart(data.diagnosticosPorCategoria, const Color(0xFF7B1FA2),
            title: 'Por categoria'),
        _donutChart(data.diagnosticosPorCriticidade, _criticidadeColors,
            title: 'Por criticidade'),
        if (data.diagnosticos.isNotEmpty) _diagnosticosLista(data.diagnosticos),
        _sectionTitle('Encaminhamentos (${data.totalEncaminhamentos})'),
        _donutChart(data.encaminhamentosPorStatus, _encStatusColors,
            title: 'Por status'),
        if (data.encaminhamentos.isNotEmpty)
          _encaminhamentosLista(data.encaminhamentos),
      ],
    );
  }

  // ── widgets de gráfico ───────────────────────────────────────────────────────

  Widget _donutChart(
    Map<String, int> data,
    Map<String, Color> colorMap, {
    required String title,
  }) {
    if (data.isEmpty) return const SizedBox.shrink();
    final total = data.values.fold(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();

    final entries = data.entries.toList();

    Color colorFor(int i, String key) =>
        colorMap[key] ?? _fallbackColors[i % _fallbackColors.length];

    return _card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: PieChart(
              PieChartData(
                sections: entries.asMap().entries.map((e) {
                  final color = colorFor(e.key, e.value.key);
                  final pct = (e.value.value / total * 100).round();
                  return PieChartSectionData(
                    value: e.value.value.toDouble(),
                    color: color,
                    title: pct >= 5 ? '$pct%' : '',
                    showTitle: true,
                    titleStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    radius: 55,
                  );
                }).toList(),
                centerSpaceRadius: 36,
                sectionsSpace: 2,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: entries.asMap().entries.map((e) {
              final color = colorFor(e.key, e.value.key);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_humanize(e.value.key)}  ${e.value.value}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _barChart(
    Map<String, int> data,
    Color barColor, {
    required String title,
  }) {
    if (data.isEmpty) return const SizedBox.shrink();
    final maxVal = data.values.fold(0, (a, b) => a > b ? a : b);

    return _card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          ...data.entries.map((e) {
            final fraction = maxVal > 0 ? e.value / maxVal : 0.0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 96,
                    child: Text(
                      _humanize(e.key),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: fraction.toDouble(),
                        backgroundColor: barColor.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation(barColor),
                        minHeight: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 28,
                    child: Text(
                      '${e.value}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _rankingBars(
    String title,
    List<RankingItem> items,
    String colLabel,
  ) {
    if (items.isEmpty) return const SizedBox.shrink();
    final maxVal =
        items.map((e) => e.total).fold(0, (a, b) => a > b ? a : b);

    return _card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          ...items.asMap().entries.map((e) {
            final fraction =
                maxVal > 0 ? e.value.total / maxVal : 0.0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 18,
                    child: Text(
                      '${e.key + 1}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 82,
                    child: Text(
                      e.value.nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: fraction,
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.1,
                        ),
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.primary,
                        ),
                        minHeight: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${e.value.total}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _completionCard(int concluidos, int total) {
    final pct = total > 0 ? concluidos / total : 0.0;
    return _card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Encaminhamentos concluídos no prazo',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: AppColors.success.withValues(alpha: 0.12),
                    valueColor: const AlwaysStoppedAnimation(AppColors.success),
                    minHeight: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$concluidos/$total  (${(pct * 100).round()}%)',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(int value, String label) {
    return _card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ── listas detalhadas (relatório por propriedade) ───────────────────────────

  Widget _visitasLista(List<VisitaItemModel> visitas) {
    return _card(
      margin: const EdgeInsets.only(top: 4, bottom: 8),
      padding: EdgeInsets.zero,
      child: Column(
        children: visitas.map((v) {
          final d =
              '${v.data.day.toString().padLeft(2, '0')}/${v.data.month.toString().padLeft(2, '0')}/${v.data.year}';
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$d  ${v.hora.length >= 5 ? v.hora.substring(0, 5) : v.hora}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      Text(
                        v.tecnico,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (v.tipo != null)
                        Text(
                          _humanize(v.tipo!),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                _statusChip(v.status),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _diagnosticosLista(List<DiagnosticoItemModel> diags) {
    return _card(
      margin: const EdgeInsets.only(top: 4, bottom: 8),
      padding: EdgeInsets.zero,
      child: Column(
        children: diags
            .map(
              (d) => Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d.categoria,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (d.observacoes != null)
                            Text(
                              d.observacoes!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _criticidadeChip(d.criticidade),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _encaminhamentosLista(List<EncaminhamentoItemModel> encs) {
    return _card(
      margin: const EdgeInsets.only(top: 4, bottom: 8),
      padding: EdgeInsets.zero,
      child: Column(
        children: encs
            .map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.acaoRealizada,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (e.responsavel != null)
                            Text(
                              'Resp: ${e.responsavel}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          if (e.prazo != null)
                            Text(
                              'Prazo: ${e.prazo!.day.toString().padLeft(2, '0')}/${e.prazo!.month.toString().padLeft(2, '0')}/${e.prazo!.year}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _statusChip(e.status),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  // ── primitivos visuais ───────────────────────────────────────────────────────

  Widget _card({
    required Widget child,
    EdgeInsets? margin,
    EdgeInsets? padding,
  }) {
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 12),
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _infoCard(RelatorioPropriedadeModel data) {
    return _card(
      child: Column(
        children: [
          _infoRow('Proprietário', data.nomeProprietario),
          _infoRow('Município', data.municipio),
          if (data.tipoProducao != null)
            _infoRow('Tipo de produção', data.tipoProducao!),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    final color = switch (status) {
      'CONCLUIDA' || 'CONCLUIDO' => AppColors.success,
      'CANCELADA' || 'CANCELADO' => AppColors.textMuted,
      'ATRASADA' || 'ATRASADO' => AppColors.error,
      _ => AppColors.warning,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _humanize(status),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _criticidadeChip(String criticidade) {
    final color = switch (criticidade) {
      'CRITICA' || 'ALTA' => AppColors.error,
      'MEDIA' => AppColors.warning,
      _ => AppColors.success,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _humanize(criticidade),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildErro() => _card(
    child: Column(
      children: [
        const Icon(Icons.error_outline, color: AppColors.error),
        const SizedBox(height: 12),
        Text(
          _error!,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: _carregar,
          child: const Text('Tentar novamente'),
        ),
      ],
    ),
  );

  Widget _buildInfoCard(String msg) => _card(
    child: Text(
      msg,
      textAlign: TextAlign.center,
      style: const TextStyle(color: AppColors.textSecondary),
    ),
  );

  String _humanize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() +
        value.substring(1).toLowerCase().replaceAll('_', ' ');
  }
}
