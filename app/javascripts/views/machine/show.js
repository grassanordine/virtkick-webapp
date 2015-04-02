define(function(require) {
  require('appcommon');
  require('!domReady');

  var angular = require('angular');
  require('angular-route');

  var moduleId = require('module').id;
  var app = angular.module(moduleId,
    [
      require('modules/handleProgress'),
      require('modules/machineService'),
      require('modules/common'),
      require('directives/ng-confirm'),
      'ngRoute',
      require('angular-ui-router'),
      require('./console'),
      require('angular-noVNC'),
      require('directives/distroselect/distroselect'),
      require('directives/ajaxloader/ajaxloader'),
      require('directives/long-run-button/directive')
    ]
  );
  var moment = require('moment');


  app.controller('PowerCtrl', function($scope) {
  });
  app.controller('ConsoleCtrl', function($scope) {
  });
  app.controller('StorageCtrl', function($scope) {
    $scope.storage = {
      newDiskType: $scope.diskTypes[0],
      newDiskPlan: $scope.diskPlans[$scope.diskTypes[0].id][0],
      showDetails: false
    };
  });
  app.controller('SettingsCtrl', function($scope) {
  });


  app.config(function($stateProvider) {

    $stateProvider
        .state('user.machines.show', {
          url: '/{machineId:[0-9]{1,8}}',
          resolve: {
            initialMachineData: function($stateParams, machineService) {
              if($stateParams.machine) {
                return $stateParams.machine;
              }
              return machineService.get($stateParams.machineId);
            }
          },
          template: require('jade!./show'),
          controller: 'ShowMachineCtrl'
        })
        .state('user.machines.show.power', {
          url: '',
          template: require('jade!./powerView'),
          controller: 'PowerCtrl'
        })
        .state('user.machines.show.console', {
          url: '/console',
          sticky: true,
          views: {
            'console@user.machines.show': {
              template: require('jade!./consoleView'),
              controller: 'ConsoleCtrl'
            }
          }
        })
        .state('user.machines.show.storage', {
          url: '/storage',
          template: require('jade!./storageView'),
          controller: 'StorageCtrl'
        })
        .state('user.machines.show.settings', {
          url: '/settings',
          template: require('jade!./settingsView'),
          controller: 'SettingsCtrl'
        });
  });



  app.controller('ShowMachineCtrl',
      function($scope,
               $location,
               initialMachineData,
               isosData,
               isoImagesData,
               diskPlans,
               $timeout,
               handleProgress,
               $state,
               $stateParams,
               machineService
      ) {

    $scope.state = $state;

    $scope.app.header.title = initialMachineData.hostname;
    $scope.app.header.icon = 'oi oi-monitor';

    $scope.machine = initialMachineData;
      // THIS is workaround for null value in rest endpoint

    $scope.idToCode = {};

    isosData.forEach(function(image) {
      $scope.idToCode[image.id] = image.code;
    });

    $scope.isoImages =  isoImagesData;

    $scope.diskTypes = initialMachineData.diskTypes;

    $scope.diskPlans = {};

    diskPlans.forEach(function(plan) {

      $scope.diskTypes.forEach(function(type) {
        if(!$scope.diskPlans[type.id])
         $scope.diskPlans[type.id] = [];
       $scope.diskPlans[type.id].push(plan);
      });
    });

    $scope.$on('$stateChangeSuccess', function(state, toState) {
      if(toState.name == 'user.machines.show') {
        $state.go('user.machines.show.power');
      }
    });

    var updateSelectedIso = function() {
      $scope.machine.selectedIso = $scope.isoImages.filter(function(image) {
        return image.id === $scope.machine.isoImageId;
      })[0]
    };

    updateSelectedIso();

    function showAndRethrow(error) {
      $scope.machine.error = error.message || error;
      throw error;
    }

    $scope.machine.deletePermanently = function() {
      return machineService.deletePermanently($scope.machine.id)
          .then($timeout(function() {}, 100))// TODO: this delay shouldn't be needed
          .then(function() {
            $state.go('user.machines.index');
          });
    };

    $scope.machine.deleteDisk = function(diskId) {
      return machineService.deleteDisk($scope.machine.id, diskId);
    };

    $scope.machine.createDisk =  function(a, b) {
      return machineService.createDisk($scope.machine.id, {
        type: a.id,
        sizePlan: b.id
      });
    };


    $scope.machine.changeIso = function(imageId) {
      $scope.requesting.changeIso = true;
      return machineService.changeIso($scope.machine.id, imageId).finally(function() {
        $scope.requesting.changeIso = false;
      });
    };

    $scope.machine.restart = function() {
      $scope.console.sendCtrlAltDel()
    };

    $scope.machine.forceRestart = function() {
      return machineService.forceRestart($scope.machine.id);
    };

    $scope.doAction = function(name, ensureStatus) {
      $scope.requesting[name] = true;
      $scope.machine.erorr = null;
      return machineService.doAction($scope.machine.id, name)
          .then(function() {
            if(ensureStatus) {
              return ensureStatus();
            }
          })
          .catch(showAndRethrow)
        .finally(function() {
          $scope.requesting[name] = false;
      });
    };


    $scope.machine.resume = function() {
      return $scope.doAction('resume');
    };
    $scope.machine.pause = function() {
      return $scope.doAction('pause');
    };
    $scope.machine.start = function() {
      return $scope.doAction('start');
    };
    $scope.machine.stop = function() {
      return $scope.doAction('stop', function() {
        var started = (new Date()).getTime();
        function recheck() {
          if((new Date()).getTime() - started > 10000) {
            $scope.machine.didNotStop = true;
            return;
          }

          if ($scope.machine.status !== 'running' || !$scope.requesting.stop) {
            return;
          }
          return $timeout(function() {}, 500).then(recheck);
        }
        return recheck();
      });
    };
    $scope.machine.forceStop = function() {
      return $scope.doAction('forceStop');
    };
    $scope.machine.forceRestart = function() {
      return $scope.doAction('forceRestart', function() {
        function recheck() {
          if ($scope.machine.status === 'running') {
            return;
          }
          return $timeout(function() {}, 500).then(recheck);
        }
        return recheck();
      });
    };

    $scope.console = {}; // will be bound by directive

    $scope.$watch('machine.status', function() {
      $scope.machine.didNotStop = false;
    });

    $scope.$watch(function() {

      var requesting = false;
      for(key in $scope.requesting) {
        if($scope.requesting[key]) {
          requesting = true;
        }
      }

      if(requesting) {
        $scope.canDo = {
          start: false,
          pause: false,
          resume: false,
          stop: false,
          restart: false,
          forceRestart: false,
          forceStop: false
        };
      } else if($scope.machine.status === 'stopped') {
        $scope.canDo = {
          start: !$scope.requesting.start, pause: false, resume: false, stop: false, restart: false, forceRestart: false, forceStop: false
        };
      }  else {
        var running = ($scope.machine.status === 'running');
        $scope.canDo = {
          start: false,
          pause: running,
          resume: !running,
          stop: running,
          restart: running && !$scope.requesting.restart,
          forceRestart:true,
          forceStop: true
        };
      }

    });

    $scope.requesting = {};
    $scope.machine.requesting = $scope.requesting;

    $scope.canDo = {};

    var timeoutHandler;

    var lastPromise;
    var abortRequest;

    function updateState() {
      var skipIsoUpdate = $scope.requesting.changeIso;

      if(timeoutHandler) {
        $timeout.cancel(timeoutHandler);
      }
      if(lastPromise) {
        return lastPromise;
      }
      lastPromise = machineService.get($scope.machine.id).then(function(machineData) {
        if(abortRequest)
          return;
        var prevTime = $scope.machine.processorUsage.timeMillis;
        var prevCpuTime = $scope.machine.processorUsage.cpuTime;

        var humps = require('humps');

        $scope.machine = angular.extend($scope.machine, machineData );

        var time = $scope.machine.processorUsage.timeMillis;
        var cpuTime = $scope.machine.processorUsage.cpuTime;

        var maxMilis = (time - prevTime);
        var usedMilis = (cpuTime - prevCpuTime)/1000000;

        $scope.machine.cpuUsage = Math.min(1.0, usedMilis / maxMilis);

        $scope.console.paused = machineData.status === 'suspended';

        $scope.machine.stateDisconnected = false;

        // prevent live updates from changing this until the process ended
        if(!skipIsoUpdate && !$scope.requesting.changeIso) {
          updateSelectedIso();
        }

        timeoutHandler = $timeout(updateState, 1000);
      }, function(err) {
        if(err && (err.status === 0 || err.status === 500)) {
          throw err;
        }
        // go to machine index if there is error with this machine
        $state.go('user.machines.index');

        $scope.machine.stateDisconnected = true;
        timeoutHandler = $timeout(updateState, 5000);
        throw err;
      }).finally(function() {
        lastPromise = null;
      });

      return lastPromise;
    }
    timeoutHandler = $timeout(updateState, 1000);

    $scope.$on('$destroy', function() {
      $timeout.cancel(timeoutHandler);
      abortRequest = true;
      $scope.app.menuCollapse = false;
    });
  });

  return moduleId;

});

