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
      this.handlers = {};
    }
    Store.prototype.on = function(name, callback) {
      var _base;
      (_base = this.handlers)[name] || (_base[name] = []);
      console.log(this.handlers);
      return this.handlers[name].push(callback);
    };
    Store.prototype.trigger = function() {
      var a, args, callback, callbacks, name, _i, _j, _len, _len2, _results;
      args = [];
      for (_i = 0, _len = arguments.length; _i < _len; _i++) {
        a = arguments[_i];
        args.push(a);
      }
      name = args.shift();
      callbacks = this.handlers[name];
      _results = [];
      for (_j = 0, _len2 = callbacks.length; _j < _len2; _j++) {
        callback = callbacks[_j];
        _results.push(callback.apply(this, args));
      }
      return _results;
    };
    Store.prototype.write = function(message, callback) {
      this.on('sync', callback);
      return this.bayeux.publish(this.channel, message);
    };
    Store.prototype.on_message = function(data) {
      return this.trigger('sync', data);
    };
    return Store;
  })();
  Backbone.sync = function(method, model, success, error) {
    var message, store, syncCallback;
    syncCallback = function(message) {
      if (model === Backbone.Model) {
        switch (message.method) {
          case 'update':
            return model.set(message.model);
          case 'delete':
            return model.view.remove();
        }
      } else {
        switch (message.method) {
          case 'read':
            if (model.get(message.model)) {
              return model.get(message.model).set(message.model);
            } else {
              return model.add(message.model);
            }
            break;
          case 'create':
            return model.add(message.model);
          case 'update':
            return model.get(message.model).set(message.model);
          case 'delete':
            return model.remove(message.model);
        }
      }
    };
    if (model.fayeStorage != null) {
      method = 'readAll';
    }
    store = model.fayeStorage || model.collection.fayeStorage;
    message = {
      method: method,
      model: model
    };
    return store.write(message, syncCallback);
  };
}).call(this);
