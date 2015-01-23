define(function(require) {
  var module = require('module');
  var angular = require('angular');
  var $ = require('jquery');
  var RFB = require('novnc/rfb');

  function controller($scope) {
    $scope.ungrab = function() {
      $scope.rfb.get_keyboard().ungrab();
      $scope.rfb.get_mouse().ungrab(); 
      $scope.focused = false;
    }
    $scope.grab = function() {
     $scope.rfb.get_keyboard().grab(); 
     $scope.rfb.get_mouse().grab(); 
     $scope.focused = true;
    }
    $scope.sendCtrlAltDel = function() {
      $scope.rfb.sendCtrlAltDel();
    }
  }

  function link(scope, element, attrs) {

    var rfb;
    var connectLoop = false;
    var $canvasWrapper = element;

    function updateConsole() {
      var width, height;
      if (!scope.rfb) {
        width = 640;
        height = 480;
      } else {
        width = scope.rfb.get_display().get_width();
        height = scope.rfb.get_display().get_height();
      }

      // after connecting first noVNC frames are not real screens, so catch only
      // realistic sizes to avoid console flickering
      if (height <= 20) {
        return;
      }

      $canvasWrapper.width(width + "px");
      $canvasWrapper.height(height + "px");
      var margin = 70;
      var left = ($('#page-machine').width() - width - margin) / 2;
      left -= $('.side-menu-wrapper').outerWidth() / 2;
  
      $('.console-window').css("margin-left", left);

    }


    var connect = function() {
      if (!connectLoop) {
        return;
      }
      var host = window.location.hostname;
      var port = window.location.port;
      var password = attrs.password;
      var uuid = attrs.uuid;

      var m = window.location.pathname.match(/\/machines\/(\d+)/);

      scope.rfb.connect(host, port, password, 'machines/' + m[1]+ "/vnc");
    };

    var connectTimeout;

    var destroying = false;
    scope.rfb = new RFB({
      'target': element.find('canvas')[0],
      'repeaterID': '',
      'encrypt': location.protocol === 'https:',
      'true_color': true,
      'local_cursor': true,
      'shared': true,
      'focused': false,
      'onUpdateState': function(rfb, state, oldstate, statusMsg) {
        scope.state.vncState = state;
        if(state === 'failed' && !destroying) {
          console.log("Trying to connect!!");
          connectTimeout = setTimeout(connect, 1000);
        }
        // force ungrab mouse if not focused
        if(!scope.focused) {
          //scope.rfb.get_keyboard().ungrab();
        }
        return;
      },
      'onFBUComplete': function (rfb, fbu) {
        updateConsole();
      },
      'view_only': false,
      'onPasswordRequired': function() {
        console.log('VNC: Password required');
      }
    });

    // http://stackoverflow.com/questions/16881478/how-to-call-a-method-defined-in-an-angularjs-directive
    if(scope.control) {
      scope.control.connect = function() {
        if(scope.state.vncState == 'normal')
          return;
        connectLoop = true;
        connect();
      };
      scope.control.sendCtrlAltDel = function() {
        scope.rfb.sendCtrlAltDel();
      };
    }


    $(window).on('resize', updateConsole);

    scope.$on("$destroy", function() {
      $(window).off('resize', updateConsole);
      destroying = true;
      scope.rfb.disconnect();
      $canvasWrapper.remove();
      clearTimeout(connectTimeout);
      delete scope.rfb;
    }); 

    updateConsole();

    connectLoop = true;
    connect();
  }

  angular.module(module.uri, []).directive('console', function() {
    return {
      replace: true,
      restrict: 'E',
      scope: {
        focused: '=',
        state: '=',
        control: '='
      },
      controller: controller,
      template: require('jade!templates/machine/console'),
      link: link
    }
  });
  return module.uri;

});