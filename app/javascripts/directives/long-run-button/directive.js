define(function(require) {
  var moduleId = require('module').id;
  var angular = require('angular');
  require('css!./style.css');
  require('ui-bootstrap');

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
      if($scope.runningAnimation) {
        $scope.runningAnimation = true;
      }

      var promise = $scope.run();

      var estimated = (new Date()).getTime() + 500;

      $scope.longRunButton.afterRocketFlyOut = function() {
        setTimeout(function() {
          $scope.$apply(function() {
            $scope.longRunButton.loadingVisible = false;
            if($scope.runningAnimation) {
              $scope.runningAnimation = false;
            }
            $scope.onFinishAnimation();
          });
        }, 5);
      };

      var promiseHandler = function(onFinish) {
        var func = function(data) {
          var currentTime = (new Date()).getTime();
          if (currentTime < estimated) {
            setTimeout(function() {

              func(data);
            }, estimated - currentTime);
            return;
          }

          setTimeout(function() {
            $scope.$apply(function() {
              $scope.longRunButton.loadingFinish = true;
            });
          }, 10);

          outTimeout = setTimeout(function() {
            $scope.$apply(function() {
              $scope.longRunButton.loading = false;
              if ($scope.running) {
                $scope.running = false;
              }
            });
          }, 330);
          onFinish(data);
        };
        return func;
      }

      $q.when(promise).then(promiseHandler(function(data) {
        $scope.onFinish(data);
      }), function(data) {
        $scope.longRunButton.loadingFinish = true;
        $scope.longRunButton.loading = false;
        $scope.longRunButton.loadingVisible = false;
        if($scope.runningAnimation) {
          $scope.runningAnimation = false;
        }
        if($scope.running) {
          $scope.running = false;
        }
        if($scope.$parent) {
          $scope.$parent.$error = data;
        }
        $scope.onError(data);
      });
    };
  }

  function link(scope, element, attrs) {
    scope.longRunButton = {
      size: attrs.size || 34,
      loading: false
    };
  }

  angular.module(moduleId, ['ui.bootstrap', require('directives/preloader/preloader')])
      .directive('longRunButton', function() {
        return {
          replace: true,
          transclude: true,
          restrict: 'E',
          scope: {
            running: '=',
            runningAnimation: '=',
            onError: '&',
            onFinish: '&',
            onFinishAnimation: '&',
            run: '&'
          },
          controller: controller,
          template: require('jade!./template')(),
          link: link
        };
      });
  return moduleId;
});