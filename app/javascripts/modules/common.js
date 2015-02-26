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
    require('angular-ui-router')
  ];

  var billingModule = 'modules/billing';
  if(require.defined('modules/billing')) {
    var str = require(billingModule);
    deps.push(str);
  }


  var mod = angular.module(module.uri, deps);
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

  mod.filter('currency', function() {
    return function(amount, currency) {
      var floatValue = parseFloat(amount / 100).toFixed(2);
      if (currency == 'usd') {
        return '$' + floatValue;
      }
      return floatValue + ' ' + currency.toUpperCase();
    };
  });

  mod.filter('payPeriod', function() {
    return function(value) {
      if(value == 'monthly') {
        return 'mo';
      } else if(value == 'hourly') {
        return 'h';
      }
      return value;
    };
  });

  mod.filter('bytes', function() {
    return function(amount, amountFormat, precision) {

      precision = precision || 0;

      amountFormat = (amountFormat || 'b').toUpperCase();

      if(!amount) {
        return "0" + ' ' + amountFormat;
      }

      if (amountFormat === 'TB') {
        amount *= 1024 * 1024 * 1024 * 1024;
      } else if (amountFormat === 'GB') {
        amount *= 1024 * 1024 * 1024;
      } else if (amountFormat === 'MB') {
        amount *= 1024 * 1024;
      } else if (amountFormat === 'KB') {
        amount *= 1024;
      }
      amountFormat = 'B';
      if (amount >= 1024) {
        amount /= 1024;
        amountFormat = 'KB';
        if (amount >= 1024*5) {
          amount /= 1024;
          amountFormat = 'MB';
          if (amount >= 1024*5) {
            amount /= 1024;
            amountFormat = 'GB';
            if (amount >= 1024*5) {
              amount /= 1024;
              amountFormat = 'TB';
            }
          }
        }
      }

      amount = amount.toFixed(2);
      while(amount.slice(-1).match(/[\.0]/)) {
        amount = amount.slice(0, -1);
      }
      return amount + ' ' + amountFormat;
    };
  });

  return module.uri;
});