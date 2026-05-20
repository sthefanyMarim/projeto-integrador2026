import 'dart:convert';

class JwtUtils {
  /// Retorna true se o token está expirado ou inválido.
  static bool isExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      // Base64url → Base64 com padding correto
      var payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      switch (payload.length % 4) {
        case 2:
          payload += '==';
        case 3:
          payload += '=';
      }

      final decoded = utf8.decode(base64.decode(payload));
      final claims = jsonDecode(decoded) as Map<String, dynamic>;

      final exp = claims['exp'];
      if (exp == null) return false;

      final expiry = DateTime.fromMillisecondsSinceEpoch((exp as int) * 1000);
      // Margem de 30s para evitar race condition
      return DateTime.now().isAfter(expiry.subtract(const Duration(seconds: 30)));
    } catch (_) {
      return true;
    }
  }
}
