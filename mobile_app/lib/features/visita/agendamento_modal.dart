import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

class AgendamentoModal extends StatefulWidget {
  const AgendamentoModal({super.key});

  @override
  State<AgendamentoModal> createState() => _AgendamentoModalState();
}

class _AgendamentoModalState extends State<AgendamentoModal> {
  final _formKey = GlobalKey<FormState>();
  String? _propriedade;
  DateTime? _dataVisita;
  TimeOfDay? _horario;
  String? _tecnico;
  String? _tipoVisita;
  String? _urgencia;

  static const _propriedades = [
    'Sítio Santa Rosa',
    'Chácara Esperança',
    'Fazenda Bela Vista',
  ];

  static const _tecnicos = ['Sthefany Marim', 'João Silva', 'Ana Costa'];

  static const _tiposVisita = ['Rotina', 'Acompanhamento', 'Retorno'];

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _dataVisita ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365)),
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

    if (date != null) {
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

    if (time != null) {
      setState(() => _horario = time);
    }
  }

  void _confirm() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Agendamento confirmado')));
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
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
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
                const Text(
                  'Agendamento de Visita',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Preencha as informações abaixo',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    controller: controller,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Propriedade Rural *',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          _buildDropdown<String>(
                            value: _propriedade,
                            hint: 'Selecione a propriedade',
                            items: _propriedades,
                            validator: (value) => value == null
                                ? 'Escolha uma propriedade'
                                : null,
                            onChanged: (value) =>
                                setState(() => _propriedade = value),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Data da Visita *',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildPickerField(
                                      label: _dataVisita == null
                                          ? 'dd/mm/aaaa'
                                          : '${_dataVisita!.day.toString().padLeft(2, '0')}/${_dataVisita!.month.toString().padLeft(2, '0')}/${_dataVisita!.year}',
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
                                      'Horário *',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildPickerField(
                                      label: _horario == null
                                          ? '00:00'
                                          : _horario!.format(context),
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
                            'Técnico Responsável *',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          _buildDropdown<String>(
                            value: _tecnico,
                            hint: 'Selecione o técnico',
                            items: _tecnicos,
                            validator: (value) =>
                                value == null ? 'Escolha um técnico' : null,
                            onChanged: (value) =>
                                setState(() => _tecnico = value),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Tipo de Visita',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          _buildDropdown<String>(
                            value: _tipoVisita,
                            hint: 'Selecione o tipo',
                            items: _tiposVisita,
                            validator: (value) => null,
                            onChanged: (value) =>
                                setState(() => _tipoVisita = value),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Urgência *',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            initialValue: _urgencia,
                            onChanged: (value) =>
                                setState(() => _urgencia = value),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Informe a urgência'
                                : null,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.fieldBg,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: AppColors.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: AppColors.border),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _confirm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'Confirmar Agendamento',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required String hint,
    required List<T> items,
    required FormFieldValidator<T> validator,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
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
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.border),
        ),
      ),
      items: items
          .map(
            (item) =>
                DropdownMenuItem<T>(value: item, child: Text(item.toString())),
          )
          .toList(),
      hint: Text(hint, style: const TextStyle(color: AppColors.textMuted)),
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
                  color: label.startsWith('dd') || label == '00:00'
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
