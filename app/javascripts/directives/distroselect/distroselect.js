define(function(require) {
  var moduleId = require('module').id;
  var angular = require('angular');
  var css = require('css!./distroselect.css');

  require('angular-sanitize');

  require('ui-select');

  function controller($scope) {
    $scope.isoImages = $scope.$parent.isoImages;
    $scope.idToCode = $scope.$parent.idToCode;

    $scope.state = {
      mountingIso: false
    };

    $scope.changeIso = function(imageId) {
      $scope.state.mountingIso = true;
      return $scope.machine.changeIso(imageId).then(function() {
        $scope.state.mountingIso = false;
      }, function() {
        $scope.state.mountingIso = false;
      });
    };

  }

  function link(scope, element, attrs) {
    scope.width = attrs.width || 'auto';
  }

  angular.module(moduleId, ['ngSanitize', 'ui.select'])
  .directive('distroselect', function() {
    return {
      replace: true,
      transclude: true,
      restrict: 'E',
      scope: {
        machine: '='
      },
      controller: controller,
      template: require('jade!./distroselect')(),
      link: link
    };
  });
  return moduleId;
});