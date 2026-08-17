(function () {
  var params = new URLSearchParams(window.location.search);
  var apiKey = params.get('apiKey') || 'dcb31709b452b1cf9dc26972add0fda6';
  var script = document.createElement('script');
  script.src = 'https://www.desmos.com/api/v1.13/calculator.js?apiKey=' +
    encodeURIComponent(apiKey);
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
