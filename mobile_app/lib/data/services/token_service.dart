import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/auth_model.dart';

class TokenService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _keyAccess = 'access_token';
  static const _keyRefresh = 'refresh_token';
  static const _keyNome = 'nome';
  static const _keyUserId = 'user_id';
  static const _keyTipo = 'tipo';

  Future<void> saveTokens(LoginResponse response) async {
    await Future.wait([
      _storage.write(key: _keyAccess, value: response.accessToken),
      _storage.write(key: _keyRefresh, value: response.refreshToken),
      _storage.write(key: _keyNome, value: response.nome),
      _storage.write(key: _keyUserId, value: response.userId.toString()),
      _storage.write(key: _keyTipo, value: response.tipo.name),
    ]);
  }

  Future<String?> getAccessToken() => _storage.read(key: _keyAccess);
  Future<String?> getRefreshToken() => _storage.read(key: _keyRefresh);

  Future<bool> hasTokens() async {
    final token = await _storage.read(key: _keyAccess);
    return token != null && token.isNotEmpty;
  }

  Future<void> clearTokens() => _storage.deleteAll();

  Future<({String? nome, String? tipo, int? userId})> getUserInfo() async {
    final results = await Future.wait([
      _storage.read(key: _keyNome),
      _storage.read(key: _keyTipo),
      _storage.read(key: _keyUserId),
    ]);
    final userIdStr = results[2];
    return (
      nome: results[0],
      tipo: results[1],
      userId: userIdStr != null ? int.tryParse(userIdStr) : null,
    );
  }
}
