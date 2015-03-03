define(function(require) {
  var moduleUri = require('module').uri;
  var mod = angular.module(moduleUri, [require('modules/handleProgress')]);

  var humps = require('humps');



  mod.service('machineService', function($http, handleProgress, $injector, $q, $timeout) {
    var machinesCache;
    var cacheTime;

    function isCacheFresh() {
      return cacheTime && new Date().getTime() - cacheTime < 10000
    }

    function cleanCache() {
      cacheTime = undefined;
    }

    var machineProgress =  function(progressId) {
      function doQuery() {
        return $http.get('/api/machine_progress/' + progressId).then(function(res) {
          if (!res.data.finished) {
            return $timeout(doQuery, 250);
          }
          return res.data;
        });
      }
      return $timeout(doQuery, 250);
    };

    return {
      index: function(aborter) {
        if(isCacheFresh()) {
          return $q.when(machinesCache);
        }

        return $http.get('/api/machines.json', {
          timeout: aborter?(aborter.promise):undefined
        }).then(function(res) {
          machinesCache = humps.camelizeKeys(res.data);
          cacheTime = new Date().getTime();

          return humps.camelizeKeys(res.data);
        });
      },
      createMachine: function(data) {
        return $http.post('/api/machines', {
          machine: {
            hostname: data.hostname,
            plan_id: data.planId,
            image_type: data.imageType,
            iso_distro_id: data.isoId
          }
        }).then(function(data) {
          return machineProgress(data.data.data).then(function(data) {
            cacheTime = undefined;
            return data.given_meta_machine_id;
          });
        }).finally(cleanCache);
      },
      validateHostname: function(hostname) {
        return $http.post('/api/machines',  {
          validate: true,
          machine: {
            hostname: hostname
        }}).then(function(response) {
          var data = response.data;
          if(data.errors && data.errors.hostname) {
            throw data.errors.hostname;
          }
        });
      },
      get: function(machineId, aborter) {
        if(isCacheFresh()) {
          var machines = machinesCache.machines;
          for(var i = 0;i < machines.length;++i) {
            if(machines[i].id == machineId) {
              return $q.when(machines[i]);
            }
          }
        }
        return $http.get('/api/machines/' + machineId, {
          timeout: aborter?(aborter.promise):undefined
        }).then(function(response) {
          var machineData = humps.camelizeKeys(response.data);
          return machineData;
        });
      },
      deletePermanently: function(machineId) {
        return $http.delete('/api/machines/' + machineId)
            .finally(cleanCache);
      },
      deleteDisk: function(machineId, diskId) {
        return $http.delete('/api/machines/' + machineId + '/disks/' + diskId);
      },
      createDisk: function(machineId, diskType) {
        return $http.post('/api/machines/' + machineId + '/disks', {
          disk: humps.decamelizeKeys(diskType)
        }).then(function(res) {
          return handleProgress(res.data.progress_id);
        });
      },
      changeIso: function(machineId, imageId) {
        return $http.post('/api/machines/' + machineId + '/mount_iso', {
          machine: {
            iso_image_id: imageId
          }
        }).then(function(res) {
          return handleProgress(res.data.progress_id);
        });
      },
      doAction: function(machineId, action) {
        return $http.post('/api/machines/' + machineId + '/' + action).then(function(res) {
          return handleProgress(res.data.progress_id);
        }).finally(cleanCache);
      },
      forceRestart: function(machineId) {
        return $http.post('/api/machines/' + machineId + '/force_restart');
      }
    }
  });
  return moduleUri;
});