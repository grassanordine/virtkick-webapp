define(function(require) {
  var angular = require('angular');
  var module = require('module');

  angular.module(module.uri, []).factory('$hook', function($injector, $q) {

    var hooks = {};
    var hookFunction = function(name) {
      var value = null;
      if(hooks[name]) {
        var args = Array.prototype.slice.call(arguments);
        args.shift();
        value = $injector.invoke(hooks[name],
            null,
            {
              args: args
            }
        );
      }
      return $q.when(value);
    };
    hookFunction.register = function(name, handler) {
      hooks[name] = handler;
    };
    return hookFunction;
  });

  return module.uri;
});