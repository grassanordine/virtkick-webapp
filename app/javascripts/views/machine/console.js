define(function(require) {
  var moduleId = require('module').id;
  var angular = require('angular');
  var $ = require('jquery');

  function controller($scope, $interval, $location) {
    $scope.interface = {};

    $scope.display =  { height: 605, fitTo: 'height', fullScreen: false };

    $scope.vncHost = $location.host();
    $scope.vncPort = $location.port();

    $scope.ungrab = function() {
      $scope.interface.rfb.get_keyboard().set_focused(false)
      $scope.interface.rfb.get_mouse().set_focused(false)
      $scope.focused = false;
    };
    $scope.grab = function() {
     $scope.interface.rfb.get_keyboard().set_focused(true);
     $scope.interface.rfb.get_mouse().set_focused(true);
     $scope.focused = true;
    };
    $scope.sendCtrlAltDel = function() {
      $scope.interface.sendCtrlAltDel();
    };

    var reconnectTimeout = $interval(function() {

      if($scope.state.status == 'running' &&
          $scope.interface.rfb_state == 'disconnected') {
        $scope.interface.connect()
      }
    }, 500);

    if($scope.control) {
      $scope.control.sendCtrlAltDel = function() {
        $scope.interface.sendCtrlAltDel();
      };
      $scope.control.fullScreen = function() {
        $scope.display.fullScreen = !$scope.display.fullScreen;
      };
    }

    $scope.$on('$destroy', function() {
      $interval.cancel(reconnectTimeout);
    });
  }

  angular.module(moduleId, [require('directives/preloader/preloader')]).directive('console', function() {
    return {
      replace: true,
      restrict: 'E',
      scope: {
        focused: '=',
        state: '=',
        control: '=',
        password: '@'
      },
      controller: controller,
      template: require('jade!./console')
    }
  });
  return moduleId

});