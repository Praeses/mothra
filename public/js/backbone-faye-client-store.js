(function() {
  var Store;
  window.Store = Store = (function() {
    function Store(channel, options) {
      this.options = options != null ? options : {
        bayeux: '/faye'
      };
      this.channel = '/models/' + channel;
      this.bayeux = new Faye.Client(this.options.bayeux);
      this.bayeux.subscribe(this.channel, this.on_message);
    }
    Store.prototype.write = function(message, success, error) {
      return this.bayeux.publish(this.channel, message);
    };
    Store.prototype.on_message = function(data) {
      var key, message, publish;
      message = JSON.parse(data);
      key = message.channel || message.collection || message.key;
      if (message.channel != null) {
        publish = message.data === Object ? message.data : JSON.parse(message.data);
      }
      return this.trigger("sync:" + key + ":data", publish);
    };
    return Store;
  })();
  Backbone.sync = function(method, model, success, error) {
    var message, store;
    if (model.fayeStorage != null) {
      method = 'readAll';
    }
    store = model.fayeStorage || model.collection.fayeStorage;
    message = {
      method: method,
      model: model
    };
    return store.write(message, success, error);
  };
}).call(this);
