define(function(require) {
  var angular = require('angular');
  var moduleId = require('module').id;

  angular.module(moduleId, []).factory('$hook', function($injector, $q) {

    var hooks = {};
    var hookFunction = function(name) {
      return $q(function(resolve, reject) {
        var value = null;
        if(hooks[name]) {
          var args = Array.prototype.slice.call(arguments);
          args.shift();
          try {
            value = $injector.invoke(hooks[name],
                null, {
                  args: args
                }
            );
          } catch(err) {
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