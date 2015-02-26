define(function(require) {
  require('appcommon');

  var angular = require('angular');
  var moduleUri = require('module').uri;

  var app = angular.module(moduleUri, [
    require('modules/common'),
    require('directives/preloader/preloader'),
    require('directives/long-run-button/directive')
  ]);


  app.config(function($stateProvider) {
    $stateProvider
        .state('machines.new', {
          url: '/new',
          template: require('jade!templates/machine/new'),
          controller: 'NewMachineCtrl'
        });


  });

  // directive for checking validity of the form
  // this will be wrapped in something nicer in the future :)
  app.directive('machineName', function($q, $http, machineService) {
    return {
      require: 'ngModel',
      link: function(scope, elm, attrs, ctrl) {
        ctrl.$asyncValidators.machine = function(modelValue, viewValue) {

          var cleanErrors = function() {
            // cache set errors
            ctrl.errors = ctrl.errors || {};
            Object.keys(ctrl.errors).forEach(function(error) {
              ctrl.$setValidity(error, true);
              delete ctrl.errors[error];
            });
            ctrl.$setValidity('any', true);
          };

          return machineService.validateHostname(modelValue).finally(cleanErrors)
              .catch(function(errors) {
                ctrl.$setValidity('any', false);
                errors.forEach(function(error) {
                  ctrl.errors[error] = true;
                  ctrl.$setValidity(error, false);
                });
              });
        };
      }
    };
  });

  app.controller('NewMachineCtrl', function($scope, $q, $http,
                                            plansData,
                                            isosData,
                                            $timeout,
                                            $hook, $state, machineService) {
    $scope.plans = plansData;
    $scope.isos = isosData;

    $scope.imageTypes =  [['Mount ISO', 'isos'], ['Appliance', 'appliances'], ['1-Click App', 'apps']].map(function(elem) {
      return {
        name: elem[0],
        id: elem[1]
      }
    });

    $scope.data = {};

    $scope.gotoMachine = function() {
      $state.go('machines.show', {
        machineId: $scope.data.createdMachineId
      });
    };

    $scope.createMachine = function() {

      return $hook('createMachine').then(function() {
        return machineService.createMachine({
          hostname: $scope.data.hostname,
          planId: $scope.data.planId,
          imageType: $scope.data.imageType,
          isoId: $scope.data.isoId
        }).then(function(machineId) {
          $scope.data.createdMachineId = machineId
        });
      });
    };
  });
  return moduleUri;
});
