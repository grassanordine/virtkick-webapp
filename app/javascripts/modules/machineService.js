define(function(require) {
  var moduleUri = require('module').uri;
  var mod = angular.module(moduleUri, [require('modules/handleProgress')]);

  var humps = require('humps');

  mod.service('machineService', function($http, handleProgress, vncPassword) {
    return {
      get: function(machineId) {
        return $http.get('/machines/' + machineId).then(function(response) {
          var machineData = humps.camelizeKeys(response.data);

          // THIS is workaround for null value in rest endpoint
          machineData.vncPassword = vncPassword;

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