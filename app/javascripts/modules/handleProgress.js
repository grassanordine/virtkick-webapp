define(function(require) {
  var module = require('module');

  var angular = require('angular');
  var mod = angular.module(module.id, []);
  mod.factory('handleProgress', function($http, $timeout, $q) {
    return function(progressId) {
      if(progressId.data && progressId.data.progress_id) {
        progressId = progressId.data.progress_id;
      }

      function doQuery() {
        return $http.get('/api/progress/' + progressId).then(function(res) {
          if(!res.data.finished) {
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

  return module.id;
});
