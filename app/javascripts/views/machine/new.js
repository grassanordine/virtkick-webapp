define(function(require) {
  require('appcommon');

  var angular = require('angular');

  var app = angular.module('app', [
    require('modules/common'),
    require('directives/preloader/preloader'),
    require('directives/long-run-button/directive')
  ]);

  // directive for checking validity of the form
  // this will be wrapped in something nicer in the future :)
  app.directive('machine', function($q, $http) {
    return {
      require: 'ngModel',
      link: function(scope, elm, attrs, ctrl) {
        ctrl.$asyncValidators.machine = function(modelValue, viewValue) {
          return $q(function(resolve, reject) {
            if(typeof modelValue == 'undefined') {
              return reject();
            }
            $http.post('/machines',  {
              validate: true,
              machine: {
              hostname: modelValue
            }}).success(function(arg) {
              resolve();

              // cache set errors
              ctrl.errors = ctrl.errors || {};
              Object.keys(ctrl.errors).forEach(function(error) {
                ctrl.$setValidity(error, true);
                delete ctrl.errors[error];
              });
              if(arg.errors.hostname) {
                ctrl.$setValidity('any', false);
                arg.errors.hostname.forEach(function(error) {
                  ctrl.errors[error] = true;
                  ctrl.$setValidity(error, false);
                });


                return reject(arg.errors.hostname);
              } else {
                ctrl.$setValidity('any', true);
              }

              resolve();
            });
          });
        };
      }
    };
  });

  app.controller('NewMachineCtrl', function($scope, $q, $http,
                                            plansData,
                                            isosData,
                                            $timeout, $hook) {
    $scope.plans = plansData;
    $scope.isos = isosData;

    $scope.imageTypes =  [['Mount ISO', 'isos'], ['Appliance', 'appliances'], ['1-Click App', 'apps']].map(function(elem) {
      return {
        name: elem[0],
        id: elem[1]
      }
    });

    var machineProgress =  function(progressId) {
      function doQuery() {
        return $http.get('/machine_progress/' + progressId).then(function(res) {
          if (!res.data.finished) {
            return $timeout(doQuery, 250);
          }
          return res.data;
        });
      }
      return $timeout(doQuery, 250);
    };

    $scope.data = {};

    $scope.gotoMachine = function() {
      window.location.href = '/machines/' + $scope.data.createdMachineId;
    };

    $scope.createMachine = function() {
      function create() {
        return $http.post('/machines', {
          machine: {
            hostname: $scope.data.hostname,
            plan_id: $scope.data.planId,
            image_type: $scope.data.imageType,
            iso_distro_id: $scope.data.isoId
          }
        }).then(function(data) {
          return machineProgress(data.data.data).then(function(data) {
            $scope.data.createdMachineId = data.given_meta_machine_id;
          });
        });
      }
      return $hook('createMachine').then(create);
    };
  });


  angular.element(document).ready(function() {
      angular.bootstrap(document, ['app']);
      try {
        angular.bootstrap(document, ['app']);
      } catch(err) {
      }
  });
});
