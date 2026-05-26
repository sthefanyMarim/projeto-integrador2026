class VisitaModel {
  const VisitaModel({
    required this.id,
    required this.usuarioId,
    required this.usuarioNome,
    required this.propriedadeId,
    required this.propriedadeNome,
    required this.dataVisita,
    required this.horaVisita,
    this.tipoVisita,
    this.temaPrincipal,
    this.observacoes,
    required this.statusVisita,
    required this.urgencia,
  });

  final int id;
  final int usuarioId;
  final String usuarioNome;
  final int propriedadeId;
  final String propriedadeNome;
  final DateTime dataVisita;
  final String horaVisita;
  final String? tipoVisita;
  final String? temaPrincipal;
  final String? observacoes;
  final String statusVisita;
  final String urgencia;

  factory VisitaModel.fromJson(Map<String, dynamic> json) {
    return VisitaModel(
      id: (json['id'] as num).toInt(),
      usuarioId: (json['usuarioId'] as num).toInt(),
      usuarioNome: json['usuarioNome'] as String? ?? '',
      propriedadeId: (json['propriedadeId'] as num).toInt(),
      propriedadeNome: json['propriedadeNome'] as String? ?? '',
      dataVisita: DateTime.parse(json['dataVisita'] as String),
      horaVisita: json['horaVisita'] as String? ?? '00:00:00',
      tipoVisita: json['tipoVisita'] as String?,
      temaPrincipal: json['temaPrincipal'] as String?,
      observacoes: json['observacoes'] as String?,
      statusVisita: json['statusVisita'] as String? ?? 'AGENDADA',
      urgencia: json['urgencia'] as String? ?? 'BAIXA',
    );
  }

  String get horaCurta =>
      horaVisita.length >= 5 ? horaVisita.substring(0, 5) : horaVisita;

  String get tipoLabel => _enumLabel(tipoVisita);
  String get urgenciaLabel => _enumLabel(urgencia);
  String get statusLabel => switch (statusVisita) {
    'AGENDADA' => 'Pendente',
    'CONCLUIDA' => 'ConcluÃ­da',
    'CANCELADA' => 'Cancelada',
    'ATRASADA' => 'Atrasada',
    _ => _enumLabel(statusVisita),
  };

  bool get atrasada => statusVisita == 'ATRASADA';
  bool get concluida => statusVisita == 'CONCLUIDA';
  bool get cancelada => statusVisita == 'CANCELADA';
  bool get podeEditar => !concluida && !cancelada;
  bool get podeCancelar => !concluida && !cancelada;
  bool get podeFinalizar => !concluida && !cancelada;

  static String _enumLabel(String? value) {
    if (value == null || value.isEmpty) {
      return '';
    }

    return value
        .toLowerCase()
        .split('_')
        .map((part) {
          if (part.isEmpty) {
            return part;
          }
          return '${part[0].toUpperCase()}${part.substring(1)}';
        })
        .join(' ');
  }
}
