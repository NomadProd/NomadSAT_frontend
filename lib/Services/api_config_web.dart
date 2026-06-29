import 'dart:html' as html;

String? localDevApiBaseUrl() {
  final host = html.window.location.hostname;
  if (host == 'localhost' || host == '127.0.0.1') {
    return 'http://localhost:8000';
  }
  return null;
}
