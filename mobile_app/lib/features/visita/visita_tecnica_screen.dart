import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

class _EncaminhamentoItem {
  _EncaminhamentoItem({
    required this.acao,
    required this.responsavel,
    required this.prazo,
    required this.prioridade,
  });

  final String acao;
  final String responsavel;
  final DateTime? prazo;
  final String prioridade;
}

class _DiagnosticoItem {
  _DiagnosticoItem({
    required this.categoria,
    required this.criticidade,
    required this.observacoes,
  });

  final String categoria;
  final String criticidade;
  final String observacoes;
}

class VisitaTecnicaScreen extends StatefulWidget {
  const VisitaTecnicaScreen({
    super.key,
    required this.propriedade,
    required this.dataVisita,
    required this.horario,
    this.tipo = '',
  });

  final String propriedade;
  final DateTime dataVisita;
  final String horario;
  final String tipo;

  @override
  State<VisitaTecnicaScreen> createState() => _VisitaTecnicaScreenState();
}

class _VisitaTecnicaScreenState extends State<VisitaTecnicaScreen> {
  final _pageController = PageController();
  int _step = 0;

  final _formKey1 = GlobalKey<FormState>();
  String? _tipoVisita;
  String? _temaPrincipal;
  String? _urgencia;
  final _obsCtrl = TextEditingController();

  final _diagFormKey = GlobalKey<FormState>();
  String? _diagCategoria;
  String _diagCriticidade = 'Média';
  final _diagObsCtrl = TextEditingController();
  final List<_DiagnosticoItem> _diagnosticos = [];
  bool _diagSemItens = false;

  final _encFormKey = GlobalKey<FormState>();
  final _encAcaoCtrl = TextEditingController();
  String? _encResponsavel;
  DateTime? _encPrazo;
  String _encPrioridade = 'Média';
  final List<_EncaminhamentoItem> _encaminhamentos = [];
  bool _encSemItens = false;

  static const _tiposVisita = [
    'Rotina',
    'Acompanhamento',
    'Retorno',
    'Verificação',
  ];
  static const _temas = [
    'Solo',
    'Plantio',
    'Irrigação',
    'Pragas',
    'Colheita',
    'Gestão',
  ];
  static const _urgencias = ['Baixa', 'Normal', 'Alta', 'Crítica'];
  static const _categorias = [
    'Solo e Fertilidade',
    'Irrigação',
    'Pragas e Doenças',
    'Plantio',
    'Colheita',
    'Infraestrutura',
    'Manejo Animal',
    'Gestão',
    'Outro',
  ];
  static const _criticidades = ['Baixa', 'Média', 'Alta', 'Crítica'];
  static const _responsaveis = ['Sthefany Marim', 'João Silva', 'Ana Costa'];

  @override
  void initState() {
    super.initState();
    if (widget.tipo.isNotEmpty && _tiposVisita.contains(widget.tipo)) {
      _tipoVisita = widget.tipo;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _obsCtrl.dispose();
    _diagObsCtrl.dispose();
    _encAcaoCtrl.dispose();
    super.dispose();
  }

  void _goTo(int step) {
    setState(() => _step = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  bool _validateCurrent() {
    switch (_step) {
      case 0:
        return _formKey1.currentState?.validate() ?? false;
      case 1:
        if (_diagnosticos.isEmpty) {
          setState(() => _diagSemItens = true);
          return false;
        }
        return true;
      case 2:
        if (_encaminhamentos.isEmpty) {
          setState(() => _encSemItens = true);
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _next() {
    if (_validateCurrent()) {
      _goTo(_step + 1);
    }
  }

  void _prev() => _goTo(_step - 1);

  void _finalizar() {
    if (!_validateCurrent()) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Visita finalizada com sucesso!'),
        backgroundColor: AppColors.primary,
      ),
    );
    Navigator.of(context).pop();
  }

  void _adicionarDiagnostico() {
    if (!(_diagFormKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _diagnosticos.add(
        _DiagnosticoItem(
          categoria: _diagCategoria!,
          criticidade: _diagCriticidade,
          observacoes: _diagObsCtrl.text.trim(),
        ),
      );
      _diagCategoria = null;
      _diagCriticidade = 'Média';
      _diagObsCtrl.clear();
      _diagSemItens = false;
    });
  }

  void _removerDiagnostico(int index) {
    setState(() => _diagnosticos.removeAt(index));
  }

  void _adicionarEncaminhamento() {
    if (!(_encFormKey.currentState?.validate() ?? false)) {
      return;
    }
    if (_encResponsavel == null) {
      return;
    }

    setState(() {
      _encaminhamentos.add(
        _EncaminhamentoItem(
          acao: _encAcaoCtrl.text.trim(),
          responsavel: _encResponsavel!,
          prazo: _encPrazo,
          prioridade: _encPrioridade,
        ),
      );
      _encAcaoCtrl.clear();
      _encResponsavel = null;
      _encPrazo = null;
      _encPrioridade = 'Média';
      _encSemItens = false;
    });
  }

  void _removerEncaminhamento(int index) {
    setState(() => _encaminhamentos.removeAt(index));
  }

  Future<void> _selectPrazo() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _encPrazo ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.fromSwatch().copyWith(
            primary: AppColors.primary,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _encPrazo = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [_buildStep1(), _buildStep2(), _buildStep3()],
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
                onTap: () => Navigator.of(context).pop(),
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
    final labels = ['Identificação', 'Diagnóstico', 'Encaminhamento'];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < 3; i++) ...[
          _stepCircle(i, labels[i]),
          if (i < 2)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 13),
                child: Container(
                  height: 2,
                  color: _step > i
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.35),
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _stepCircle(int index, String label) {
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
                onPressed: _prev,
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
              onPressed: _step == 2 ? _finalizar : _next,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _step == 2 ? 'Finalizar' : 'Próximo',
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

  Widget _buildStep1() {
    final dataFmt =
        '${widget.dataVisita.day.toString().padLeft(2, '0')}/'
        '${widget.dataVisita.month.toString().padLeft(2, '0')}/'
        '${widget.dataVisita.year}';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Form(
        key: _formKey1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dados da Visita',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _label('Propriedade Rural *'),
            _readonlyField(widget.propriedade),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Data da Visita *'),
                      _readonlyField(dataFmt),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Horário *'),
                      _readonlyField(widget.horario),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _label('Tipo de Visita'),
            _dropdown(
              value: _tipoVisita,
              hint: 'Selecione o tipo',
              items: _tiposVisita,
              onChanged: (value) => setState(() => _tipoVisita = value),
            ),
            const SizedBox(height: 14),
            _label('Tema Principal'),
            _dropdown(
              value: _temaPrincipal,
              hint: 'Selecione o tema',
              items: _temas,
              onChanged: (value) => setState(() => _temaPrincipal = value),
            ),
            const SizedBox(height: 14),
            _label('Urgência *'),
            _dropdown(
              value: _urgencia,
              hint: 'Selecione a urgência',
              items: _urgencias,
              validator: (value) => value == null ? 'Campo obrigatório' : null,
              onChanged: (value) => setState(() => _urgencia = value),
            ),
            const SizedBox(height: 14),
            _label('Observações Gerais'),
            TextFormField(
              controller: _obsCtrl,
              maxLines: 3,
              decoration: _inputDec('Descreva observações gerais...'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Diagnósticos da Visita',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Adicione um ou mais diagnósticos identificados.',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.grey50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Form(
              key: _diagFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _label('Categoria *'),
                  _dropdown(
                    value: _diagCategoria,
                    hint: 'Selecione a categoria',
                    items: _categorias,
                    validator: (value) =>
                        value == null ? 'Selecione uma categoria' : null,
                    onChanged: (value) =>
                        setState(() => _diagCategoria = value),
                  ),
                  const SizedBox(height: 14),
                  _label('Criticidade'),
                  const SizedBox(height: 8),
                  _buildCriticidadeSelector(),
                  const SizedBox(height: 14),
                  _label('Observações *'),
                  TextFormField(
                    controller: _diagObsCtrl,
                    maxLines: 3,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Campo obrigatório'
                        : null,
                    decoration: _inputDec(
                      'Descreva o diagnóstico observado...',
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 46,
                    child: OutlinedButton.icon(
                      onPressed: _adicionarDiagnostico,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text(
                        'Adicionar Diagnóstico',
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
          if (_diagSemItens) ...[
            const SizedBox(height: 8),
            const Row(
              children: [
                Icon(Icons.error_outline, size: 14, color: AppColors.error),
                SizedBox(width: 6),
                Text(
                  'Adicione pelo menos um diagnóstico para continuar.',
                  style: TextStyle(fontSize: 12, color: AppColors.error),
                ),
              ],
            ),
          ],
          if (_diagnosticos.isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                const Text(
                  'Diagnósticos Adicionados',
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

  Widget _buildCriticidadeSelector() {
    return Row(
      children: _criticidades.map((label) {
        final isSelected = _diagCriticidade == label;
        final color = _criticidadeColor(label);
        final bg = _criticidadeBg(label);

        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _diagCriticidade = label),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: isSelected ? bg : AppColors.fieldBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? color : AppColors.border,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Center(
                child: Text(
                  label,
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
      }).toList(),
    );
  }

  Widget _buildDiagnosticoCard(int index) {
    final item = _diagnosticos[index];
    final color = _criticidadeColor(item.criticidade);
    final bg = _criticidadeBg(item.criticidade);

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
                            color: bg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.criticidade,
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
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              color: AppColors.grey400,
              onPressed: () => _removerDiagnostico(index),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep3() {
    final prazoFmt = _encPrazo == null
        ? null
        : '${_encPrazo!.day.toString().padLeft(2, '0')}/'
              '${_encPrazo!.month.toString().padLeft(2, '0')}/'
              '${_encPrazo!.year}';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Encaminhamentos',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Adicione um ou mais encaminhamentos necessários.',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.grey50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Form(
              key: _encFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _label('Ação de Encaminhamento *'),
                  TextFormField(
                    controller: _encAcaoCtrl,
                    maxLines: 3,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Campo obrigatório'
                        : null,
                    decoration: _inputDec(
                      'Descreva a ação de encaminhamento...',
                    ),
                  ),
                  const SizedBox(height: 14),
                  _label('Responsável *'),
                  _dropdown(
                    value: _encResponsavel,
                    hint: 'Selecionar responsável',
                    items: _responsaveis,
                    validator: (value) =>
                        value == null ? 'Campo obrigatório' : null,
                    onChanged: (value) =>
                        setState(() => _encResponsavel = value),
                  ),
                  const SizedBox(height: 14),
                  _label('Prazo para Conclusão'),
                  GestureDetector(
                    onTap: _selectPrazo,
                    child: Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.fieldBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              prazoFmt ?? 'dd/mm/aaaa',
                              style: TextStyle(
                                fontSize: 15,
                                color: _encPrazo == null
                                    ? AppColors.textMuted
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 18,
                            color: AppColors.grey400,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _label('Prioridade'),
                  const SizedBox(height: 8),
                  _buildPrioritySelector(),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 46,
                    child: OutlinedButton.icon(
                      onPressed: _adicionarEncaminhamento,
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
          if (_encSemItens) ...[
            const SizedBox(height: 8),
            const Row(
              children: [
                Icon(Icons.error_outline, size: 14, color: AppColors.error),
                SizedBox(width: 6),
                Text(
                  'Adicione pelo menos um encaminhamento para finalizar.',
                  style: TextStyle(fontSize: 12, color: AppColors.error),
                ),
              ],
            ),
          ],
          if (_encaminhamentos.isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                const Text(
                  'Encaminhamentos Adicionados',
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
    final color = _priorityColor(item.prioridade);
    final bg = _priorityBg(item.prioridade);
    final prazoStr = item.prazo == null
        ? 'Sem prazo'
        : '${item.prazo!.day.toString().padLeft(2, '0')}/'
              '${item.prazo!.month.toString().padLeft(2, '0')}/'
              '${item.prazo!.year}';

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
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.prioridade,
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
                        Flexible(
                          child: Text(
                            item.responsavel,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 12,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          prazoStr,
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
              onPressed: () => _removerEncaminhamento(index),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrioritySelector() {
    const options = ['Alta', 'Média', 'Baixa'];

    return Row(
      children: options.map((label) {
        final isSelected = _encPrioridade == label;
        final textColor = _priorityColor(label);
        final bgColor = _priorityBg(label);

        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _encPrioridade = label),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? bgColor : AppColors.fieldBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? textColor : AppColors.border,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected
                        ? FontWeight.w700
                        : FontWeight.normal,
                    color: isSelected ? textColor : AppColors.textMuted,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
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

  Color _criticidadeColor(String value) {
    switch (value) {
      case 'Crítica':
        return AppColors.error;
      case 'Alta':
        return AppColors.warning;
      case 'Média':
        return const Color(0xFF1565C0);
      default:
        return AppColors.success;
    }
  }

  Color _criticidadeBg(String value) {
    switch (value) {
      case 'Crítica':
        return AppColors.errorSurface;
      case 'Alta':
        return AppColors.warningSurface;
      case 'Média':
        return AppColors.infoSurface;
      default:
        return AppColors.successSurface;
    }
  }

  Color _priorityColor(String value) {
    if (value == 'Alta') {
      return AppColors.error;
    }
    if (value == 'Média') {
      return AppColors.warning;
    }
    return AppColors.success;
  }

  Color _priorityBg(String value) {
    if (value == 'Alta') {
      return AppColors.errorSurface;
    }
    if (value == 'Média') {
      return AppColors.warningSurface;
    }
    return AppColors.successSurface;
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

  InputDecoration _inputDec(String hint) {
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

  Widget _dropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    FormFieldValidator<String>? validator,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.fieldBg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
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
      ),
      hint: Text(hint, style: const TextStyle(color: AppColors.textMuted)),
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
    );
  }
}
