class FormOption {
  const FormOption({required this.value, required this.label});

  final String value;
  final String label;
}

const List<FormOption> tipoVisitaOptions = [
  FormOption(value: 'ACOMPANHAMENTO', label: 'Acompanhamento'),
  FormOption(value: 'DIAGNOSTICO', label: 'Diagnóstico'),
  FormOption(value: 'EMERGENCIAL', label: 'Emergencial'),
  FormOption(value: 'RETORNO', label: 'Retorno'),
  FormOption(value: 'ROTINA', label: 'Rotina'),
];

const List<FormOption> urgenciaOptions = [
  FormOption(value: 'BAIXA', label: 'Baixa'),
  FormOption(value: 'MEDIA', label: 'Média'),
  FormOption(value: 'ALTA', label: 'Alta'),
  FormOption(value: 'CRITICA', label: 'Crítica'),
];

const List<FormOption> criticidadeOptions = [
  FormOption(value: 'BAIXA', label: 'Baixa'),
  FormOption(value: 'MEDIA', label: 'Média'),
  FormOption(value: 'ALTA', label: 'Alta'),
  FormOption(value: 'CRITICA', label: 'Crítica'),
];

const List<FormOption> prioridadeOptions = [
  FormOption(value: 'BAIXA', label: 'Baixa'),
  FormOption(value: 'MEDIA', label: 'Média'),
  FormOption(value: 'ALTA', label: 'Alta'),
  FormOption(value: 'CRITICA', label: 'Crítica'),
];

const List<FormOption> tipoProducaoOptions = [
  FormOption(value: 'AGRICULTURA_CONVENCIONAL', label: 'Agricultura Convencional'),
  FormOption(value: 'AGRICULTURA_FAMILIAR', label: 'Agricultura Familiar'),
  FormOption(value: 'AGROECOLOGICA_ORGANICA', label: 'Agroecológica / Orgânica'),
  FormOption(value: 'AVICULTURA', label: 'Avicultura'),
  FormOption(value: 'FRUTICULTURA', label: 'Fruticultura'),
  FormOption(value: 'HORTICULTURA', label: 'Horticultura'),
  FormOption(value: 'PECUARIA', label: 'Pecuária'),
  FormOption(value: 'PISCICULTURA', label: 'Piscicultura'),
  FormOption(value: 'MISTA', label: 'Produção Mista'),
  FormOption(value: 'SILVICULTURA', label: 'Silvicultura'),
  FormOption(value: 'OUTROS', label: 'Outros'),
];

const List<FormOption> verificacaoOptions = [
  FormOption(value: 'EMAIL', label: 'Email'),
  FormOption(value: 'LIGACAO', label: 'Ligação'),
  FormOption(value: 'VISITA', label: 'Nova visita'),
  FormOption(value: 'OUTRO', label: 'Outro'),
];

const List<FormOption> temaPrincipalOptions = [
  FormOption(value: 'Colheita', label: 'Colheita'),
  FormOption(value: 'Gestao', label: 'Gestão'),
  FormOption(value: 'Infraestrutura', label: 'Infraestrutura'),
  FormOption(value: 'Irrigacao', label: 'Irrigação'),
  FormOption(value: 'Manejo Animal', label: 'Manejo Animal'),
  FormOption(value: 'Plantio', label: 'Plantio'),
  FormOption(value: 'Pragas e Doencas', label: 'Pragas e Doenças'),
  FormOption(value: 'Solo e Fertilidade', label: 'Solo e Fertilidade'),
  FormOption(value: 'Outro', label: 'Outro'),
];

const List<FormOption> responsavelOptions = [
  FormOption(value: 'Cooperativa', label: 'Cooperativa'),
  FormOption(value: 'Laboratorio', label: 'Laboratório'),
  FormOption(value: 'Produtor', label: 'Produtor'),
  FormOption(value: 'Tecnico', label: 'Técnico'),
  FormOption(value: 'Outro', label: 'Outro'),
];

const List<String> diagnosticoCategorias = [
  'Colheita',
  'Gestao',
  'Infraestrutura',
  'Irrigacao',
  'Manejo Animal',
  'Plantio',
  'Pragas e Doencas',
  'Solo e Fertilidade',
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
