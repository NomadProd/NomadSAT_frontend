import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;

/// Cookie auth: every request must carry the HTTP-only `access_token` cookie.
http.Client createAuthedClient() => BrowserClient()..withCredentials = true;
