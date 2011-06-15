(function() {
  var Store;
  Store = (function() {
    function Store(channel, options) {
      this.options = options != null ? options : {
        bayeux: '/backbone-faye'
      };
      this.channel = '/models/' + channel;
      this.bayeux = new Faye.Client(this.options.bayeux);
      this.bayeux.subscribe(this.channel, on_message);
    }
    Store.prototype.write = function(message, success, error) {
      if (message.toJSON() === 'function') {
        message = message.toJSON();
      }
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
    var messsage;
    messsage = {
      method: method,
      model: model
    };
    return model.fayeStorage.write(message, success, error);
  };
}).call(this);
