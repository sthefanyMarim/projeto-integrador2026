class DiagnosticoResumado {
  const DiagnosticoResumado({
    required this.id,
    required this.categoria,
    required this.criticidade,
    this.observacoes,
    this.imagemUrl,
  });

  final int id;
  final String categoria;
  final String criticidade;
  final String? observacoes;
  final String? imagemUrl;

  factory DiagnosticoResumado.fromJson(Map<String, dynamic> json) {
    return DiagnosticoResumado(
      id: (json['id'] as num).toInt(),
      categoria: json['categoria'] as String? ?? '',
      criticidade: json['criticidade'] as String? ?? 'BAIXA',
      observacoes: json['observacoes'] as String?,
      imagemUrl: json['imagemUrl'] as String?,
    );
  }
}

class EncaminhamentoResumado {
  const EncaminhamentoResumado({
    required this.id,
    required this.acaoRealizada,
    required this.prioridade,
    required this.status,
    this.responsavel,
    this.prazo,
    this.verificacao,
  });

  final int id;
  final String acaoRealizada;
  final String prioridade;
  final String status;
  final String? responsavel;
  final DateTime? prazo;
  final String? verificacao;

  factory EncaminhamentoResumado.fromJson(Map<String, dynamic> json) {
    return EncaminhamentoResumado(
      id: (json['id'] as num).toInt(),
      acaoRealizada: json['acaoRealizada'] as String? ?? '',
      prioridade: json['prioridade'] as String? ?? 'MEDIA',
      status: json['status'] as String? ?? 'PENDENTE',
      responsavel: json['responsavel'] as String?,
      prazo: json['prazo'] == null
          ? null
          : DateTime.tryParse(json['prazo'] as String),
      verificacao: json['verificacao'] as String?,
    );
  }
}

class VisitaDetalheModel {
  const VisitaDetalheModel({
    required this.id,
    required this.usuarioNome,
    required this.propriedadeNome,
    required this.dataVisita,
    required this.horaVisita,
    required this.statusVisita,
    required this.urgencia,
    required this.diagnosticos,
    required this.encaminhamentos,
    this.tipoVisita,
    this.temaPrincipal,
    this.observacoes,
  });

  final int id;
  final String usuarioNome;
  final String propriedadeNome;
  final DateTime dataVisita;
  final String horaVisita;
  final String statusVisita;
  final String urgencia;
  final String? tipoVisita;
  final String? temaPrincipal;
  final String? observacoes;
  final List<DiagnosticoResumado> diagnosticos;
  final List<EncaminhamentoResumado> encaminhamentos;

  factory VisitaDetalheModel.fromJson(Map<String, dynamic> json) {
    return VisitaDetalheModel(
      id: (json['id'] as num).toInt(),
      usuarioNome: json['usuarioNome'] as String? ?? '',
      propriedadeNome: json['propriedadeNome'] as String? ?? '',
      dataVisita: DateTime.parse(json['dataVisita'] as String),
      horaVisita: json['horaVisita'] as String? ?? '00:00:00',
      statusVisita: json['statusVisita'] as String? ?? 'AGENDADA',
      urgencia: json['urgencia'] as String? ?? 'BAIXA',
      tipoVisita: json['tipoVisita'] as String?,
      temaPrincipal: json['temaPrincipal'] as String?,
      observacoes: json['observacoes'] as String?,
      diagnosticos: (json['diagnosticos'] as List<dynamic>? ?? [])
          .map((e) => DiagnosticoResumado.fromJson(e as Map<String, dynamic>))
          .toList(),
      encaminhamentos: (json['encaminhamentos'] as List<dynamic>? ?? [])
          .map(
            (e) => EncaminhamentoResumado.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  String get horaCurta =>
      horaVisita.length >= 5 ? horaVisita.substring(0, 5) : horaVisita;
}
