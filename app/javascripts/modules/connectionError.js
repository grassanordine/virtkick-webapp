define(function(require) {
  var moduleId = require('module').id;
  var angular = require('angular');

  var mod = angular.module(moduleId, [require('directives/preloader/preloader')]);

  mod.config(function($httpProvider) {
    $httpProvider.interceptors.push(function(connectionErrorService) {
      return {
        responseError: function(rejection) {
          return connectionErrorService(rejection);
        }
      }
    });
  });

  mod.service('connectionErrorService', function($q, $injector, $location) {
    var modalIsOpen;
    return function(rejection) {
      var $modal = $injector.get('$modal');

      var blockInteraction = false;
      var status;
      // assure the failure was in connecting to local API
      var parser = document.createElement('a')
      parser.href = rejection.config.url;

      var host = parser.host;
      var protocol = parser.protocol;
      if(modalIsOpen || parser.pathname == '/api/ping' ||  protocol != window.location.protocol || host != window.location.host) {
        return $q.reject(rejection);
      }

      switch(rejection.status) {
        case 0:
          status = 'connectionError';
          blockInteraction = true;
          break;
        case 401:
          status = 'authError';
          blockInteraction = true;
          break;
        default:
          return $q.reject(rejection);
      }


      $modal.open({
        template: require('jade!views/connectionError'),
        controller: function($scope, $modalInstance, $timeout) {
          $scope.logout = function() {
            window.location.href = '/';
          };

          modalIsOpen = true;
          $scope.$on('$destroy', function() {
            modalIsOpen = false;
          });

          var $http = $injector.get('$http');
          function checkPing() {
            return $http.get('/api/ping').then(function() {
              var $state = $injector.get('$state');
              $state.go($state.current.name, {}, {reload: true});
              $modalInstance.close();
            }, function() {
              $timeout(checkPing, 3000);
            });
          }
          if(status === 'connectionError') {
            $timeout(checkPing, 3000);
          }
          $scope.status = status;
        },
        backdrop: blockInteraction?'static':undefined,
        keyboard: !blockInteraction
      });

      return $q.reject(rejection);
    }
  });


  return moduleId;
});