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

          value = $q.all(hooks[name].map(function(hookFunc) {
            try {
              var resolved = args[0];
              value = $injector.invoke(hookFunc,
                  null, resolved
              );
              return $q.when(value);
            } catch(err) {
              console.error('Unable to run hook', name, err.stack);
              return reject(err);
            }
          }));
        }
        return resolve(value);
      });
    };
    hookFunction.register = function(name, handler) {
      if(!hooks[name]) {
        hooks[name] = [handler];
      } else {
        hooks[name].push(handler);
      }
    };
    return hookFunction;
  });

  return moduleId;
});