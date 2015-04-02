define(function(require) {
  require('appcommon');

  var angular = require('angular');
  var moduleId = require('module').id;

  var app = angular.module(moduleId, [
    require('modules/common'),
    require('directives/preloader/preloader'),
    require('directives/long-run-button/directive')
  ]);


  app.config(function($stateProvider) {
    $stateProvider .state('user.machines.new', {
      url: '/new',
      template: require('jade!./new'),
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

    $scope.app.header.title = 'Create new machine';
    $scope.app.header.icon = 'oi oi-monitor';

    $scope.plans = plansData;
    $scope.isos = isosData;

    $scope.imageTypes =  [['Mount ISO', 'isos'], ['Appliance', 'appliances'], ['1-Click App', 'apps']].map(function(elem) {
      return {
        name: elem[0],
        id: elem[1]
      }
    });

    $scope.newMachine = {
      // as iso is only available for now, make it default
      imageType: $scope.imageTypes[0].id
    };

    $scope.gotoMachine = function() {
      $state.go('user.machines.show.console', {
        machineId: $scope.newMachine.id
      });
    };

    $scope.createMachine = function() {
      $scope.newMachine.error = null;
      return $hook('createMachine').then(function() {
        return machineService.createMachine({
          hostname: $scope.newMachine.hostname,
          planId: $scope.newMachine.planId,
          imageType: $scope.newMachine.imageType,
          isoId: $scope.newMachine.isoId
        });
      }).then(function(data) {
        $scope.newMachine.id = data.machineId;
      }).catch(function(err) {
        if(err === 'cancel' || err === 'backdrop click') {
          throw err;
        }
        // TODO: fix up error handling
        if(err.data && (err.data.message || err.data.errors)) {
          err = err.data;
        }
        $scope.newMachine.error = err.message || err;
        throw err;
      });
    };
  });
  return moduleId;
});
