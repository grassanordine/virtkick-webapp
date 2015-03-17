define(function(require) {
  var angular = require('angular');
  var moduleId = require('module').id;

  angular.module(moduleId, []).factory('$hook', function($injector, $q) {

    var hooks = {};
    var hookFunction = function(name) {
      var args = Array.prototype.slice.call(arguments);
      args.shift();
      return $q(function(resolve, reject) {
        var value = null;
        if(hooks[name]) {
          try {
            var resolved = args[0];
            value = $injector.invoke(hooks[name],
                null, resolved
            );
          } catch(err) {
            console.error('Unable to run hook', name, err.stack);
            return reject(err);
          }
        }
        return resolve(value);
      });
    };
    hookFunction.register = function(name, handler) {
      hooks[name] = handler;
    };
    return hookFunction;
  });

  return moduleId;
});