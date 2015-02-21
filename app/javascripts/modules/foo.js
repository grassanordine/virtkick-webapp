define(function(require) {

  var angular = require('angular');
  var moduleUri = require('module').uri;
  angular.module(moduleUri).controller('Foo', function() {
    console.log("Foo controller");
  });
  return moduleUri;
});