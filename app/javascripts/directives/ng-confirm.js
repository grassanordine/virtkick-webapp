define(function(require) {
  var module = require('module');
  var angular = require('angular');


  require('ui-bootstrap');

  angular.module(module.uri, ['ui.bootstrap'])
  .directive('confirm', function($modal) {
    return {
      restrict: 'A',
      scope: {
        'action': '&',
        'text': '@confirm',
        'title': '@title'
      },
      link: function(scope, elem, attrs) {
        //scope.machine = scope.$parent.machine;
        console.log("MACHINE", scope.$parent.machine);
        elem.on('click', function() {
          var modalInstance = $modal.open({
            template: require('jade!./ng-confirm'),
            controller: function($scope, $modalInstance, text, title) {
              $scope.text = text;
              $scope.title = title;
              $scope.ok = function () {
                $modalInstance.close(/*$scope.text*/);
              };
              $scope.cancel = function () {
                $modalInstance.dismiss('cancel');
              };
            },
            resolve: {
              text: function () {
                return scope.text;
              },
              title: function () {
                return scope.title;
              }
            }
          });
          modalInstance.result.then(function (/*text*/) {
            console.log("ACTION");
            scope.action();
          }, function () {
          });
        });
      }
    };
  });
  return module.uri;
});