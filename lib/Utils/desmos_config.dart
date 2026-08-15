/// Desmos Graphing Calculator API (v1.13).
///
/// Get a production key at https://www.desmos.com/my-api (free for personal /
/// educational projects). Override at build time:
/// `--dart-define=DESMOS_API_KEY=your_key`
///
/// The default is Desmos's documented demo key, suitable for local/dev use.
/// Do not strip Desmos branding from the embed (API Terms §5.b).
const kDesmosApiVersion = 'v1.13';
const kDesmosApiKey = String.fromEnvironment(
  'DESMOS_API_KEY',
  defaultValue: '542ecf4c02af4fa7bbb6b4f945779357',
);

const kDesmosCalculatorHint =
    'Calculator and reference sheet now available';

String desmosCalculatorHtml({String apiKey = kDesmosApiKey}) {
  final version = kDesmosApiVersion;
  return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
  <style>
    html, body, #calculator {
      margin: 0;
      padding: 0;
      width: 100%;
      height: 100%;
      overflow: hidden;
      background: #fff;
    }
  </style>
</head>
<body>
  <div id="calculator"></div>
  <script>
    (function () {
      var script = document.createElement('script');
      script.src = 'https://www.desmos.com/api/$version/calculator.js?apiKey=' +
        encodeURIComponent(${_jsString(apiKey)});
      script.onload = function () {
        var elt = document.getElementById('calculator');
        window.calculator = Desmos.GraphingCalculator(elt, {
          keypad: true,
          expressions: true,
          settingsMenu: true,
          zoomButtons: true,
          border: false,
          autosize: true
        });
      };
      document.head.appendChild(script);
    })();
  </script>
</body>
</html>
''';
}

String _jsString(String value) {
  return "'${value.replaceAll(r'\', r'\\').replaceAll("'", r"\'")}'";
}
