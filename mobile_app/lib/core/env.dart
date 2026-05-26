import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8080';

  static String get mapsApiKey => dotenv.env['MAPS_API_KEY'] ?? '';

  static String rewriteMediaUrl(String url) {
    if (!url.contains('localhost')) return url;
    final uri = Uri.tryParse(baseUrl);
    if (uri == null) return url;
    return url.replaceFirst('localhost', uri.host);
  }
}
