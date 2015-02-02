define('application', function(require) {
  var $ = require('jquery');
  require('jquery_ujs');
  require('jquery.ajaxchimp')
  require('bootstrap');
  require('twitter/bootstrap/rails/confirm');
  require('!domReady');

  var angular = require('angular');

  var ga = require('snippets/analytics');

  $('.newsletter form').ajaxChimp({
    callback: function(response, element) {
      resultElement = $('.newsletter .result');
      wrapperElement = $('.newsletter .input-group');

      resultElement.addClass('performed');

      if (response.result == 'error') {
        wrapperElement.removeClass('has-success').addClass('has-error');
        resultElement.html(response.msg);
      } else {
        wrapperElement.removeClass('has-error').addClass('has-success');
        resultElement.html(resultElement.data('success'));
        ga('send', 'event', 'newsletter_alpha', 'subscribe');
        // hide form
        wrapperElement.fadeOut(500);
      }
    },
    errorCallback: function($form) {
      // Disconnect.me extension blocks any JSONP requests.
      $form.unbind('submit').submit();
    }
  });
});
// defer bootstrap loading
window.name = "NG_DEFER_BOOTSTRAP!";