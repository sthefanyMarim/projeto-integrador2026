class RankingItem {
  const RankingItem({required this.id, required this.nome, required this.total});
  final int? id;
  final String nome;
  final int total;
  factory RankingItem.fromJson(Map<String, dynamic> j) => RankingItem(
        id: j['id'] == null ? null : (j['id'] as num).toInt(),
        nome: j['nome'] as String? ?? '',
        total: (j['total'] as num).toInt(),
      );
}

class RelatorioGeralModel {
  const RelatorioGeralModel({
    required this.inicio,
    required this.fim,
    required this.totalVisitas,
    required this.visitasPorStatus,
    required this.visitasPorTipo,
    required this.totalDiagnosticos,
    required this.diagnosticosPorCategoria,
    required this.diagnosticosPorCriticidade,
    required this.totalEncaminhamentos,
    required this.encaminhamentosPorStatus,
    required this.encaminhadosConcluidosNoPrazo,
    required this.encaminhadosComPrazo,
    required this.topPropriedadesVisitadas,
    required this.topPropriedadesDiagnosticos,
    required this.visitasPorTecnico,
  });

  final DateTime inicio;
  final DateTime fim;
  final int totalVisitas;
  final Map<String, int> visitasPorStatus;
  final Map<String, int> visitasPorTipo;
  final int totalDiagnosticos;
  final Map<String, int> diagnosticosPorCategoria;
  final Map<String, int> diagnosticosPorCriticidade;
  final int totalEncaminhamentos;
  final Map<String, int> encaminhamentosPorStatus;
  final int encaminhadosConcluidosNoPrazo;
  final int encaminhadosComPrazo;
  final List<RankingItem> topPropriedadesVisitadas;
  final List<RankingItem> topPropriedadesDiagnosticos;
  final List<RankingItem> visitasPorTecnico;

  factory RelatorioGeralModel.fromJson(Map<String, dynamic> j) {
    return RelatorioGeralModel(
      inicio: DateTime.parse(j['inicio'] as String),
      fim: DateTime.parse(j['fim'] as String),
      totalVisitas: (j['totalVisitas'] as num).toInt(),
      visitasPorStatus: _toIntMap(j['visitasPorStatus']),
      visitasPorTipo: _toIntMap(j['visitasPorTipo']),
      totalDiagnosticos: (j['totalDiagnosticos'] as num).toInt(),
      diagnosticosPorCategoria: _toIntMap(j['diagnosticosPorCategoria']),
      diagnosticosPorCriticidade: _toIntMap(j['diagnosticosPorCriticidade']),
      totalEncaminhamentos: (j['totalEncaminhamentos'] as num).toInt(),
      encaminhamentosPorStatus: _toIntMap(j['encaminhamentosPorStatus']),
      encaminhadosConcluidosNoPrazo: (j['encaminhadosConcluidosNoPrazo'] as num).toInt(),
      encaminhadosComPrazo: (j['encaminhadosComPrazo'] as num).toInt(),
      topPropriedadesVisitadas: _toRankingList(j['topPropriedadesVisitadas']),
      topPropriedadesDiagnosticos: _toRankingList(j['topPropriedadesDiagnosticos']),
      visitasPorTecnico: _toRankingList(j['visitasPorTecnico']),
    );
  }

  static Map<String, int> _toIntMap(dynamic raw) {
    if (raw == null) return {};
    final map = raw as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k, (v as num).toInt()));
  }

  static List<RankingItem> _toRankingList(dynamic raw) {
    if (raw == null) return [];
    return (raw as List).map((e) => RankingItem.fromJson(e as Map<String, dynamic>)).toList();
  }
}

class VisitaItemModel {
  const VisitaItemModel({required this.data, required this.hora, required this.tecnico, this.tipo, required this.status, this.temaPrincipal});
  final DateTime data;
  final String hora;
  final String tecnico;
  final String? tipo;
  final String status;
  final String? temaPrincipal;
  factory VisitaItemModel.fromJson(Map<String, dynamic> j) => VisitaItemModel(
        data: DateTime.parse(j['data'] as String),
        hora: j['hora'] as String? ?? '',
        tecnico: j['tecnico'] as String? ?? '',
        tipo: j['tipo'] as String?,
        status: j['status'] as String? ?? '',
        temaPrincipal: j['temaPrincipal'] as String?,
      );
}

class DiagnosticoItemModel {
  const DiagnosticoItemModel({required this.categoria, required this.criticidade, this.observacoes});
  final String categoria;
  final String criticidade;
  final String? observacoes;
  factory DiagnosticoItemModel.fromJson(Map<String, dynamic> j) => DiagnosticoItemModel(
        categoria: j['categoria'] as String? ?? '',
        criticidade: j['criticidade'] as String? ?? '',
        observacoes: j['observacoes'] as String?,
      );
}

class EncaminhamentoItemModel {
  const EncaminhamentoItemModel({required this.acaoRealizada, this.responsavel, this.prazo, required this.prioridade, required this.status});
  final String acaoRealizada;
  final String? responsavel;
  final DateTime? prazo;
  final String prioridade;
  final String status;
  factory EncaminhamentoItemModel.fromJson(Map<String, dynamic> j) => EncaminhamentoItemModel(
        acaoRealizada: j['acaoRealizada'] as String? ?? '',
        responsavel: j['responsavel'] as String?,
        prazo: j['prazo'] == null ? null : DateTime.tryParse(j['prazo'] as String),
        prioridade: j['prioridade'] as String? ?? '',
        status: j['status'] as String? ?? '',
      );
}

class RelatorioPropriedadeModel {
  const RelatorioPropriedadeModel({
    required this.propriedadeId,
    required this.propriedadeNome,
    required this.nomeProprietario,
    required this.municipio,
    this.tipoProducao,
    required this.inicio,
    required this.fim,
    required this.totalVisitas,
    required this.visitasPorStatus,
    required this.visitasPorTipo,
    required this.visitas,
    required this.totalDiagnosticos,
    required this.diagnosticosPorCategoria,
    required this.diagnosticosPorCriticidade,
    required this.diagnosticos,
    required this.totalEncaminhamentos,
    required this.encaminhamentosPorStatus,
    required this.encaminhamentos,
  });

  final int propriedadeId;
  final String propriedadeNome;
  final String nomeProprietario;
  final String municipio;
  final String? tipoProducao;
  final DateTime inicio;
  final DateTime fim;
  final int totalVisitas;
  final Map<String, int> visitasPorStatus;
  final Map<String, int> visitasPorTipo;
  final List<VisitaItemModel> visitas;
  final int totalDiagnosticos;
  final Map<String, int> diagnosticosPorCategoria;
  final Map<String, int> diagnosticosPorCriticidade;
  final List<DiagnosticoItemModel> diagnosticos;
  final int totalEncaminhamentos;
  final Map<String, int> encaminhamentosPorStatus;
  final List<EncaminhamentoItemModel> encaminhamentos;

  factory RelatorioPropriedadeModel.fromJson(Map<String, dynamic> j) {
    return RelatorioPropriedadeModel(
      propriedadeId: (j['propriedadeId'] as num).toInt(),
      propriedadeNome: j['propriedadeNome'] as String? ?? '',
      nomeProprietario: j['nomeProprietario'] as String? ?? '',
      municipio: j['municipio'] as String? ?? '',
      tipoProducao: j['tipoProducao'] as String?,
      inicio: DateTime.parse(j['inicio'] as String),
      fim: DateTime.parse(j['fim'] as String),
      totalVisitas: (j['totalVisitas'] as num).toInt(),
      visitasPorStatus: RelatorioGeralModel._toIntMap(j['visitasPorStatus']),
      visitasPorTipo: RelatorioGeralModel._toIntMap(j['visitasPorTipo']),
      visitas: _list(j['visitas'], VisitaItemModel.fromJson),
      totalDiagnosticos: (j['totalDiagnosticos'] as num).toInt(),
      diagnosticosPorCategoria: RelatorioGeralModel._toIntMap(j['diagnosticosPorCategoria']),
      diagnosticosPorCriticidade: RelatorioGeralModel._toIntMap(j['diagnosticosPorCriticidade']),
      diagnosticos: _list(j['diagnosticos'], DiagnosticoItemModel.fromJson),
      totalEncaminhamentos: (j['totalEncaminhamentos'] as num).toInt(),
      encaminhamentosPorStatus: RelatorioGeralModel._toIntMap(j['encaminhamentosPorStatus']),
      encaminhamentos: _list(j['encaminhamentos'], EncaminhamentoItemModel.fromJson),
    );
  }

  static List<T> _list<T>(dynamic raw, T Function(Map<String, dynamic>) fromJson) {
    if (raw == null) return [];
    return (raw as List).map((e) => fromJson(e as Map<String, dynamic>)).toList();
  }
}
