import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_colors.dart';
import '../../core/app_feedback.dart';
import '../../core/app_refresh_bus.dart';
import '../../data/models/visita_model.dart';
import '../../data/services/token_service.dart';
import '../../data/services/visita_service.dart';
import 'visita_form_options.dart';

class _DiagnosticoDraft {
  const _DiagnosticoDraft({
    required this.categoria,
    required this.criticidade,
    required this.observacoes,
    this.imagePath,
  });

  final String categoria;
  final String criticidade;
  final String observacoes;
  final String? imagePath;
}

class _EncaminhamentoDraft {
  const _EncaminhamentoDraft({
    required this.acao,
    required this.prioridade,
    required this.verificacao,
    this.responsavel,
    this.prazo,
  });

  final String acao;
  final String prioridade;
  final String verificacao;
  final String? responsavel;
  final DateTime? prazo;
}

class _PendingReturnVisit {
  const _PendingReturnVisit({
    required this.data,
    required this.hora,
    required this.urgencia,
  });

  final DateTime data;
  final TimeOfDay hora;
  final String urgencia;
}

class VisitaTecnicaScreen extends StatefulWidget {
  const VisitaTecnicaScreen({super.key, required this.visit});

  final VisitaModel visit;

  @override
  State<VisitaTecnicaScreen> createState() => _VisitaTecnicaScreenState();
}

class _VisitaTecnicaScreenState extends State<VisitaTecnicaScreen> {
  static const double _dropdownMenuMaxHeight = 280;

  final _pageController = PageController();
  final _observacoesGeraisController = TextEditingController();
  final _diagnosticoFormKey = GlobalKey<FormState>();
  final _encaminhamentoFormKey = GlobalKey<FormState>();
  final _diagnosticoObservacoesController = TextEditingController();
  final _encaminhamentoAcaoController = TextEditingController();

  late final VisitaService _service;

  int _step = 0;
  bool _saving = false;

  String? _diagnosticoCategoria;
  String _diagnosticoCriticidade = criticidadeOptions[1].value;
  XFile? _diagnosticoImagem;
  String _encaminhamentoPrioridade = prioridadeOptions[1].value;
  String _encaminhamentoVerificacao = verificacaoOptions[0].value;
  String? _encaminhamentoResponsavel;
  DateTime? _encaminhamentoPrazo;

  final List<_DiagnosticoDraft> _diagnosticos = [];
  final List<_EncaminhamentoDraft> _encaminhamentos = [];
  _PendingReturnVisit? _pendingReturnVisit;

  @override
  void initState() {
    super.initState();
    _service = VisitaService(TokenService());
  }

  @override
  void dispose() {
    _pageController.dispose();
    _observacoesGeraisController.dispose();
    _diagnosticoObservacoesController.dispose();
    _encaminhamentoAcaoController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }

  bool _validateCurrentStep() {
    switch (_step) {
      case 1:
        if (_diagnosticos.isEmpty) {
          AppFeedback.warning(
            context,
            'Adicione pelo menos um diagnóstico.',
          );
          return false;
        }
        return true;
      case 2:
        if (_encaminhamentos.isEmpty) {
          AppFeedback.warning(
            context,
            'Adicione pelo menos um encaminhamento.',
          );
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _goTo(int step) {
    setState(() => _step = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _next() {
    if (_validateCurrentStep()) {
      _goTo(_step + 1);
    }
  }

  void _previous() {
    if (_step > 0) {
      _goTo(_step - 1);
    }
  }

  void _addDiagnostico() {
    if (!(_diagnosticoFormKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_diagnosticoCategoria == null) {
      return;
    }

    setState(() {
      _diagnosticos.add(
        _DiagnosticoDraft(
          categoria: _diagnosticoCategoria!,
          criticidade: _diagnosticoCriticidade,
          observacoes: _diagnosticoObservacoesController.text.trim(),
          imagePath: _diagnosticoImagem?.path,
        ),
      );
      _diagnosticoCategoria = null;
      _diagnosticoCriticidade = criticidadeOptions[1].value;
      _diagnosticoObservacoesController.clear();
      _diagnosticoImagem = null;
    });
  }

  Future<void> _pickDiagnosticoImagem(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1280,
    );
    if (picked != null && mounted) {
      setState(() => _diagnosticoImagem = picked);
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.grey200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Adicionar foto',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                title: const Text('Tirar foto'),
                subtitle: const Text('Usar a câmera do dispositivo'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickDiagnosticoImagem(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.infoSurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.photo_library_outlined,
                    color: AppColors.info,
                    size: 20,
                  ),
                ),
                title: const Text('Escolher da galeria'),
                subtitle: const Text('Selecionar uma imagem existente'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickDiagnosticoImagem(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _removeDiagnostico(int index) {
    setState(() => _diagnosticos.removeAt(index));
  }

  void _resetEncaminhamentoForm() {
    _encaminhamentoAcaoController.clear();
    _encaminhamentoResponsavel = null;
    _encaminhamentoPrazo = null;
    _encaminhamentoPrioridade = prioridadeOptions[1].value;
    _encaminhamentoVerificacao = verificacaoOptions[0].value;
  }

  Future<void> _addEncaminhamento() async {
    if (!(_encaminhamentoFormKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_encaminhamentoVerificacao != 'VISITA' && _encaminhamentoPrazo == null) {
      AppFeedback.warning(
        context,
        'Informe um prazo para encaminhamentos de verificação por ${_encaminhamentoVerificacao.toLowerCase()}.',
      );
      return;
    }

    final draft = _EncaminhamentoDraft(
      acao: _encaminhamentoAcaoController.text.trim(),
      prioridade: _encaminhamentoPrioridade,
      verificacao: _encaminhamentoVerificacao,
      responsavel: _encaminhamentoResponsavel,
      prazo: _encaminhamentoPrazo,
    );

    if (_encaminhamentoVerificacao == 'VISITA') {
      await _showRetornoModal(draft);
      return;
    }

    setState(() {
      _encaminhamentos.add(draft);
      _resetEncaminhamentoForm();
    });
  }

  Future<void> _showRetornoModal(_EncaminhamentoDraft draft) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _RetornoVisitaDialog(
        propriedadeNome: widget.visit.propriedadeNome,
        onAgendarDepois: () {
          setState(() {
            _encaminhamentos.add(draft);
            _encaminhamentos.add(_EncaminhamentoDraft(
              acao:
                  'Agendar visita de retorno — ${widget.visit.propriedadeNome}',
              prioridade: draft.prioridade,
              verificacao: 'VISITA',
              responsavel: 'Tecnico',
            ));
            _resetEncaminhamentoForm();
          });
          Navigator.of(ctx).pop();
        },
        onConcluirAgendamento: (data, hora, urgencia) {
          setState(() {
            _encaminhamentos.add(draft);
            _pendingReturnVisit = _PendingReturnVisit(
              data: data,
              hora: hora,
              urgencia: urgencia,
            );
            _resetEncaminhamentoForm();
          });
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  void _removeEncaminhamento(int index) {
    setState(() => _encaminhamentos.removeAt(index));
  }

  Future<void> _selectPrazo() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _encaminhamentoPrazo ?? today.add(const Duration(days: 7)),
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSwatch().copyWith(
              primary: AppColors.primary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() => _encaminhamentoPrazo = picked);
    }
  }

  Future<void> _finishVisit() async {
    if (!_validateCurrentStep()) {
      return;
    }

    setState(() => _saving = true);

    try {
      final request = FinalizarVisitaRequest(
        diagnosticos: List.generate(
          _diagnosticos.length,
          (i) => DiagnosticoPayload(
            categoria: _diagnosticos[i].categoria,
            criticidade: _diagnosticos[i].criticidade,
            observacoes: _diagnosticos[i].observacoes,
            imagePath: _diagnosticos[i].imagePath,
          ),
        ),
        encaminhamentos: _encaminhamentos
            .map(
              (item) => EncaminhamentoPayload(
                acaoRealizada: item.acao,
                responsavel: item.responsavel,
                prazo: item.prazo,
                verificacao: item.verificacao,
                prioridade: item.prioridade,
              ),
            )
            .toList(),
        observacoesGerais: _observacoesGeraisController.text.trim().isEmpty
            ? null
            : _observacoesGeraisController.text.trim(),
      );

      await _service.finalizar(widget.visit.id, request);

      if (_pendingReturnVisit != null) {
        final ret = _pendingReturnVisit!;
        final h = ret.hora.hour.toString().padLeft(2, '0');
        final m = ret.hora.minute.toString().padLeft(2, '0');
        await _service.criar(SalvarVisitaRequest(
          propriedadeId: widget.visit.propriedadeId,
          dataVisita: ret.data,
          horaVisita: '$h:$m:00',
          tipoVisita: 'RETORNO',
          urgencia: ret.urgencia,
        ));
      }

      if (!mounted) {
        return;
      }

      AppRefreshBus.notifyChanged();
      AppFeedback.success(context, 'Visita finalizada com sucesso.');
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      await AppFeedback.apiError(
        context,
        error,
        title: 'Erro ao finalizar visita',
        fallback: 'Não foi possível finalizar a visita.',
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildResumoStep(),
                _buildDiagnosticosStep(),
                _buildEncaminhamentosStep(),
              ],
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _saving ? null : () => Navigator.of(context).pop(),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Realizar Visita',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildStepIndicator(),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    const labels = ['Resumo', 'Diagnosticos', 'Encaminhamentos'];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int index = 0; index < labels.length; index++) ...[
          _buildStepCircle(index, labels[index]),
          if (index < labels.length - 1)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 13),
                child: Container(
                  height: 2,
                  color: _step > index
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.35),
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildStepCircle(int index, String label) {
    final isActive = index == _step;
    final isCompleted = index < _step;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive || isCompleted
                ? Colors.white
                : Colors.white.withValues(alpha: 0.3),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, size: 14, color: AppColors.primary)
                : Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isActive
                          ? AppColors.primary
                          : Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: isActive || isCompleted
                ? Colors.white
                : Colors.white.withValues(alpha: 0.5),
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      child: Row(
        children: [
          if (_step > 0) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: _saving ? null : _previous,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.grey200),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Anterior',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: ElevatedButton(
              onPressed: _saving
                  ? null
                  : _step == 2
                  ? _finishVisit
                  : _next,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.grey200,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _saving
                    ? 'Salvando...'
                    : _step == 2
                    ? 'Finalizar'
                    : 'Proximo',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumoStep() {
    final visit = widget.visit;
    final tipo = optionLabel(
      tipoVisitaOptions,
      visit.tipoVisita,
      fallback: 'Nao informado',
    );
    final urgencia = optionLabel(
      urgenciaOptions,
      visit.urgencia,
      fallback: 'Nao informada',
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0F000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dados da visita',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),
                _label('Propriedade Rural'),
                _readonlyField(visit.propriedadeNome),
                const SizedBox(height: 12),
                _label('Tecnico responsavel'),
                _readonlyField(visit.usuarioNome),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Data'),
                          _readonlyField(_formatDate(visit.dataVisita)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Horario'),
                          _readonlyField(visit.horaCurta),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildStatusChip(tipo, AppColors.primary),
                    _buildStatusChip(urgencia, _urgenciaColor(visit.urgencia)),
                    _buildStatusChip(
                      visit.statusLabel,
                      _statusColor(visit.statusVisita),
                    ),
                  ],
                ),
                if (visit.temaPrincipal != null &&
                    visit.temaPrincipal!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _label('Tema principal'),
                  _readonlyField(visit.temaPrincipal!),
                ],
                if (visit.observacoes != null &&
                    visit.observacoes!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _label('Observacoes do agendamento'),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.grey50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      visit.observacoes!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0F000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('Observacoes gerais'),
                TextFormField(
                  controller: _observacoesGeraisController,
                  maxLines: 4,
                  decoration: _inputDecoration(
                    'Descreva observacoes finais, orientacoes e contexto da visita.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDiagnosticosStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Diagnosticos da visita',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Adicione os diagnosticos identificados durante a visita.',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0F000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Form(
              key: _diagnosticoFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _label('Categoria *'),
                  DropdownButtonFormField<String>(
                    initialValue: _diagnosticoCategoria,
                    isExpanded: true,
                    menuMaxHeight: _dropdownMenuMaxHeight,
                    validator: (value) =>
                        value == null ? 'Selecione uma categoria.' : null,
                    onChanged: (value) =>
                        setState(() => _diagnosticoCategoria = value),
                    decoration: _dropdownDecoration(),
                    hint: const Text(
                      'Selecione a categoria',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                    items: diagnosticoCategorias
                        .map(
                          (item) => DropdownMenuItem<String>(
                            value: item,
                            child: Text(
                              item,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 14),
                  _label('Criticidade'),
                  const SizedBox(height: 8),
                  _buildOptionSelector(
                    value: _diagnosticoCriticidade,
                    options: criticidadeOptions,
                    colorForValue: _criticidadeColor,
                    backgroundForValue: _criticidadeBackground,
                    onChanged: (value) {
                      setState(() => _diagnosticoCriticidade = value);
                    },
                  ),
                  const SizedBox(height: 14),
                  _label('Observacoes'),
                  TextFormField(
                    controller: _diagnosticoObservacoesController,
                    maxLines: 3,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Descreva o diagnostico.'
                        : null,
                    decoration: _inputDecoration(
                      'Descreva o que foi observado na visita.',
                    ),
                  ),
                  const SizedBox(height: 14),
                  _label('Foto (opcional)'),
                  _buildImagePicker(),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 46,
                    child: OutlinedButton.icon(
                      onPressed: _addDiagnostico,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text(
                        'Adicionar Diagnostico',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_diagnosticos.isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                const Text(
                  'Diagnosticos adicionados',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 8),
                _countBadge(_diagnosticos.length),
              ],
            ),
            const SizedBox(height: 10),
            ...List.generate(_diagnosticos.length, _buildDiagnosticoCard),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDiagnosticoCard(int index) {
    final item = _diagnosticos[index];
    final color = _criticidadeColor(item.criticidade);
    final background = _criticidadeBackground(item.criticidade);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(12),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.categoria,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: background,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            optionLabel(criticidadeOptions, item.criticidade),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.observacoes,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (item.imagePath != null) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(item.imagePath!),
                          height: 100,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              color: AppColors.grey400,
              onPressed: () => _removeDiagnostico(index),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEncaminhamentosStep() {
    final prazoLabel = _encaminhamentoPrazo == null
        ? 'dd/mm/aaaa'
        : _formatDate(_encaminhamentoPrazo!);
    final bool prazoObrigatorio = _encaminhamentoVerificacao != 'VISITA';
    final bool prazoAusenteVisita =
        _encaminhamentoVerificacao == 'VISITA' && _encaminhamentoPrazo == null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Encaminhamentos',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Registre as acoes que precisam de acompanhamento.',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0F000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Form(
              key: _encaminhamentoFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _label('Acao de encaminhamento *'),
                  TextFormField(
                    controller: _encaminhamentoAcaoController,
                    maxLines: 3,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Descreva a acao.'
                        : null,
                    decoration: _inputDecoration(
                      'Ex.: solicitar analise, agendar retorno, orientar correcao.',
                    ),
                  ),
                  const SizedBox(height: 14),
                  _label('Responsavel'),
                  DropdownButtonFormField<String>(
                    initialValue: _encaminhamentoResponsavel,
                    isExpanded: true,
                    menuMaxHeight: _dropdownMenuMaxHeight,
                    onChanged: (value) =>
                        setState(() => _encaminhamentoResponsavel = value),
                    decoration: _dropdownDecoration(),
                    hint: const Text(
                      'Selecione o responsavel',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                    items: responsavelOptions
                        .map(
                          (option) => DropdownMenuItem<String>(
                            value: option.value,
                            child: Text(
                              option.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 14),
                  _label(prazoObrigatorio ? 'Prazo *' : 'Prazo'),
                  if (prazoAusenteVisita)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: const [
                          Icon(
                            Icons.warning_amber_outlined,
                            size: 13,
                            color: AppColors.error,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Sem prazo: será marcado como Crítico',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  GestureDetector(
                    onTap: _selectPrazo,
                    child: Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.fieldBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: (prazoObrigatorio && _encaminhamentoPrazo == null)
                              ? AppColors.error
                              : AppColors.border,
                          width: (prazoObrigatorio && _encaminhamentoPrazo == null) ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              prazoLabel,
                              style: TextStyle(
                                fontSize: 15,
                                color: _encaminhamentoPrazo == null
                                    ? AppColors.textMuted
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 18,
                            color: (prazoObrigatorio && _encaminhamentoPrazo == null)
                                ? AppColors.error
                                : AppColors.grey400,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _label('Forma de verificacao'),
                  DropdownButtonFormField<String>(
                    initialValue: _encaminhamentoVerificacao,
                    isExpanded: true,
                    menuMaxHeight: _dropdownMenuMaxHeight,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _encaminhamentoVerificacao = value);
                      }
                    },
                    decoration: _dropdownDecoration(),
                    items: verificacaoOptions
                        .map(
                          (option) => DropdownMenuItem<String>(
                            value: option.value,
                            child: Text(
                              option.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 14),
                  _label('Prioridade'),
                  const SizedBox(height: 8),
                  _buildOptionSelector(
                    value: _encaminhamentoPrioridade,
                    options: prioridadeOptions,
                    colorForValue: _prioridadeColor,
                    backgroundForValue: _prioridadeBackground,
                    onChanged: (value) {
                      setState(() => _encaminhamentoPrioridade = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 46,
                    child: OutlinedButton.icon(
                      onPressed: _addEncaminhamento,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text(
                        'Adicionar Encaminhamento',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_encaminhamentos.isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                const Text(
                  'Encaminhamentos adicionados',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 8),
                _countBadge(_encaminhamentos.length),
              ],
            ),
            const SizedBox(height: 10),
            ...List.generate(_encaminhamentos.length, _buildEncaminhamentoCard),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildEncaminhamentoCard(int index) {
    final item = _encaminhamentos[index];
    final bool semPrazoVisita =
        item.prazo == null && item.verificacao == 'VISITA';
    final color = semPrazoVisita
        ? AppColors.error
        : _prioridadeColor(item.prioridade);
    final background = semPrazoVisita
        ? AppColors.errorSurface
        : _prioridadeBackground(item.prioridade);
    final prazo = item.prazo == null
        ? (semPrazoVisita ? 'Sem prazo — Crítico' : 'Sem prazo')
        : _formatDate(item.prazo!);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(12),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.acao,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: background,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            optionLabel(prioridadeOptions, item.prioridade),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline,
                          size: 13,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.responsavel ?? 'Responsavel nao informado',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 12,
                          color: semPrazoVisita
                              ? AppColors.error
                              : AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          prazo,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: semPrazoVisita
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: semPrazoVisita
                                ? AppColors.error
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.fact_check_outlined,
                          size: 12,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          optionLabel(verificacaoOptions, item.verificacao),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              color: AppColors.grey400,
              onPressed: () => _removeEncaminhamento(index),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    if (_diagnosticoImagem != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(_diagnosticoImagem!.path),
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => setState(() => _diagnosticoImagem = null),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 18),
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: GestureDetector(
              onTap: _showImageSourceSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Trocar',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: _showImageSourceSheet,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.fieldBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, style: BorderStyle.solid),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_a_photo_outlined,
              color: AppColors.textMuted,
              size: 22,
            ),
            SizedBox(width: 10),
            Text(
              'Adicionar foto',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionSelector({
    required String value,
    required List<FormOption> options,
    required Color Function(String) colorForValue,
    required Color Function(String) backgroundForValue,
    required ValueChanged<String> onChanged,
  }) {
    return Row(
      children: List.generate(options.length, (index) {
        final option = options[index];
        final isSelected = option.value == value;
        final color = colorForValue(option.value);
        final background = backgroundForValue(option.value);

        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(option.value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: EdgeInsets.only(
                right: index == options.length - 1 ? 0 : 8,
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? background : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? color : const Color(0xFFDDDDDD),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Center(
                child: Text(
                  option.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected
                        ? FontWeight.w700
                        : FontWeight.normal,
                    color: isSelected ? color : AppColors.textMuted,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
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

  Widget _countBadge(int value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$value',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    return switch (status) {
      'CONCLUIDA' => AppColors.success,
      'CANCELADA' => AppColors.textMuted,
      'ATRASADA' => AppColors.error,
      _ => AppColors.primary,
    };
  }

  Color _urgenciaColor(String urgencia) {
    return switch (urgencia) {
      'CRITICA' => AppColors.error,
      'ALTA' => AppColors.warning,
      'MEDIA' => AppColors.info,
      _ => AppColors.success,
    };
  }

  Color _criticidadeColor(String value) {
    return switch (value) {
      'CRITICA' => AppColors.error,
      'ALTA' => AppColors.warning,
      'MEDIA' => AppColors.info,
      _ => AppColors.success,
    };
  }

  Color _criticidadeBackground(String value) {
    return switch (value) {
      'CRITICA' => AppColors.errorSurface,
      'ALTA' => AppColors.warningSurface,
      'MEDIA' => AppColors.infoSurface,
      _ => AppColors.successSurface,
    };
  }

  Color _prioridadeColor(String value) {
    return switch (value) {
      'CRITICA' => AppColors.error,
      'ALTA' => AppColors.warning,
      'MEDIA' => AppColors.info,
      _ => AppColors.success,
    };
  }

  Color _prioridadeBackground(String value) {
    return switch (value) {
      'CRITICA' => AppColors.errorSurface,
      'ALTA' => AppColors.warningSurface,
      'MEDIA' => AppColors.infoSurface,
      _ => AppColors.successSurface,
    };
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _readonlyField(String value) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          value,
          style: const TextStyle(fontSize: 15, color: AppColors.textSecondary),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
      filled: true,
      fillColor: AppColors.fieldBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
    );
  }

  InputDecoration _dropdownDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: AppColors.fieldBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }
}

class _RetornoVisitaDialog extends StatefulWidget {
  const _RetornoVisitaDialog({
    required this.propriedadeNome,
    required this.onAgendarDepois,
    required this.onConcluirAgendamento,
  });

  final String propriedadeNome;
  final VoidCallback onAgendarDepois;
  final void Function(DateTime data, TimeOfDay hora, String urgencia)
  onConcluirAgendamento;

  @override
  State<_RetornoVisitaDialog> createState() => _RetornoVisitaDialogState();
}

class _RetornoVisitaDialogState extends State<_RetornoVisitaDialog> {
  bool _agendando = false;
  DateTime? _data;
  TimeOfDay? _hora;
  String _urgencia = urgenciaOptions[0].value;

  String _formatDate(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    return '$day/$month/${d.year}';
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _data ?? today.add(const Duration(days: 1)),
      firstDate: today.add(const Duration(days: 1)),
      lastDate: today.add(const Duration(days: 730)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.fromSwatch().copyWith(
            primary: AppColors.primary,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) setState(() => _data = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _hora ?? const TimeOfDay(hour: 8, minute: 0),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          timePickerTheme: TimePickerThemeData(
            dialHandColor: AppColors.primary,
            dialBackgroundColor: AppColors.primarySurface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) setState(() => _hora = picked);
  }

  void _confirmarAgendamento() {
    if (_data == null || _hora == null) {
      return;
    }
    widget.onConcluirAgendamento(_data!, _hora!, _urgencia);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Verificação por nova visita',
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Este encaminhamento requer uma nova visita a ${widget.propriedadeNome}. Deseja agendá-la agora?',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            if (!_agendando) ...[
              OutlinedButton(
                onPressed: widget.onAgendarDepois,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Agendar depois',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => setState(() => _agendando = true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Concluir agendamento'),
              ),
            ] else ...[
              const Text(
                'Data da visita *',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              _PickerField(
                label: _data == null ? 'dd/mm/aaaa' : _formatDate(_data!),
                icon: Icons.calendar_today_outlined,
                onTap: _pickDate,
              ),
              const SizedBox(height: 12),
              const Text(
                'Horário *',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              _PickerField(
                label: _hora == null ? '00:00' : _formatTime(_hora!),
                icon: Icons.access_time_outlined,
                onTap: _pickTime,
              ),
              const SizedBox(height: 12),
              const Text(
                'Urgência *',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _urgencia,
                isExpanded: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.fieldBg,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
                items: urgenciaOptions
                    .map((o) => DropdownMenuItem(
                          value: o.value,
                          child: Text(o.label),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _urgencia = v);
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _data != null && _hora != null
                    ? _confirmarAgendamento
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.grey200,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Confirmar agendamento'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => setState(() => _agendando = false),
                child: const Text(
                  'Voltar',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isPlaceholder = label == 'dd/mm/aaaa' || label == '00:00';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.fieldBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isPlaceholder
                      ? AppColors.textMuted
                      : AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
            ),
            Icon(icon, color: AppColors.textSecondary, size: 18),
          ],
        ),
      ),
    );
  }
}
