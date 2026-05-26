import 'package:flutter/material.dart';

import '../../core/api_error.dart';
import '../../core/api_error_dialog.dart';
import '../../core/app_colors.dart';
import '../../core/app_refresh_bus.dart';
import '../../data/models/propriedade_model.dart';
import '../../data/models/visita_model.dart';
import '../../data/services/propriedade_service.dart';
import '../../data/services/token_service.dart';
import '../../data/services/visita_service.dart';
import 'visita_form_options.dart';

class AgendamentoModal extends StatefulWidget {
  const AgendamentoModal({super.key, this.visit});

  final VisitaModel? visit;

  @override
  State<AgendamentoModal> createState() => _AgendamentoModalState();
}

class _AgendamentoModalState extends State<AgendamentoModal> {
  static const double _dropdownMenuMaxHeight = 280;

  final _formKey = GlobalKey<FormState>();
  final _observacoesController = TextEditingController();

  late final TokenService _tokenService;
  late final PropriedadeService _propriedadeService;
  late final VisitaService _visitaService;

  List<PropriedadeModel> _propriedades = const [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  int? _propriedadeId;
  DateTime? _dataVisita;
  TimeOfDay? _horario;
  String? _tipoVisita;
  String? _urgencia;
  String? _temaPrincipal;
  String? _nomeTecnico;

  bool get _editing => widget.visit != null;

  @override
  void initState() {
    super.initState();
    _tokenService = TokenService();
    _propriedadeService = PropriedadeService(_tokenService);
    _visitaService = VisitaService(_tokenService);
    _prefill();
    _loadInitialData();
  }

  @override
  void dispose() {
    _observacoesController.dispose();
    super.dispose();
  }

  void _prefill() {
    final visit = widget.visit;
    if (visit == null) {
      return;
    }

    _propriedadeId = visit.propriedadeId;
    _dataVisita = visit.dataVisita;
    _horario = _parseTime(visit.horaVisita);
    _tipoVisita = visit.tipoVisita;
    _urgencia = visit.urgencia;
    _temaPrincipal = knownOptionValue(
      temaPrincipalOptions,
      visit.temaPrincipal,
    );
    _observacoesController.text = visit.observacoes ?? '';
  }

  TimeOfDay? _parseTime(String? value) {
    if (value == null || value.length < 5) {
      return null;
    }

    final parts = value.split(':');
    if (parts.length < 2) {
      return null;
    }

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) {
      return null;
    }

    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _propriedadeService.listarAtivas(),
        _tokenService.getUserInfo(),
      ]);

      if (!mounted) {
        return;
      }

      final propriedades = results[0] as List<PropriedadeModel>;
      final userInfo =
          results[1] as ({String? nome, String? tipo, int? userId});

      setState(() {
        _propriedades = propriedades;
        _nomeTecnico = userInfo.nome ?? 'Usuario logado';
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _error = ApiError.message(
          error,
          fallback: 'Nao foi possivel carregar os dados do agendamento.',
        );
      });
      await ApiErrorDialog.show(
        context,
        error,
        title: 'Erro ao carregar agendamento',
        fallback: 'Nao foi possivel carregar os dados do agendamento.',
      );
    }
  }

  Future<void> _selectDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final initialDate = _dataVisita != null && !_dataVisita!.isBefore(today)
        ? _dataVisita!
        : today;

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 730)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSwatch().copyWith(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null && mounted) {
      setState(() => _dataVisita = date);
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _horario ?? const TimeOfDay(hour: 8, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              dialHandColor: AppColors.primary,
              dialBackgroundColor: AppColors.primarySurface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (time != null && mounted) {
      setState(() => _horario = time);
    }
  }

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }

  String _formatTime(TimeOfDay value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _timeForApi(TimeOfDay value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute:00';
  }

  Future<void> _submit() async {
    final formValid = _formKey.currentState?.validate() ?? false;
    if (!formValid) {
      return;
    }

    if (_dataVisita == null || _horario == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe a data e o horario da visita.')),
      );
      return;
    }

    if (_propriedadeId == null || _tipoVisita == null) {
      return;
    }

    setState(() => _saving = true);

    final request = SalvarVisitaRequest(
      propriedadeId: _propriedadeId!,
      dataVisita: _dataVisita!,
      horaVisita: _timeForApi(_horario!),
      tipoVisita: _tipoVisita!,
      temaPrincipal: _temaPrincipal,
      observacoes: _observacoesController.text.trim().isEmpty
          ? null
          : _observacoesController.text.trim(),
      urgencia: _urgencia,
    );

    try {
      if (_editing) {
        await _visitaService.atualizar(widget.visit!.id, request);
      } else {
        await _visitaService.criar(request);
      }

      if (!mounted) {
        return;
      }

      AppRefreshBus.notifyChanged();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _editing
                ? 'Visita atualizada com sucesso.'
                : 'Visita agendada com sucesso.',
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      await ApiErrorDialog.show(
        context,
        error,
        title: _editing ? 'Erro ao atualizar visita' : 'Erro ao agendar visita',
        fallback: _editing
            ? 'Nao foi possivel atualizar a visita.'
            : 'Nao foi possivel agendar a visita.',
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, controller) {
          final mediaQuery = MediaQuery.of(context);

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom:
                  mediaQuery.viewInsets.bottom + mediaQuery.padding.bottom + 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  height: 4,
                  width: 60,
                  decoration: BoxDecoration(
                    color: AppColors.grey200,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _editing ? 'Editar Visita' : 'Agendar Visita',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _editing
                      ? 'Atualize os dados do agendamento.'
                      : 'Preencha as informacoes para criar a visita.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    controller: controller,
                    child: _buildContent(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.only(top: 48),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_propriedades.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.grey50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Text(
          'Nenhuma propriedade ativa foi encontrada para agendar visitas.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Propriedade Rural *',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            initialValue: _propriedadeId,
            isExpanded: true,
            menuMaxHeight: _dropdownMenuMaxHeight,
            decoration: _inputDecoration(),
            items: _propriedades
                .map(
                  (item) => DropdownMenuItem<int>(
                    value: item.id,
                    child: Text(
                      item.nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            validator: (value) =>
                value == null ? 'Escolha uma propriedade.' : null,
            onChanged: (value) => setState(() => _propriedadeId = value),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Data da visita *',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    _buildPickerField(
                      label: _dataVisita == null
                          ? 'dd/mm/aaaa'
                          : _formatDate(_dataVisita!),
                      icon: Icons.calendar_today_outlined,
                      onTap: _selectDate,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Horario *',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    _buildPickerField(
                      label: _horario == null
                          ? '00:00'
                          : _formatTime(_horario!),
                      icon: Icons.access_time_outlined,
                      onTap: _selectTime,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Tecnico responsavel',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _readonlyField(_nomeTecnico ?? 'Usuario logado'),
          const SizedBox(height: 16),
          const Text(
            'Tipo de visita *',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _buildOptionDropdown(
            value: _tipoVisita,
            hint: 'Selecione o tipo',
            options: tipoVisitaOptions,
            validator: (value) => value == null ? 'Escolha o tipo.' : null,
            onChanged: (value) => setState(() => _tipoVisita = value),
          ),
          const SizedBox(height: 16),
          const Text('Urgencia', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _buildOptionDropdown(
            value: _urgencia,
            hint: 'Selecione a urgencia',
            options: urgenciaOptions,
            onChanged: (value) => setState(() => _urgencia = value),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tema principal',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _buildOptionDropdown(
            value: _temaPrincipal,
            hint: 'Selecione o tema',
            options: temaPrincipalOptions,
            onChanged: (value) => setState(() => _temaPrincipal = value),
          ),
          const SizedBox(height: 16),
          const Text(
            'Observacoes',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _observacoesController,
            maxLines: 3,
            decoration: _inputDecoration(
              hintText: 'Detalhes importantes para este agendamento',
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _saving ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.grey200,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                _saving
                    ? 'Salvando...'
                    : _editing
                    ? 'Salvar Alteracoes'
                    : 'Confirmar Agendamento',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.cloud_off_outlined, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _loadInitialData,
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }

  Widget _readonlyField(String value) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      alignment: Alignment.centerLeft,
      child: Text(
        value,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildOptionDropdown({
    required String? value,
    required String hint,
    required List<FormOption> options,
    required ValueChanged<String?> onChanged,
    FormFieldValidator<String>? validator,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      menuMaxHeight: _dropdownMenuMaxHeight,
      validator: validator,
      onChanged: onChanged,
      decoration: _inputDecoration(),
      hint: Text(hint, style: const TextStyle(color: AppColors.textMuted)),
      items: options
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
    );
  }

  InputDecoration _inputDecoration({String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: AppColors.fieldBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

  Widget _buildPickerField({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.fieldBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: label == 'dd/mm/aaaa' || label == '00:00'
                      ? AppColors.textMuted
                      : AppColors.textPrimary,
                ),
              ),
            ),
            Icon(icon, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
