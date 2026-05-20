// ignore: constant_identifier_names
enum TipoUsuario { TECNICO, ADMIN }

class LoginRequest {
  final String matricula;
  final String senha;

  LoginRequest({required this.matricula, required this.senha});

  Map<String, dynamic> toJson() => {'matricula': matricula, 'senha': senha};
}

class LoginResponse {
  final String accessToken;
  final String refreshToken;
  final TipoUsuario tipo;
  final String nome;
  final int userId;

  LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.tipo,
    required this.nome,
    required this.userId,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      tipo: TipoUsuario.values.firstWhere((e) => e.name == json['tipo']),
      nome: json['nome'] as String,
      userId: (json['userId'] as num).toInt(),
    );
  }
}
