define(function(require) {
  require('appcommon');
  var extraModules = document.getElementsByClassName('inject_module');

  var angular = require('angular');

  var extraModules = [];
  angular.element('script.inject-module').each(function() {
    extraModules.push(JSON.parse(this.innerHTML));
  });

  require(extraModules, function() {
    var moduleAngularDeps = Array.prototype.slice.call(arguments);

    var app = angular.module('app',
        [
          require('views/machine/index'),
          require('views/machine/show'),
          require('views/machine/new')
        ].concat(moduleAngularDeps)
    );

    app.config(function($urlMatcherFactoryProvider, $locationProvider, $stateProvider, $urlRouterProvider) {
      $locationProvider.html5Mode(true);

      $urlRouterProvider.otherwise("/machines");

      $stateProvider
          .state('logout', {
            url: '^/users/sign_out',
            template: require('jade!templates/logout'),
            controller: function($timeout, $window, $scope) {
              $scope.app.header = {
                title: 'Signing out',
                icon: 'fa-sign-out'
              };
              var timer = $timeout(function() {
                $window.location = '/users/sign_out';
              }, 0);
              $scope.$on('$destroy', function() {
                $timeout.cancel(timer);
              });
            }
          });


    });

    app.controller('AppCtrl', function($scope, $state, $rootScope) {

      $scope.$state = $state;

      $scope.primaryState = '';

      $rootScope.$on('$stateChangeStart',
          function(event, toState, toParams, fromState, fromParams) {
            $scope.primaryState = toState.name.split('.')[0];

          });

      $scope.app = {
        header: {
          title: '',
          icon: ''
        },
        menuCollapse: false
      };
    });


    angular.element().ready(function() {
      angular.bootstrap(document, ['app']);
      try {
        angular.bootstrap(document, ['app']);
      } catch(err) { }
    });
  });

});
