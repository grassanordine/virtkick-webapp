window.name = "NG_DEFER_BOOTSTRAP!";
define(function(require) {
  var module = require('module');
  var angular = require('angular');

  require('angular-filter'); // for angular.filter
  require('ui-bootstrap'); // for ui.bootstrap
  require('angular-messages'); // for ngMessages
  require('ct-ui-router-extras');
  require('angular-animate');

  var deps = [
    require('./constants'),
    'ui.bootstrap',
    'ngMessages',
    'angular.filter',
    'ngAnimate',
    require('modules/hook'),
    'ct.ui.router.extras.sticky',
    'ct.ui.router.extras.future',
    require('angular-ui-router'),
    require('modules/helpers')
  ];

  var billingModule = 'modules/billing';
  if(require.defined('modules/billing')) {
    var str = require(billingModule);
    deps.push(str);
  }


  var mod = angular.module(module.id, deps);
  require('csrfSetup')(mod);

  mod.config(function($urlMatcherFactoryProvider) {
    $urlMatcherFactoryProvider.caseInsensitive(true);
    $urlMatcherFactoryProvider.strictMode(false);
  });

  mod.controller('AppCtrl', function($scope) {
    $scope.data = {
      menuCollapse: false
    };
  });

  return module.id;
});