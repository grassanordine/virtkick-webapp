define(function(require) {
  var module = require('module');
  var angular = require('angular');
  var humps = require('humps');


  var mod = angular.module(module.uri, []);
  angular.element('script.constant').each(function() {
    mod.constant(this.id,
        humps.camelizeKeys(JSON.parse(this.innerHTML))
    );
  });

  return module.uri;
});