define(function(require) {
  var moduleUri = require('module').uri;
  var mod = angular.module(moduleUri, [require('modules/handleProgress')]);

  var humps = require('humps');

  mod.service('machineService', function($http, handleProgress, $injector, $q) {
    var machinesCache;
    var cacheTime;

    function isCacheFresh() {
      return cacheTime && new Date().getTime() - cacheTime < 10000
    }

    return {
      index: function() {
        if(isCacheFresh()) {
          return $q.when(machinesCache);
        }

        return $http.get('/machines.json').then(function(res) {
          machinesCache = humps.camelizeKeys(res.data);
          cacheTime = new Date().getTime();

          return humps.camelizeKeys(res.data);
        });
      },
      get: function(machineId, aborter) {
        if(isCacheFresh()) {
          console.log("Is cache fresh", machinesCache);

          var machines = machinesCache.machines;
          for(var i = 0;i < machines.length;++i) {
            if(machines[i].id == machineId) {
              console.log("RETURN", machines[i], machineId);
              return $q.when(machines[i]);
            }
          }
        }
        console.log("GETTING MACHINE DATA");
        return $http.get('/machines/' + machineId, {
          timeout: aborter?(aborter.promise):undefined
        }).then(function(response) {
          var machineData = humps.camelizeKeys(response.data);
          return machineData;
        });
      },
      deletePermanently: function(machineId) {
        return $http.delete('/machines/' + machineId);
      },
      deleteDisk: function(machineId, diskId) {
        return $http.delete('/machines/' + machineId + '/disks/' + diskId);
      },
      createDisk: function(machineId, diskType) {
        return $http.post('/machines/' + machineId + '/disks', {
          disk: humps.decamelizeKeys(diskType)
        }).then(function(res) {
          return handleProgress(res.data.progress_id);
        });
      },
      changeIso: function(machineId, imageId) {
        return $http.post('/machines/' + machineId + '/mount_iso', {
          machine: {
            iso_image_id: imageId
          }
        }).then(function(res) {
          return handleProgress(res.data.progress_id);
        });
      },
      doAction: function(machineId, action) {
        return $http.post('/machines/' + machineId + '/' + action).then(function(res) {
          return handleProgress(res.data.progress_id);
        });
      },
      forceRestart: function(machineId) {
        return $http.post('/machines/' + machineId + '/force_restart');
      }
    }
  });
  return moduleUri;
});