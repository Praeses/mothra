(function() {
  var Store;
  window.Store = Store = (function() {
    function Store(channel, options) {
      var auth, that;
      this.options = options != null ? options : {
        bayeux: '/faye'
      };
      _.bindAll(this, 'on_message', 'request_auth');
      this.channel = '/models/' + channel;
      this.server_channel = '/server/models/' + channel;
      this.bayeux = new Faye.Client(this.options.bayeux);
      this.bayeux.subscribe(this.server_channel, this.on_message);
      this.authenticate = false;
      that = this;
      auth = {
        outgoing: function(message, callback) {
          console.log(message);
          if (message.channel !== '/meta/subscribe') {
            return callback(message);
          }
          return that.request_auth(message, callback);
        }
      };
      this.bayeux.addExtension(auth);
    }
    Store.prototype.request_auth = function(message, callback) {
      var that;
      if (!message.ext) {
        message.ext = {};
      }
      that = this;
      return $('#password').live('keydown', function(e) {
        if (e.keyCode === 13) {
          message.ext.username = $('#username').val();
          message.ext.password = $('#password').val();
          callback(message);
          return that.write({
            method: 'readAll'
          });
        }
      });
    };
    Store.prototype.write = function(message) {
      return this.bayeux.publish(this.channel, message);
    };
    Store.prototype.on_message = function(message) {
      $('.auth').hide();
      $('#create-equipment').show();
      return this[message.method](message.model);
    };
    Store.prototype.read = function(model) {
      if (this.collection.get(model)) {
        return this.collection.get(model).set(model);
      } else {
        return this.collection.add(model);
      }
    };
    Store.prototype.create = function(model) {
      return this.collection.add(model);
    };
    Store.prototype.update = function(model) {
      return this.collection.get(model).set(model);
    };
    Store.prototype["delete"] = function(model) {
      return this.collection.get(model).view.remove() && this.collection.remove(model);
    };
    return Store;
  })();
  Backbone.sync = function(method, model, success, error) {
    var message, store;
    if (model.fayeStorage != null) {
      method = 'readAll';
      store = model.fayeStorage;
      store.collection = model;
    } else {
      store = model.collection.fayeStorage;
      store.collection = model.collection;
    }
    message = {
      method: method,
      model: model
    };
    return store.write(message);
  };
}).call(this);
