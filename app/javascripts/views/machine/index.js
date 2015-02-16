define(function(require) {
  require('appcommon');
  var angular = require('angular');

  var app = angular.module('app',
      [
        require('modules/common'),
        require('directives/ajaxloader/ajaxloader')
      ]
  );

  app.controller('MachineList', function($http, $scope) {
    $scope.state = {
      loading: true
    };
    $http.get('/machines.json').then(function(res) {
      angular.extend($scope, res.data);
      $scope.state.loading = false;
    });

  });

  angular.element().ready(function() {
    angular.bootstrap(document, ['app']);
  });

});