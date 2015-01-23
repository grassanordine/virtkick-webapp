define(function(require) {
  require('appcommon');
  var $ = require('jquery');
  require('!domReady');

  require('twitter/bootstrap/rails/confirm');

  //require('./_console');
  require('ui-bootstrap');
  require('angular-sanitize');
  require('angular-messages');

  var angular = require('angular');
  
  require('angular-route');
  require('ui-select');

  // ngSanitize is for ng-bind-html
  var app = angular.module('app',
    ['ui.bootstrap', require('directives/ng-confirm'), 'ngRoute', require('angular-ui-router'), 'ngMessages', require('./console'), require('directives/distroselect/distroselect'), require('directives/ajaxloader/ajaxloader')]
  );

  app.controller('PowerCtrl', function($scope) {
    console.log("Power");
  });
  app.controller('ConsoleCtrl', function($scope) {
    console.log("Console");
  });
  app.controller('StorageCtrl', function($scope) {
  });
  app.controller('SettingsCtrl', function($scope) {
    console.log("Settings", $scope.machine);
  });


  app.config(function($routeProvider, $locationProvider) {
    $locationProvider.html5Mode(true);
    $routeProvider.
      when('/power', {template: require('jade!templates/machine/powerView'), controller: 'PowerCtrl' }).
      when('/console', {template: require('jade!templates/machine/consoleView'), controller: 'ConsoleCtrl' }).
      when('/storage', {template: require('jade!templates/machine/storageView'), controller: 'StorageCtrl' }).
      when('/settings', {template: require('jade!templates/machine/settingsView'), controller: 'SettingsCtrl' }).
      otherwise({redirectTo: '/power'});
  });

  app.controller('AppCtrl', function($scope) {
    $scope.data = {
      menuCollapse: false
    };
  });

  app.controller('ShowMachineCtrl', function($scope, $rootScope, $http, $location) {

    $scope.activate = function(tab) {
      console.log($location.path());
      $location.path( "/" + tab);
    };

    $scope.machine = JSON.parse($('#initialMachineData').html());
      // THIS is workaround for null value in rest endpoint
    $scope.machine.vnc_password = $('#vnc_password').val();

    $scope.idToCode = {};
    JSON.parse($("#isoData").html()).forEach(function(image) {
      $scope.idToCode[image.attributes.id] = image.attributes.code;
    });

    $scope.isoImages = JSON.parse($("#isoImagesData").html()).map(function(image) {
      return image.attributes;
    });

    $scope.diskTypes = JSON.parse($('#diskTypes').html());

    $scope.diskPlans = {};
    JSON.parse($('#diskPlans').html()).forEach(function(plan) {
      $scope.diskTypes.forEach(function(type) {
        if(!$scope.diskPlans[type.id])
         $scope.diskPlans[type.id] = [];
       $scope.diskPlans[type.id].push(plan.attributes);
      });
    });
    console.log($scope.diskPlans);

    $scope.storage = {
      newDiskType: $scope.diskTypes[0],
      newDiskPlan: $scope.diskPlans[$scope.diskTypes[0].id][0] 
    };


    $scope.data = {
      active: {
      }
    };
    $scope.data.active[$location.path().substr(1)] = true;

    var updateSelectedIso = function() {
      $scope.machine.selectedIso = $scope.isoImages.filter(function(image) {
        return image.id === $scope.machine.iso_image_id
      })[0]
    };

    updateSelectedIso();

    $scope.machine.deletePermanently = function() {
      $.ajax({
        url: '/machines/' + $scope.machine.id,
        type: 'DELETE',
        success: function(data) {
          window.location.href = '/machines';
        },
        contentType: "application/json"
      });
    };

    $scope.machine.deleteDisk = function(disk) {
      $.ajax({
        url: '/machines/' + $scope.machine.id + '/disks/' + disk,
        type: 'DELETE',
        success: function(data) {
          
        },
        contentType: "application/json"
      });
    };

    $scope.machine.createDisk = function(a, b) {
      $scope.storage.showDetails = false;
      $scope.storage.creatingDisk = true;
      $.post('/machines/' + $scope.machine.id + '/disks',  {
        disk: {
          // TODO changing type here to a.name does not yield error in progress
          type: a.id,
          size_plan: b.id
        }
      }).then(function(data) {
        handleProgress(data.progress_id, function() {
          $scope.storage.creatingDisk = false;
        }, function() {
          // TODO: show error
          $scope.storage.creatingDisk = false;
        });

        console.log(data);
      }, function(error) {

      });
    };

    $scope.machine.changeIso = function(imageId) {
      $scope.machine.mountingIso = true;
      $.post('/machines/' + $scope.machine.id + '/mount_iso', {
        machine: {
          iso_image_id: imageId
        }
      }).then(function(data) {
        handleProgress(data.progress_id, function() {
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
//      $.ajax({
//        url: '/machines/' + $scope.machine.id + '/restart',
//        type: 'POST',
//        success: function(data) {
//          if(cb) cb(null, data);
//        },
//        error: function(err) {
//          if(cb) cb(err);
//        },
//        contentType: "application/json"
//      });
    };


    $scope.machine.forceRestart = function(cb) {
      $.ajax({
        url: '/machines/' + $scope.machine.id + '/force_restart',
        type: 'POST',
        success: function(data) {
          if(cb) cb(null, data);
        },
        error: function(err) {
          if(cb) cb(err);
        },
        contentType: "application/json"
      });      
    };

    $scope.machine.resume = function(cb) {
      $scope.doAction('resume', cb);
    };
    $scope.machine.pause = function(cb) {
      $scope.doAction('pause', cb);
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

    var handleProgress = function(progressId, onSuccess, onError) {
        var id = setInterval(function() {
          return $.ajax('/progress/' + progressId).success(function(data) {
            if (!data.finished) {
              return;
            }
            clearInterval(id);

            data.error === null ? onSuccess() : onError(data.error);
          });
        }, 500);
      };

      $scope.$watch(function() {

        if($scope.machine.status.attributes.id === 'stopped') {
          $scope.canDo = {
            start: !$scope.requesting.starting, pause: false, resume: false, stop: false, restart: false, force_restart: false, force_stop: false
          };
        }
        else {
          $scope.canDo = {
            start: false,
            pause: $scope.machine.status.attributes.running,
            resume: !$scope.machine.status.attributes.running,
            stop: $scope.machine.status.attributes.running,
            restart: $scope.machine.status.attributes.running && !$scope.requesting.restart,
            force_restart:true,
            force_stop: true
          };
        }

      });

    $scope.doAction = function(name, cb) {

      var actionUrl = baseUrl + '/' + name;

      $scope.requesting[name]= true;
      $.post(actionUrl).then(function(data) {
        handleProgress(data.progress_id, function() {
          $scope.requesting[name]= false;
          $scope.machine.error = null;
          if(cb) cb();
        }, function(error) {
          $scope.requesting[name]= false;
          $scope.machine.error = error;
          if(cb) cb(error);
        });
      });
    };

    $scope.requesting = {};
    $scope.canDo = {};

    var timeoutHandler;
    function updateState() {
      var skipIsoUpdate = !$scope.machine.mountingIso;
      $http.get(baseUrl + '.json').then(function(response) {

        $scope.machine = $.extend($scope.machine, response.data);
        // THIS is workaround for null value in rest endpoint
        $scope.machine.vnc_password = $('#vnc_password').val();

        $scope.console.paused = response.data.status.attributes.id === 'suspended';
        
        // prevent live updates from changing this until the process ended
        if(!skipIsoUpdate && !$scope.machine.mountingIso) {
          updateSelectedIso();
        }

        timeoutHandler = setTimeout(updateState, 1000);
      }, function() {
        $scope.machine.stateDisconnected = true;
        timeoutHandler = setTimeout(updateState, 5000);
      });
    }
    timeoutHandler = setTimeout(updateState, 1000);

    $scope.$on('$destroy', function() {
      clearTimeout(timeoutHandler);
    });
    

    $scope.$watch('data.active.console', function(val) {
      $scope.$parent.data.menuCollapse = $scope.data.active.console;
    });
  });

  angular.element().ready(function() {
    angular.bootstrap(document, ['app']);
  });


  var handleProgress = function(progressId, onSuccess, onError) {
    var id = setInterval(function() {
      return $.ajax('/progress/' + progressId).success(function(data) {
        if (!data.finished) {
          return;
        }
        clearInterval(id);

        data.error === null ? onSuccess() : onError(data.error);
      });
    }, 500);
  };

});

