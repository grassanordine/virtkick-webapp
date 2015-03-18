define(function(require) {
  var moduleId = require('module').id;
  var angular = require('angular');
  require('css!./style.css');

  function link(scope, element, attrs, ngModel) {
    scope.switcher = {};
    scope.switcher.activeOption = ngModel.$modelValue;

    scope.switch = function(val) {
      if(typeof val !== 'undefined') {
        ngModel.$setViewValue(val);
        scope.switcher.activeOption = val;
        return;
      }
      ngModel.$setViewValue(!scope.switcher.activeOption);
      scope.switcher.activeOption = !scope.switcher.activeOption;
    };

    ngModel.$render = function() {
      scope.switcher.activeOption = ngModel.$modelValue;
    };
  }

  angular.module(moduleId, [])
      .directive('switcher', function() {
        return {
          replace: true,
          transclude: true,
          restrict: 'E',
          require: 'ngModel',
          scope: {
            left: '@',
            right: '@',
            leftIcon: '@',
            rightIcon: '@'
          },
          template: require('jade!./template')(),
          link: link
        };
      });
  return moduleId;
});