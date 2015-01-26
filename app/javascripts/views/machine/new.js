define(function(require) {
  require('appcommon');
  var $ = require('jquery');

  var handleProgress = require('handleProgress');

  var angular = require('angular');
  require('angular-messages'); // for ngMessages
  require('ui-bootstrap');

  var app = angular.module('app', ['ui.bootstrap', 'ngMessages', require('directives/preloader/preloader')]);


  var machineProgress =  function(progressId, onSuccess) {
    var id = setInterval(function() {
      return $.ajax('/machine_progress/' + progressId).success(function(data) {
        if (!data.finished) {
          return;
        }
        clearInterval(id);

        onSuccess(data);
      });
    }, 500);
  };

  app.controller('AppCtrl', function($scope) {
    $scope.data = {
      menuCollapse: false
    };
  });

  require('csrfSetup')(app);


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
            $http.post('/machines',  {machine: {
              hostname: modelValue
            }}).success(function(arg) {
              resolve();
            }).error(function(arg) {
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

  app.controller('NewMachineCtrl', function($scope) {
    $scope.data = {};


    $scope.gotoMachine = function() {
      window.location.href = '/machines/' + $scope.data.createdMachineId;
    };

    $scope.createMachine = function(cb) {
      $.ajax({
        url: '/machines',
        type: 'POST',
        data: {
          machine: {
            hostname: $scope.data.hostname,
            plan_id: $scope.data.planId,
            image_type: $scope.data.imageType,
            iso_distro_id: $scope.data.isoId
          }
        },
        dataType: "json",
        success: function(data) {
          $scope.$apply(function() {
            $scope.data.creatingMachine = true;
          });
          machineProgress(data.data, function(data) {
            console.log("Succeed", data);
            $scope.$apply(function() {
              $scope.data.createdMachineId = data.given_meta_machine_id;
              $scope.data.creatingMachineFinished = true;
            });

          });

          if(cb) cb(null, data);
        },
        error: function(err) {
          if(cb) cb(err);
        }
      });
    };

  });

  angular.element().ready(function() {
    angular.bootstrap(document, ['app']);
  });
});
