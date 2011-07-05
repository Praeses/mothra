(function() {
  var Auth;
  window.Auth = Auth = (function() {
    function Auth() {
      _.bindAll(this, 'outgoing', 'success', 'errback');
    }
    Auth.prototype.outgoing = function(message, callback) {
      if (message.channel !== '/meta/subscribe') {
        return callback(message);
      }
      return this.request_auth(message, callback);
    };
    Auth.prototype.bind = function(bayeux, channel, callback) {
      this.bayeux = bayeux;
      this.channel = channel;
      this.callback = callback;
      this.bayeux.addExtension(this);
      return this.connect_subscription();
    };
    Auth.prototype.connect_subscription = function() {
      var _ref;
      if ((_ref = this.subscription) != null) {
        _ref.cancel();
      }
      this.subscription = this.bayeux.subscribe(this.channel, this.callback);
      this.subscription.callback(this.success);
      return this.subscription.errback(this.errback);
    };
    Auth.prototype.errback = function(err) {
      alert(err);
      return this.connect_subscription();
    };
    Auth.prototype.success = function() {
      $('.auth').hide();
      $('#create-equipment').show();
      return Inventory.fetch();
    };
    Auth.prototype.request_auth = function(message, callback) {
      if (!message.ext) {
        message.ext = {};
      }
      return $('#password').live('keydown', function(e) {
        if (e.keyCode === 13) {
          message.ext.username = $('#username').val();
          message.ext.password = $('#password').val();
          return callback(message);
        }
      });
    };
    return Auth;
  })();
}).call(this);
