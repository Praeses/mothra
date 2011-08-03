(function() {
  var AppView, Equipment, EquipmentList, EquipmentView;
  Equipment = Backbone.Model.extend({
    checkout: function(user) {
      return this.save({
        who_has_it: user(!this.get('who_has_it'))
      });
    }
  });
  EquipmentList = Backbone.Collection.extend({
    model: Equipment,
    fayeStorage: new Store('equipments'),
    nextOrder: function() {
      if (!this.length) {
        return 1;
      }
      return this.last().get('order') + 1;
    },
    comparator: function(equipment) {
      return equipment.get('order');
    }
  });
  EquipmentView = Backbone.View.extend({
    tagName: 'li',
    template: _.template($('#item-template').html()),
    events: {
      'dblclick .equipment': 'edit',
      'keyup .fields input': 'liveSave',
      'keyup .fields textarea': 'liveSave',
      'click .equipment-destroy': 'destroy'
    },
    initialize: function() {
      _.bindAll(this, 'render', 'close', 'setContent', 'destroy', 'set_input');
      this.model.bind('change', this.setContent);
      return this.model.view = this;
    },
    render: function() {
      $(this.el).html(this.template(this.model.toJSON()));
      this.setContent();
      return this;
    },
    setContent: function() {
      var tag, tags, _i, _len, _results;
      tags = ['asset_tag_number', 'make', 'model_number', 'serial_number', 'who_has_it', 'notes'];
      _results = [];
      for (_i = 0, _len = tags.length; _i < _len; _i++) {
        tag = tags[_i];
        _results.push(this.set_input(tag));
      }
      return _results;
    },
    set_input: function(name) {
      this[name] = this.$("." + name);
      this[name].val(this.model.get(name));
      return this.$(".equipment-" + name).text(this.model.get(name));
    },
    toggleDone: function() {
      return this.model.toggle();
    },
    edit: function() {
      return $(this.el).addClass('editing');
    },
    clear: function() {
      return this.model.clear();
    },
    destroy: function() {
      return this.model.destroy();
    },
    updatedAttributes: function() {
      return {
        asset_tag_number: this.asset_tag_number.val(),
        make: this.make.val(),
        model_number: this.model_number.val(),
        serial_number: this.serial_number.val(),
        notes: this.notes.val(),
        who_has_it: this.who_has_it.val()
      };
    },
    close: function() {
      this.model.save(this.updatedAttributes());
      return $(this.el).removeClass('editing');
    },
    liveSave: function(e) {
      this.model.save(this.updatedAttributes());
      if (e.keyCode === 13) {
        return this.close();
      }
    }
  });
  AppView = Backbone.View.extend({
    el: $('#equipmentapp'),
    events: {
      'keyup .fields input': 'createOnEnter',
      'keyup .fields textarea': 'createOnEnter'
    },
    initialize: function() {
      _.bindAll(this, 'addOne', 'addAll', 'render');
      this.asset_tag_number = this.$('#asset_tag_number');
      this.make = this.$('#make');
      this.model_number = this.$('#model_number');
      this.serial_number = this.$('#serial_number');
      this.notes = this.$('#notes');
      this.who_has_it = this.$('#who_has_it');
      Inventory.bind('add', this.addOne);
      Inventory.bind('refresh', this.addAll);
      return Inventory.bind('all', this.render);
    },
    addOne: function(equipment) {
      var view;
      view = new EquipmentView({
        model: equipment
      });
      return this.$('#equipment-list').append(view.render().el);
    },
    addAll: function() {
      return Inventory.each(this.addOne);
    },
    newAttributes: function() {
      return {
        asset_tag_number: this.$('#asset_tag_number').val(),
        make: this.$('#make').val(),
        model_number: this.$('#model_number').val(),
        serial_number: this.$('#serial_number').val(),
        notes: this.$('#notes').val(),
        who_has_it: this.$('#who_has_it').val(),
        order: Inventory.nextOrder()
      };
    },
    hasAttributes: function() {
      return this.$('#asset_tag_number').val() || this.$('#make').val() || this.$('#model_number').val() || this.$('#serial_number').val() || this.$('#notes').val() || this.$('#who_has_it').val();
    },
    createOnEnter: function(e) {
      if (!this.hasAttributes()) {
        return null;
      }
      if (e.keyCode !== 13) {
        return null;
      }
      Inventory.create(this.newAttributes());
      this.asset_tag_number.val('');
      this.make.val('');
      this.model_number.val('');
      this.serial_number.val('');
      this.notes.val('');
      return this.who_has_it.val('');
    }
  });
  window.Inventory = new EquipmentList();
  window.App = new AppView;
}).call(this);
