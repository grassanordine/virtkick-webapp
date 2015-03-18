define(function(require) {
  var moduleId = require('module').id;
  var angular = require('angular');

  var app = angular.module(moduleId, [
    require('views/machine/index'),
    require('views/machine/show'),
    require('views/machine/new'),
    require('directives/switcher/directive')
  ]);

  app.config(function($urlMatcherFactoryProvider, $locationProvider, $stateProvider, $urlRouterProvider) {
    $stateProvider
      .state('user', {
        url: '',
        template: require('jade!./userLayout'),
        controller: 'UserCtrl'
      });
  });

  app.controller('UserCtrl', function($scope, $hook, $state, virtkickMode) {
    $scope.user = {
      navbarLinks: [],
      logoutAvailable: virtkickMode !== 'localhost'
    };
    $hook('UserCtrl', {$scope: $scope});

    $scope.$on('$stateChangeSuccess', function(state, toState) {
      if(toState.name == 'user') {
        $state.go('user.machines.index');
      }
    });
  });

  return moduleId;
});