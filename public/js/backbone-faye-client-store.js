(function() {
  var Store;
  window.Store = Store = (function() {
    function Store(channel, options) {
      this.options = options != null ? options : {
        bayeux: '/faye'
      };
      _.bindAll(this, 'on_message');
      this.channel = '/models/' + channel;
      this.server_channel = '/server/models/' + channel;
      this.bayeux = new Faye.Client(this.options.bayeux);
      this.bayeux.subscribe(this.server_channel, this.on_message);
    }
    Store.prototype.write = function(message) {
      return this.bayeux.publish(this.channel, message);
    };
    Store.prototype.on_message = function(message) {
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
