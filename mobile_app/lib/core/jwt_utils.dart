import 'dart:convert';

class JwtUtils {
  static bool isExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

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
      return DateTime.now().isAfter(
        expiry.subtract(const Duration(seconds: 30)),
      );
    } catch (_) {
      return true;
    }
  }
}
