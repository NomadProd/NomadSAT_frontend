import 'api_config_local.dart' if (dart.library.html) 'api_config_web.dart';

class ApiConfig {
  static const _rawBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get baseUrl => _resolveBaseUrl();

  static String _resolveBaseUrl() {
    final fromEnv = _rawBaseUrl.trim();
    if (fromEnv.isNotEmpty) {
      return _stripTrailingSlash(fromEnv);
    }

    final localDevUrl = localDevApiBaseUrl();
    if (localDevUrl != null) {
      return localDevUrl;
    }

    return 'https://api.turansat.com';
  }

  static String _stripTrailingSlash(String value) {
    if (value.endsWith('/')) {
      return value.substring(0, value.length - 1);
    }
    return value;
  }
}
