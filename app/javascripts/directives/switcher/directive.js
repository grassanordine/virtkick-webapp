define(function(require) {
  var moduleId = require('module').id;
  var angular = require('angular');
  require('css!./style.css');

  function controller($scope, $q) {
    $scope.switch = function() {
      if ($scope.switcher.activeOption.position == 'left') {
        $scope.set($scope.switcher.options[1]);
      } else {
        $scope.set($scope.switcher.options[0]);
      }
    }

    $scope.set = function (option) {
      $scope.switcher.activeOption = option;
    }
  }

  function link(scope, element, attrs) {
    scope.switcher = scope.$parent.switcher;
    scope.switcher.options[0].position = 'left';
    scope.switcher.options[1].position = 'right';
    scope.switcher.activeOption = scope.switcher.options[0];
  }

  angular.module(moduleId, [])
      .directive('switcher', function() {
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