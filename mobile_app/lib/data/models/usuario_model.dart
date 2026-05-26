class UsuarioModel {
  const UsuarioModel({
    required this.id,
    required this.nome,
    required this.matricula,
    required this.email,
    this.telefone,
    required this.tipo,
    this.fotoUrl,
    required this.ativo,
    this.criadoEm,
  });

  final int id;
  final String nome;
  final String matricula;
  final String email;
  final String? telefone;
  final String tipo;
  final String? fotoUrl;
  final bool ativo;
  final DateTime? criadoEm;

  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    return UsuarioModel(
      id: (json['id'] as num).toInt(),
      nome: json['nome'] as String? ?? '',
      matricula: json['matricula'] as String? ?? '',
      email: json['email'] as String? ?? '',
      telefone: json['telefone'] as String?,
      tipo: json['tipo'] as String? ?? 'TECNICO',
      fotoUrl: json['fotoUrl'] as String?,
      ativo: json['ativo'] as bool? ?? true,
      criadoEm: json['criadoEm'] != null
          ? DateTime.tryParse(json['criadoEm'] as String)
          : null,
    );
  }
}
