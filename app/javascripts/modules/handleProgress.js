define(function(require) {
  var module = require('module');

  var angular = require('angular');
  var mod = angular.module(module.id, []);
  mod.factory('handleProgress', function($http, $timeout, $q) {
    return function(progressId, cb) {
      if(progressId.data && progressId.data.progress_id) {
        progressId = progressId.data.progress_id;
      }

      function doQuery() {
        return $http.get('/api/progress/' + progressId).then(function(res) {
          if(!res.data.finished) {
            if(cb) {cb(res.data.data)}
            return $timeout(doQuery, 250);
          }
          if(res.data.error) {
            throw res.data.error;
          }
          return res.data.data;
        });
      }
      return $timeout(doQuery, 250);
    };
  });

  mod.factory('handleProgressWithUpdates', function(handleProgress) {
    return function(cb) {
      return function(progressId) {
        return handleProgress(progressId, cb);
      };
    };
  });

  return module.id;
});
