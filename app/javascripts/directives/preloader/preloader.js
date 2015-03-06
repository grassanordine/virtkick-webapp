define(function(require) {
  var moduleId = require('module').id;
  var angular = require('angular');
  var css = require('css!./preloader.css');

  function link(scope, rocketContext, attrs) {

    scope.size = attrs.size || 40;

    var rocket = rocketContext[0].getElementsByClassName('preloader-rocket-wrapper')[0];

    var flyIn = function() {
      setTimeout(function() {
        rocket.setAttribute('class', 'preloader-rocket-wrapper');
        setTimeout(function() {
          rocket.setAttribute('class', 'preloader-rocket-wrapper animate');
        }, 450);
      }, 50);
    };

    var flyOut = function(callback) {
      rocket.setAttribute('class', 'preloader-rocket-wrapper flyover animate');
      setTimeout(function() {
        rocket.setAttribute('class', 'preloader-rocket-wrapper flyover');
        if (callback) {
          callback();
        }
      }, 1000);
    };

    scope.$watch('loading', function(cur, prev) {
      if(prev == cur) return;
      if(cur === true) {
        flyIn();
      }
    });

    scope.$watch('finish', function(cur, prev) {
      if(prev == cur) return;
      if(cur === true) {
        flyOut(function() {
          scope.afterFinish();
        });
      }
    });

    if(attrs.started)
      flyIn();
  }

  function controller($scope) {
    $scope.size = 40;
  }

  angular.module(moduleId, []).directive('preloader', function() {
    return {
      replace: true,
      link: link,
      restrict: 'E',
      controller: controller,
      scope: {
        'loading': '=',
        'finish': '=',
        'afterFinish': '&'
      },
      template: require('jade!./preloader')()
    }
  });
  return moduleId;
});