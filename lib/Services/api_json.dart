import 'dart:convert';

import 'package:http/http.dart' as http;

dynamic decodeJsonResponse(http.Response response) {
  return jsonDecode(utf8.decode(response.bodyBytes));
}

String decodeResponseBody(http.Response response) {
  return utf8.decode(response.bodyBytes);
}
