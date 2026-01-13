import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String resolveBaseUrl() {
    const override = String.fromEnvironment('BACKEND_BASE_URL');
    if (override.isNotEmpty) return override;

    if (kIsWeb) return dotenv.env['BASE_URL1'] ?? 'http://localhost:3000';
    if (Platform.isAndroid) return  dotenv.env['BASE_URL1'] ?? 'http://localhost:3000';

    return 'http://localhost:3000';
  }

  static Uri join(String path) {
    final base = resolveBaseUrl();
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Uri.parse(path);
    }
    if (!path.startsWith('/')) {
      return Uri.parse('$base/$path');
    }
    return Uri.parse('$base$path');
  }
}


