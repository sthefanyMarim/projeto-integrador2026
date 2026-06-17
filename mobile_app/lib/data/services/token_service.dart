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
  static const _keyDeviceId = 'device_id';

  Future<void> saveTokens(LoginResponse response) async {
    await Future.wait([
      _storage.write(key: _keyAccess, value: response.accessToken),
      _storage.write(key: _keyRefresh, value: response.refreshToken),
      saveUserIdentity(
        nome: response.nome,
        userId: response.userId,
        tipo: response.tipo.name,
      ),
    ]);
  }

  Future<String?> getAccessToken() => _storage.read(key: _keyAccess);
  Future<String?> getRefreshToken() => _storage.read(key: _keyRefresh);

  Future<String> getOrCreateDeviceId() async {
    final existing = await _storage.read(key: _keyDeviceId);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final created = 'device-${DateTime.now().microsecondsSinceEpoch}';
    await _storage.write(key: _keyDeviceId, value: created);
    return created;
  }

  Future<bool> hasTokens() async {
    final token = await _storage.read(key: _keyAccess);
    return token != null && token.isNotEmpty;
  }

  Future<void> saveUserIdentity({
    required String nome,
    required int userId,
    required String tipo,
  }) async {
    await Future.wait([
      _storage.write(key: _keyNome, value: nome),
      _storage.write(key: _keyUserId, value: userId.toString()),
      _storage.write(key: _keyTipo, value: tipo),
    ]);
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
