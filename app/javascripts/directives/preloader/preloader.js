define(function(require) {
  var module = require('module');
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


    flyIn();

    setTimeout(function() {
      //flyOut(function () {
      //location.reload(true);
      //});
    }, 5000);
  }

  function controller($scope) {
    $scope.size = 40;
  }

  angular.module(module.uri, []).directive('preloader', function() {
    return {
      replace: true,
      link: link,
      restrict: 'E',
      controller: controller,
      scope: {},
      template: require('jade!./preloader')()
    }
  });
  return module.uri;
});