import 'encaminhamento_model.dart';
import 'visita_model.dart';

class DashboardModel {
  const DashboardModel({
    required this.nomeUsuario,
    required this.totalPropriedades,
    required this.visitasAtrasadas,
    required this.pendenciasUrgentes,
    required this.visitasHoje,
    required this.pendenciasUrgentesLista,
  });

  final String nomeUsuario;
  final int totalPropriedades;
  final int visitasAtrasadas;
  final int pendenciasUrgentes;
  final List<VisitaModel> visitasHoje;
  final List<EncaminhamentoModel> pendenciasUrgentesLista;

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    return DashboardModel(
      nomeUsuario: json['nomeUsuario'] as String? ?? '',
      totalPropriedades: (json['totalPropriedades'] as num?)?.toInt() ?? 0,
      visitasAtrasadas: (json['visitasAtrasadas'] as num?)?.toInt() ?? 0,
      pendenciasUrgentes: (json['pendenciasUrgentes'] as num?)?.toInt() ?? 0,
      visitasHoje: ((json['visitasHoje'] as List<dynamic>?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(VisitaModel.fromJson)
          .toList(),
      pendenciasUrgentesLista:
          ((json['pendenciasUrgentesLista'] as List<dynamic>?) ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(EncaminhamentoModel.fromJson)
              .toList(),
    );
  }
}
