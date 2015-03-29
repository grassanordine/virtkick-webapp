define(function(require) {
  var angular = require('angular');
  var moduleId = require('module').id;

  var app = angular.module(moduleId,
      [
        require('modules/common'),
        require('directives/ajaxloader/ajaxloader'),
        require('modules/machineService')
      ]
  );

  app.config(function($stateProvider) {
    $stateProvider
        .state('user.machines', {
          url: '/machines',
          abstract: true,
          template: '<div ui-view></div>'
        })
        .state('user.machines.index', {
          url: '',
          template: require('jade!./index'),
          controller: 'MachineIndex'
        });
  });

  app.controller('MachineIndex', function(machineService, $scope, $timeout, $state, $q) {
    $scope.app.header.title = 'Machines';
    $scope.app.header.icon = 'oi oi-monitor';

    $scope.app.action = {
      url: '/machines/new',
      title: 'Create a new machine',
      show: true
    };

    var abortRequest;

    $scope.$on('$stateChangeStart', function() {
      abortRequest = true;
      $scope.app.action.show = false;
    });

    $scope.state = {
      loading: true
    };

    $timeout(function() {
      machineService.index().then(function(data) {
        $scope.state.error = null;
        if(abortRequest) return;

        angular.extend($scope, data);
        $scope.state.loading = false;
      }).catch(function(err) {
        $scope.state.error = err;
      });
    }, 0);


  });

  return moduleId;

});