import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web/Services/api_json.dart';
import 'package:http/http.dart' as http;

http.Response _response(String body, {int status = 200}) {
  return http.Response(body, status, headers: {'content-type': 'application/json'});
}

void main() {
  tearDown(() {
    onUnauthorized = null;
  });

  test('decodes JSON bodies', () {
    final data = decodeJsonResponse(_response('{"ok": true}'));
    expect(data, {'ok': true});
  });

  test('rejects HTML and empty bodies with a stable message', () {
    expect(
      () => decodeJsonResponse(_response('<html>bad gateway</html>', status: 502)),
      throwsA(isA<ApiException>()),
    );
    expect(
      () => decodeJsonResponse(_response('   ')),
      throwsA(isA<ApiException>()),
    );
  });

  test('401 triggers redirect callback and UnauthenticatedException', () {
    var redirected = false;
    onUnauthorized = () => redirected = true;
    expect(
      () => decodeJsonResponse(_response('{"detail":"Not authenticated"}', status: 401)),
      throwsA(isA<UnauthenticatedException>()),
    );
    expect(redirected, isTrue);
  });

  test('login 401 does not redirect when handleUnauthorized is false', () {
    var redirected = false;
    onUnauthorized = () => redirected = true;
    final data = decodeJsonResponse(
      _response('{"detail":"Invalid credentials"}', status: 401),
      handleUnauthorized: false,
    );
    expect(redirected, isFalse);
    expect(apiDetailMessage(data), 'Invalid credentials');
  });

  test('flattens FastAPI validation detail lists', () {
    expect(
      apiDetailMessage({
        'detail': [
          {'msg': 'due_date is required'},
          {'msg': 'due_time is required'},
        ],
      }),
      'due_date is required due_time is required',
    );
  });

  test('userFacingError hides raw client exceptions', () {
    expect(
      userFacingError(Exception('ClientException: XMLHttpRequest error.')),
      'Could not connect to the server. Check your internet connection.',
    );
    expect(
      userFacingError(Exception('Not authenticated')),
      'Please sign in again.',
    );
  });
}
