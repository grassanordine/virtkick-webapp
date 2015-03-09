define(function(require) {
  require('appcommon');

  var angular = require('angular');

  var app = angular.module('app',
      [
        require('./angular-bootstrap-checkbox'),
        require('./modules/helpers')
      ]
  );

  app.controller('SignUpCtrl', function($scope) {
  });


  angular.element().ready(function() {
    angular.bootstrap(document, ['app']);
    try {
      angular.bootstrap(document, ['app']);
    } catch(err) { }
  });

});
