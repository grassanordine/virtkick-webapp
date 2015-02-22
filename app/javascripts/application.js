define(function(require) {
  require('appcommon');
  var angular = require('angular');

  var app = angular.module('app',
      [
        require('views/machine/index'),
        require('views/machine/show'),
        require('views/machine/new')

      ]
  );

  app.config(function($locationProvider) {
    $locationProvider.html5Mode(true);
  });

  app.controller('AppCtrl', function($scope) {
    console.log("App controller");
    $scope.data = {
      menuCollapse: false
    };
  });


  angular.element().ready(function() {
    angular.bootstrap(document, ['app']);
  });
});
