define(function(require) {
  var $ = require('jquery');

  $.ajaxSetup({
    headers: {
      'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')
    }
  });

  return function(app) {
    app.config(function($httpProvider) {
      $httpProvider.defaults.headers.common['X-CSRF-Token'] = $('meta[name=csrf-token]').attr('content')
      $httpProvider.defaults.headers.common['Accept'] = 'application/json';

    });
  };
});