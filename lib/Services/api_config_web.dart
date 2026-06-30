import 'dart:html' as html;

/// Private / LAN hosts used during local dev (phone on same Wi‑Fi, etc.).
bool _isLocalDevHost(String host) {
  if (host == 'localhost' || host == '127.0.0.1' || host == '0.0.0.0') {
    return true;
  }

  final parts = host.split('.');
  if (parts.length != 4) return false;

  final octets = <int>[];
  for (final part in parts) {
    final value = int.tryParse(part);
    if (value == null || value < 0 || value > 255) return false;
    octets.add(value);
  }

  // 10.0.0.0/8
  if (octets[0] == 10) return true;
  // 172.16.0.0/12
  if (octets[0] == 172 && octets[1] >= 16 && octets[1] <= 31) return true;
  // 192.168.0.0/16
  if (octets[0] == 192 && octets[1] == 168) return true;

  return false;
}

String? localDevApiBaseUrl() {
  final host = html.window.location.hostname;
  if (host == null || host.isEmpty) return null;
  if (_isLocalDevHost(host)) {
    // Keep the same hostname as the page so auth cookies are same-site.
    return 'http://$host:8000';
  }
  return null;
}
