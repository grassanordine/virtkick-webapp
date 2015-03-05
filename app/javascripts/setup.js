define(function(require) {

  require('appcommon');
  var angular = require('angular');
  require('angular-messages'); // for ngMessages
  require('angular-animate');
  var app = angular.module('app', [
    'ngAnimate',
    'ngMessages',
    require('directives/long-run-button/directive'),
    require('angular-bootstrap-show-errors'),
    require('angular-input-match'),
    require('modules/helpers'),
    require('modules/constants')
  ]);

  require('csrfSetup')(app);

  var humps = require('humps');

  app.controller('SetupCtrl', function($scope, $http, $location, $q, allowVpsProvider) {
    $scope.setup = {
      allowVpsProvider: allowVpsProvider
    };

    $scope.submit = function(data) {
      return $http.post('/setup/perform/' + humps.decamelize($scope.setup.mode), $scope.setup)
          .catch(function(res) {
            $scope.setup.error = res.data.error ? res.data.error : res.data.message;
            throw res;
          });
    };

    $scope.reload = function() {
      window.location.pathname = '/';
    };
  });

  angular.element().ready(function() {
    angular.bootstrap(document, ['app']);
    try {
      angular.bootstrap(document, ['app']);
    } catch(err) { }
  });

});