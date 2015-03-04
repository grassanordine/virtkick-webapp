define(function(require) {
  require('appcommon');
  require('!domReady');

  var angular = require('angular');
  require('angular-route');

  var moduleUri = require('module').uri;
  var app = angular.module(moduleUri,
    [
      require('modules/handleProgress'),
      require('modules/machineService'),
      require('modules/common'),
      require('directives/ng-confirm'),
      'ngRoute',
      require('angular-ui-router'),
      require('./console'),
      require('directives/distroselect/distroselect'),
      require('directives/ajaxloader/ajaxloader'),
      require('directives/long-run-button/directive')
    ]
  );


  app.controller('PowerCtrl', function($scope) {
  });
  app.controller('ConsoleCtrl', function($scope) {
  });
  app.controller('StorageCtrl', function($scope) {
    console.log("Disk types", $scope.diskPlans);
    $scope.storage = {
      newDiskType: $scope.diskTypes[0],
      newDiskPlan: $scope.diskPlans[$scope.diskTypes[0].id][0]
    };
  });
  app.controller('SettingsCtrl', function($scope) {
  });


  app.config(function($stateProvider) {

    $stateProvider
        .state('machines.show', {
          url: '/{machineId:[0-9]{1,8}}',
          resolve: {
            initialMachineData: function($stateParams, machineService) {
              if($stateParams.machine) {
                return $stateParams.machine;
              }
              return machineService.get($stateParams.machineId);
            }
          },
          template: require('jade!templates/machine/show'),
          controller: 'ShowMachineCtrl'
        })
        .state('machines.show.power', {
          url: '/power',
          views: {
            'tab@machines.show': {
              template: require('jade!templates/machine/powerView'),
              controller: 'PowerCtrl'
            }
          }
        })
        .state('machines.show.console', {
          url: '/console',
          sticky: true,
          views: {
            'console@machines.show': {
              template: require('jade!templates/machine/consoleView'),
              controller: 'ConsoleCtrl'
            }
          }
        })
        .state('machines.show.storage', {
          url: '/storage',
          views: {
            'tab@machines.show': {
              template: require('jade!templates/machine/storageView'),
              controller: 'StorageCtrl'
            }
          }
        })
        .state('machines.show.settings', {
          url: '/settings',
          views: {
            'tab@machines.show': {
              template: require('jade!templates/machine/settingsView'),
              controller: 'SettingsCtrl'
            }
          }
        });
  });



  app.controller('ShowMachineCtrl',
      function($scope,
               $rootScope,
               $location,
               initialMachineData,
               isosData,
               isoImagesData,
               diskTypes,
               diskPlans,
               $timeout,
               handleProgress,
               $state,
               $stateParams,
               machineService,
               $q
      ) {

    $scope.app.header.title = initialMachineData.hostname;
    $scope.app.header.icon = 'monitor';

    $scope.activate = function(tab) {
      if($state.includes('machines.show')) {
        $state.go('machines.show.' + tab, {
          machineId: initialMachineData.id
        });
      }
    };


    $scope.machine = initialMachineData;
      // THIS is workaround for null value in rest endpoint

    $scope.idToCode = {};

    isosData.forEach(function(image) {
      $scope.idToCode[image.id] = image.code;
    });

    $scope.isoImages =  isoImagesData;

    $scope.diskTypes = diskTypes;

    $scope.diskPlans = {};

    diskPlans.forEach(function(plan) {

      $scope.diskTypes.forEach(function(type) {
        if(!$scope.diskPlans[type.id])
         $scope.diskPlans[type.id] = [];
       $scope.diskPlans[type.id].push(plan);
      });
    });

    $scope.$on('$stateChangeSuccess', function(state, toState, toParams, fromState, fromParams) {
      var m;
      m = fromState.name.match(/show\.(.+)/);
      if(m) {
        $scope.data.active[m[1]] = false;
      }
      m = toState.name.match(/show\.(.+)/);
      if(m) {
        $scope.data.active[m[1]] = true;
      }
    });


    $scope.data = {
      active: {
      }
    };

    $scope.data.active[$location.path().substr(1)] = true;

    var updateSelectedIso = function() {
      $scope.machine.selectedIso = $scope.isoImages.filter(function(image) {
        return image.id === $scope.machine.isoImageId;
      })[0]
    };

    updateSelectedIso();

    $scope.machine.deletePermanently = function() {
      return machineService.deletePermanently($scope.machine.id)
          .then(function() {
            window.location.href = '/machines';
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

    $scope.doAction = function(name) {
      $scope.requesting[name] = true;
      return machineService.doAction($scope.machine.id, name)
          .then(updateState)
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
      return $scope.doAction('stop');
    };
    $scope.machine.forceStop = function() {
      return $scope.doAction('force_stop');
    };
    $scope.machine.forceRestart = function() {
      return $scope.doAction('force_restart');
    };

    $scope.console = {}; // will be bound by directive

    var baseUrl = '/machines/' + $scope.machine.id;

    $scope.$watch(function() {

      if($scope.machine.status.id === 'stopped') {
        $scope.canDo = {
          start: !$scope.requesting.start, pause: false, resume: false, stop: false, restart: false, force_restart: false, force_stop: false
        };
      }
      else {
        $scope.canDo = {
          start: false,
          pause: $scope.machine.status.running,
          resume: !$scope.machine.status.running,
          stop: $scope.machine.status.running,
          restart: $scope.machine.status.running && !$scope.requesting.restart,
          force_restart:true,
          force_stop: true
        };
      }

    });

    $scope.requesting = {};

    $scope.machine.requesting = $scope.requesting;

    $scope.canDo = {};

    var timeoutHandler;

    var lastPromise;
    var aborter;
    function updateState() {
      var skipIsoUpdate = $scope.requesting.changeIso;

      if(timeoutHandler) {
        $timeout.cancel(timeoutHandler);
      }
      if(lastPromise) {
        return lastPromise;
      }

      aborter = $q.defer();
      lastPromise = machineService.get($scope.machine.id, aborter).then(function(machineData) {
        var prevTime = $scope.machine.processorUsage.timeMillis;
        var prevCpuTime = $scope.machine.processorUsage.cpuTime;

        var humps = require('humps');

        $scope.machine = angular.extend($scope.machine, machineData );

        var time = $scope.machine.processorUsage.timeMillis;
        var cpuTime = $scope.machine.processorUsage.cpuTime;

        var maxMilis = (time - prevTime);
        var usedMilis = (cpuTime - prevCpuTime)/1000000;

        $scope.machine.cpuUsage = Math.min(1.0, usedMilis / maxMilis);

        $scope.console.paused = machineData.status.id === 'suspended';

        $scope.machine.stateDisconnected = false;

        // prevent live updates from changing this until the process ended
        if(!skipIsoUpdate) {
          updateSelectedIso();
        }

        timeoutHandler = $timeout(updateState, 1000);
      }, function(err) {
        if(err && err.status === 0) {
          throw err;
        }
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
      if(aborter) {
        aborter.resolve('');
      }
      $scope.app.menuCollapse = false;
    });
    

    $scope.$watch('data.active.console', function(val) {
      $scope.app.menuCollapse = $scope.data.active.console;
    });
  });

  return moduleUri;

});

