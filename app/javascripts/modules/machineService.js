define(function(require) {
  var moduleId = require('module').id;
  var mod = angular.module(moduleId, [require('modules/handleProgress')]);

  var humps = require('humps');



  mod.service('machineService', function($http, handleProgress, $injector, $q, $timeout) {
    var machinesCache;
    var cacheTime;

    function extractErrorMessage(response) {
      if(response.data && (response.data.error)) {
        throw response.data.error;
      } else if(response.data) {
        throw response.data;
      }
      throw response;
    }

    function isCacheFresh() {
      return cacheTime && new Date().getTime() - cacheTime < 10000
    }

    function cleanCache() {
      cacheTime = undefined;
    }

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
        }).catch(extractErrorMessage);
      },
      createMachine: function(data) {
        return $http.post('/api/machines.json', {
          machine: {
            hostname: data.hostname,
            plan_id: data.planId,
            image_type: data.imageType,
            iso_distro_id: data.isoId
          }
        }).then(function(res) {
          return handleProgress(res.data.progress_id).then(humps.camelizeKeys);
        }).catch(extractErrorMessage).finally(cleanCache);
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
        return $http.get('/api/machines/' + machineId, {
          timeout: aborter?(aborter.promise):undefined
        }).then(function(response) {
          var machineData = humps.camelizeKeys(response.data);
          return machineData;
        }).catch(extractErrorMessage);
      },
      deletePermanently: function(machineId) {
        return $http.delete('/api/machines/' + machineId).finally(cleanCache).catch(extractErrorMessage);
      },
      deleteDisk: function(machineId, diskId) {
        return $http.delete('/api/machines/' + machineId + '/disks/' + diskId).catch(extractErrorMessage);
      },
      createDisk: function(machineId, diskType) {
        return $http.post('/api/machines/' + machineId + '/disks', {
          disk: humps.decamelizeKeys(diskType)
        }).then(function(res) {
          return handleProgress(res.data.progress_id);
        }).catch(extractErrorMessage);
      },
      changeIso: function(machineId, imageId) {
        return $http.post('/api/machines/' + machineId + '/mount_iso', {
          machine: {
            iso_image_id: imageId
          }
        }).then(function(res) {
          return handleProgress(res.data.progress_id);
        }).catch(extractErrorMessage);
      },
      doAction: function(machineId, action) {
        action = humps.decamelize(action);
        return $http.post('/api/machines/' + machineId + '/' + action).then(function(res) {
          return handleProgress(res.data.progress_id);
        }).catch(extractErrorMessage).finally(cleanCache);
      },
      forceRestart: function(machineId) {
        return $http.post('/api/machines/' + machineId + '/force_restart')
            .catch(extractErrorMessage);
      }
    }
  });
  return moduleId;
});