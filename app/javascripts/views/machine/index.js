define(function(require) {
  var angular = require('angular');
  var moduleUri = require('module').uri;

  var app = angular.module(moduleUri,
      [
        require('modules/common'),
        require('directives/ajaxloader/ajaxloader'),
        require('modules/machineService')
      ]
  );

  app.config(function($stateProvider) {
    $stateProvider
        .state('index', {
          url: '/',
          template: require('jade!templates/machine/index'),
          controller: 'MachineIndex'
        });
  });

  app.controller('MachineIndex', function(machineService, $scope, $timeout, $state) {
    $scope.state = {
      loading: true
    };

    machineService.index().then(function(data) {
      angular.extend($scope, data);
      console.log(data);
      $scope.state.loading = false;
    });

  });

  return moduleUri;

});