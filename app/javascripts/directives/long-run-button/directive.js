define(function(require) {
  var module = require('module');
  var angular = require('angular');
  require('css!./style.css');


  function controller($scope, $q) {

    var outTimeout;

    $scope.startRun = function() {
      clearTimeout(outTimeout);
      $scope.longRunButton.loading = true;
      $scope.longRunButton.loadingVisible = true;
      $scope.longRunButton.loadingFinish = false;
      if($scope.running) {
        $scope.running = true;
      }

      $scope.longRunButton.afterRocketFlyOut = function() {
        setTimeout(function() {
          $scope.$apply(function() {
            $scope.longRunButton.loadingVisible = false;
          });
        }, 10);
      };

      var promise = $scope.run();

      var promiseHandler = function(data) {
        setTimeout(function() {
          $scope.$apply(function() {
            $scope.longRunButton.loadingFinish = true;
          });
        }, 10);

        outTimeout = setTimeout(function() {
          $scope.$apply(function() {
            $scope.longRunButton.loading = false;
            if($scope.running) {
              $scope.running = false;
            }
          });
        }, 150);
        $scope.onFinish(data);
      };

      $q.when(promise).then(promiseHandler);
    };
  }

  function link(scope, element, attrs) {
    scope.longRunButton = {
      size: attrs.size || 34,
      loading: false
    };
  }

  angular.module(module.uri, ['ui.bootstrap', require('directives/preloader/preloader')])
      .directive('longRunButton', function() {
        return {
          replace: true,
          transclude: true,
          restrict: 'E',
          scope: {
            running: '=',
            onError: '&',
            onFinish: '&',
            run: '&'
          },
          controller: controller,
          template: require('jade!./template')(),
          link: link
        };
      });
  return module.uri;
});