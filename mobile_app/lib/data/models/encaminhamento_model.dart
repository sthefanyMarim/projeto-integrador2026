class EncaminhamentoModel {
  const EncaminhamentoModel({
    required this.id,
    required this.visitaId,
    required this.propriedadeNome,
    required this.acaoRealizada,
    this.responsavel,
    this.prazo,
    this.verificacao,
    required this.prioridade,
    required this.status,
  });

  final int id;
  final int visitaId;
  final String propriedadeNome;
  final String acaoRealizada;
  final String? responsavel;
  final DateTime? prazo;
  final String? verificacao;
  final String prioridade;
  final String status;

  factory EncaminhamentoModel.fromJson(Map<String, dynamic> json) {
    return EncaminhamentoModel(
      id: (json['id'] as num).toInt(),
      visitaId: (json['visitaId'] as num).toInt(),
      propriedadeNome: json['propriedadeNome'] as String? ?? '',
      acaoRealizada: json['acaoRealizada'] as String? ?? '',
      responsavel: json['responsavel'] as String?,
      prazo: _parseDate(json['prazo'] as String?),
      verificacao: json['verificacao'] as String?,
      prioridade: json['prioridade'] as String? ?? 'MEDIA',
      status: json['status'] as String? ?? 'PENDENTE',
    );
  }

  String get prioridadeLabel => _enumLabel(prioridade);
  String get verificacaoLabel => switch (verificacao) {
    'VISITA' => 'Nova visita',
    'LIGACAO' => 'Ligacao',
    'EMAIL' => 'Email',
    'OUTRO' => 'Outro',
    null || '' => '',
    _ => _enumLabel(verificacao),
  };

  String get statusLabel => switch (status) {
    'PENDENTE' => 'Pendente',
    'ATRASADO' => 'Atrasado',
    'CONCLUIDO' => 'ConcluÃ­do',
    'CANCELADO' => 'Cancelado',
    _ => _enumLabel(status),
  };

  bool get concluido => status == 'CONCLUIDO';
  bool get cancelado => status == 'CANCELADO';
  bool get atrasado => status == 'ATRASADO';
  bool get podeConcluir => !concluido && !cancelado;
  bool get podeCancelar => !concluido && !cancelado;

  static DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }

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
