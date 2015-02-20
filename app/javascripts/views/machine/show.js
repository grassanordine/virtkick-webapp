define(function(require) {
  require('appcommon');
  require('!domReady');

  var angular = require('angular');
  require('angular-route');

  var app = angular.module('app',
    [
      require('modules/handleProgress'),
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
  });
  app.controller('SettingsCtrl', function($scope) {
  });


  app.config(function($stateProvider, $locationProvider, $urlRouterProvider, initialMachineData) {
    $locationProvider.html5Mode(true);

    $urlRouterProvider.otherwise(initialMachineData.id + '/power', {
      machineId: initialMachineData.id
    });

    $stateProvider
        .state('list', {
          url: '/',
          onEnter: function() {
            window.location.href = '/machines';
          }
        })
        .state('show', {
          url: '/:machineId',
          abstract: true,
          template: '<ui-view/>'
        })
        .state('show.power', {
          url: '/power',
          template: require('jade!templates/machine/powerView'),
          controller: 'PowerCtrl'
        })
        .state('show.console', {
          url: '/console',
          sticky: true,
          views: {
            'console@': {
              template: require('jade!templates/machine/consoleView'),
              controller: 'ConsoleCtrl'
            }
          }
        })
        .state('show.storage', {
          url: '/storage',
          template: require('jade!templates/machine/storageView'),
          controller: 'StorageCtrl'
        })
        .state('show.settings', {
          url: '/settings',
          template: require('jade!templates/machine/settingsView'),
          controller: 'SettingsCtrl'
        });
  });

  app.controller('AppCtrl', function($scope) {
    $scope.data = {
      menuCollapse: false
    };
  });

  app.controller('ShowMachineCtrl',
      function($scope,
               $rootScope,
               $http,
               $location,
               initialMachineData,
               isoData,
               isoImagesData,
               diskTypes,
               diskPlans,
               vncPassword,
               $interval,
               $timeout,
               handleProgress,
               $state,
               $stateParams,
               $rootScope
      ) {

    $scope.$state = $state;

    $scope.activate = function(tab) {
      $state.go('show.'+tab, {
        machineId: initialMachineData.id
      });
    };

    $scope.machine = initialMachineData;
      // THIS is workaround for null value in rest endpoint

    $scope.machine.vncPassword = vncPassword;

    $scope.idToCode = {};
    isoData.forEach(function(image) {
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

    $scope.storage = {
      newDiskType: $scope.diskTypes[0],
      newDiskPlan: $scope.diskPlans[$scope.diskTypes[0].id][0] 
    };

    $scope.$on('$stateChangeSuccess', function(state, toState, toParams, fromState, fromParams) {
      var m;
      m = fromState.name.match(/.*\.(.+)/);
      if(m) {
        $scope.data.active[m[1]] = false;
      }
      m = toState.name.match(/.*\.(.+)/);
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
      $http.delete('/machines/' + $scope.machine.id).then(function(res) {
        window.location.href = '/machines';
      });
    };

    $scope.machine.deleteDisk = function(disk) {
      $http.delete('/machines/' + $scope.machine.id + '/disks/' + disk).then(function(res) {
        console.log("deleted disk");
      });
    };

    $scope.machine.createDisk = function(a, b) {
      //$scope.storage.showDetails = false;
      //$scope.storage.creatingDisk = true;
      return $http.post('/machinma' +
      'es/' + $scope.machine.id + '/disks',  {
        disk: {
          type: a.id,
          size_plan: b.id
        }
      }).then(function(res) {
        return handleProgress(res.data.progress_id);
      }).then(function() {
        console.log("FINISH!!");

        //$scope.storage.creatingDisk = false;
      }, function() {
        // TODO: show error
        //$scope.storage.creatingDisk = false;
      });
    };

    $scope.machine.changeIso = function(imageId) {
      $scope.machine.mountingIso = true;
      $http.post('/machines/' + $scope.machine.id + '/mount_iso', {
        machine: {
          iso_image_id: imageId
        }
      }).then(function(data) {
        handleProgress(data.progress_id).then(function() {
          $scope.machine.mountingIso = false;
        }, function() {
          $scope.machine.mountingIso = false;
        });
      }, function(error) {
        // TODO handle error
        $scope.machine.mountingIso = false;
      });
    };

    $scope.machine.restart = function(cb) {
      $scope.console.sendCtrlAltDel()
    };


    $scope.machine.forceRestart = function(cb) {
      return $http.post('/machines/' + $scope.machine.id + '/force_restart');
    };

    $scope.machine.resume = function(cb) {
      $scope.doAction('resume', cb);
    };
    $scope.machine.pause = function(cb) {
      $scope.doAction('pause', cb);
    };
    $scope.machine.start = function(cb) {
      $scope.doAction('start', cb);
    };
    $scope.machine.stop = function(cb) {
      $scope.doAction('stop', cb);
    };
    $scope.machine.forceStop = function(cb) {
      $scope.doAction('force_stop', cb);
    };
    $scope.machine.forceRestart = function(cb) {
      $scope.doAction('force_restart', cb);
    };

    $scope.console = {}; // will be bound by directive

    var baseUrl = '/machines/' + $scope.machine.id;

    $scope.toHumanValue = function(val) {
      var unit = 'B';
      if(val > 1024) {
        val /= 1024;
        unit = 'KB';
        if(val > 1024) {
          val /= 1024;
          unit = 'MB';
          if(val > 1024) {
            val /= 1024;
            unit = 'GB';
            if(val > 1024) {
              val /= 1024;
              unit = 'TB';
            }
          }
        }
      }
      return val + ' ' + unit;
    }


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

    $scope.doAction = function(name, cb) {

      var actionUrl = baseUrl + '/' + name;

      $scope.requesting[name]= true;

      $timeout.cancel(timeoutHandler);
      $http.post(actionUrl).then(function(res) {
        var data = res.data;
        handleProgress(data.progress_id).then(function() {

          updateState(function(err) {
            $scope.requesting[name]= false;
            $scope.machine.error = err;
            if(cb) cb(err);
          });
        }, function(error) {
          $scope.requesting[name]= false;
          $scope.machine.error = error;
          if(cb) cb(error);
        });
      });
    };

    $scope.requesting = {};

    $scope.machine.requesting = $scope.requesting;

    $scope.canDo = {};

    var timeoutHandler;
    function updateState(cb) {
      var skipIsoUpdate = !$scope.machine.mountingIso;
      if(timeoutHandler) {
        $timeout.cancel(timeoutHandler);
      }
      $http.get(baseUrl + '.json').then(function(response) {

        var prevTime = $scope.machine.processorUsage.timeMillis;
        var prevCpuTime = $scope.machine.processorUsage.cpuTime;

        var humps = require('humps');

        $scope.machine = angular.extend($scope.machine, humps.camelizeKeys(response.data) );

        var time = $scope.machine.processorUsage.timeMillis;
        var cpuTime = $scope.machine.processorUsage.cpuTime;

        var maxMilis = (time - prevTime);
        var usedMilis = (cpuTime - prevCpuTime)/1000000;

        $scope.machine.cpuUsage = Math.min(1.0, usedMilis / maxMilis);


        // THIS is workaround for null value in rest endpoint
        $scope.machine.vncPassword = vncPassword;

        $scope.console.paused = response.data.status.id === 'suspended';

        $scope.machine.stateDisconnected = false;

        // prevent live updates from changing this until the process ended
        if(!skipIsoUpdate && !$scope.machine.mountingIso) {
          updateSelectedIso();
        }

        if(cb) cb();

        timeoutHandler = $timeout(updateState, 1000);
      }, function(err) {
        if(cb) cb(err);

        $scope.machine.stateDisconnected = true;
        timeoutHandler = $timeout(updateState, 5000);
      });
    }
    timeoutHandler = $timeout(updateState, 1000);

    $scope.$on('$destroy', function() {
      $timeout.cancel(timeoutHandler);
    });
    

    $scope.$watch('data.active.console', function(val) {
      $scope.$parent.data.menuCollapse = $scope.data.active.console;
    });
  });

  angular.element().ready(function() {
    angular.bootstrap(document, ['app']);
  });

});

