class FormOption {
  const FormOption({required this.value, required this.label});

  final String value;
  final String label;
}

const List<FormOption> tipoVisitaOptions = [
  FormOption(value: 'ROTINA', label: 'Rotina'),
  FormOption(value: 'DIAGNOSTICO', label: 'Diagnostico'),
  FormOption(value: 'ACOMPANHAMENTO', label: 'Acompanhamento'),
  FormOption(value: 'RETORNO', label: 'Retorno'),
  FormOption(value: 'EMERGENCIAL', label: 'Emergencial'),
];

const List<FormOption> urgenciaOptions = [
  FormOption(value: 'BAIXA', label: 'Baixa'),
  FormOption(value: 'MEDIA', label: 'Media'),
  FormOption(value: 'ALTA', label: 'Alta'),
  FormOption(value: 'CRITICA', label: 'Critica'),
];

const List<FormOption> criticidadeOptions = [
  FormOption(value: 'BAIXA', label: 'Baixa'),
  FormOption(value: 'MEDIA', label: 'Media'),
  FormOption(value: 'ALTA', label: 'Alta'),
  FormOption(value: 'CRITICA', label: 'Critica'),
];

const List<FormOption> prioridadeOptions = [
  FormOption(value: 'BAIXA', label: 'Baixa'),
  FormOption(value: 'MEDIA', label: 'Media'),
  FormOption(value: 'ALTA', label: 'Alta'),
  FormOption(value: 'CRITICA', label: 'Critica'),
];

const List<FormOption> verificacaoOptions = [
  FormOption(value: 'VISITA', label: 'Nova visita'),
  FormOption(value: 'LIGACAO', label: 'Ligacao'),
  FormOption(value: 'EMAIL', label: 'Email'),
  FormOption(value: 'OUTRO', label: 'Outro'),
];

const List<FormOption> temaPrincipalOptions = [
  FormOption(value: 'Solo e Fertilidade', label: 'Solo e Fertilidade'),
  FormOption(value: 'Irrigacao', label: 'Irrigacao'),
  FormOption(value: 'Pragas e Doencas', label: 'Pragas e Doencas'),
  FormOption(value: 'Plantio', label: 'Plantio'),
  FormOption(value: 'Colheita', label: 'Colheita'),
  FormOption(value: 'Infraestrutura', label: 'Infraestrutura'),
  FormOption(value: 'Manejo Animal', label: 'Manejo Animal'),
  FormOption(value: 'Gestao', label: 'Gestao'),
  FormOption(value: 'Outro', label: 'Outro'),
];

const List<FormOption> responsavelOptions = [
  FormOption(value: 'Produtor', label: 'Produtor'),
  FormOption(value: 'Tecnico', label: 'Tecnico'),
  FormOption(value: 'Laboratorio', label: 'Laboratorio'),
  FormOption(value: 'Cooperativa', label: 'Cooperativa'),
  FormOption(value: 'Outro', label: 'Outro'),
];

const List<String> diagnosticoCategorias = [
  'Solo e Fertilidade',
  'Irrigacao',
  'Pragas e Doencas',
  'Plantio',
  'Colheita',
  'Infraestrutura',
  'Manejo Animal',
  'Gestao',
  'Outro',
];

String optionLabel(
  List<FormOption> options,
  String? value, {
  String fallback = '',
}) {
  if (value == null || value.isEmpty) {
    return fallback;
  }

  for (final option in options) {
    if (option.value == value) {
      return option.label;
    }
  }

  return humanizeEnum(value);
}

String? knownOptionValue(List<FormOption> options, String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }

  for (final option in options) {
    if (option.value == value) {
      return value;
    }
  }

  return null;
}

String humanizeEnum(String value) {
  return value
      .toLowerCase()
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
