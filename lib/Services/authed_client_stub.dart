import 'package:http/http.dart' as http;

/// Non-web fallback so this app's services can be imported from VM tests.
/// The real app always resolves to the web implementation.
http.Client createAuthedClient() => http.Client();
