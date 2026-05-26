class PropriedadeModel {
  const PropriedadeModel({
    required this.id,
    required this.nome,
    required this.nomeProprietario,
    this.telefone,
    this.endereco,
    this.municipio,
    this.estado,
    this.latitude,
    this.longitude,
    this.tipoProducao,
    required this.ativa,
    this.criadoEm,
  });

  final int id;
  final String nome;
  final String nomeProprietario;
  final String? telefone;
  final String? endereco;
  final String? municipio;
  final String? estado;
  final double? latitude;
  final double? longitude;
  final String? tipoProducao;
  final bool ativa;
  final DateTime? criadoEm;

  factory PropriedadeModel.fromJson(Map<String, dynamic> json) {
    return PropriedadeModel(
      id: (json['id'] as num).toInt(),
      nome: json['nome'] as String? ?? '',
      nomeProprietario: json['nomeProprietario'] as String? ?? '',
      telefone: json['telefone'] as String?,
      endereco: json['endereco'] as String?,
      municipio: json['municipio'] as String?,
      estado: json['estado'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      tipoProducao: json['tipoProducao'] as String?,
      ativa: json['ativa'] as bool? ?? true,
      criadoEm: json['criadoEm'] != null
          ? DateTime.tryParse(json['criadoEm'] as String)
          : null,
    );
  }
}
