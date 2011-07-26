(function() {
  var AppView, Equipment, EquipmentList, EquipmentView;
  var __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  }, __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  Equipment = (function() {
    __extends(Equipment, Backbone.Model);
    function Equipment() {
      Equipment.__super__.constructor.apply(this, arguments);
    }
    Equipment.prototype.checkout = function(user) {
      return this.save({
        who_has_it: user(!this.get('who_has_it'))
      });
    };
    return Equipment;
  })();
  EquipmentList = (function() {
    __extends(EquipmentList, Backbone.Collection);
    function EquipmentList() {
      EquipmentList.__super__.constructor.apply(this, arguments);
    }
    EquipmentList.prototype.model = Equipment;
    EquipmentList.prototype.fayeStorage = new Store('equipments');
    EquipmentList.prototype.nextOrder = function() {
      if (!this.length) {
        return 1;
      }
      return this.last().get('order') + 1;
    };
    EquipmentList.prototype.comparator = function(equipment) {
      return equipment.get('order');
    };
    return EquipmentList;
  })();
  EquipmentView = (function() {
    __extends(EquipmentView, Backbone.View);
    function EquipmentView() {
      this.close = __bind(this.close, this);
      this.destroy = __bind(this.destroy, this);
      this.set_input = __bind(this.set_input, this);
      this.setContent = __bind(this.setContent, this);
      this.render = __bind(this.render, this);
      EquipmentView.__super__.constructor.apply(this, arguments);
    }
    EquipmentView.prototype.tagName = 'li';
    EquipmentView.prototype.template = _.template($('#item-template').html());
    EquipmentView.prototype.events = {
      'dblclick .equipment': 'edit',
      'keyup .fields input': 'liveSave',
      'keyup .fields textarea': 'liveSave',
      'click .equipment-destroy': 'destroy'
    };
    EquipmentView.prototype.initialize = function() {
      this.model.bind('change', this.setContent);
      return this.model.view = this;
    };
    EquipmentView.prototype.render = function() {
      $(this.el).html(this.template(this.model.toJSON()));
      this.setContent();
      return this;
    };
    EquipmentView.prototype.setContent = function() {
      var tag, tags, _i, _len, _results;
      tags = ['asset_tag_number', 'make', 'model_number', 'serial_number', 'who_has_it', 'notes'];
      _results = [];
      for (_i = 0, _len = tags.length; _i < _len; _i++) {
        tag = tags[_i];
        _results.push(this.set_input(tag));
      }
      return _results;
    };
    EquipmentView.prototype.set_input = function(name) {
      this[name] = this.$("." + name);
      this[name].val(this.model.get(name));
      return this.$(".equipment-" + name).text(this.model.get(name));
    };
    EquipmentView.prototype.toggleDone = function() {
      return this.model.toggle();
    };
    EquipmentView.prototype.edit = function() {
      return $(this.el).addClass('editing');
    };
    EquipmentView.prototype.clear = function() {
      return this.model.clear();
    };
    EquipmentView.prototype.destroy = function() {
      return this.model.destroy();
    };
    EquipmentView.prototype.updatedAttributes = function() {
      return {
        asset_tag_number: this.asset_tag_number.val(),
        make: this.make.val(),
        model_number: this.model_number.val(),
        serial_number: this.serial_number.val(),
        notes: this.notes.val(),
        who_has_it: this.who_has_it.val()
      };
    };
    EquipmentView.prototype.close = function() {
      this.model.save(this.updatedAttributes());
      return $(this.el).removeClass('editing');
    };
    EquipmentView.prototype.liveSave = function(e) {
      this.model.save(this.updatedAttributes());
      if (e.keyCode === 13) {
        return this.close();
      }
    };
    return EquipmentView;
  })();
  AppView = (function() {
    __extends(AppView, Backbone.View);
    function AppView() {
      this.addAll = __bind(this.addAll, this);
      this.addOne = __bind(this.addOne, this);
      AppView.__super__.constructor.apply(this, arguments);
    }
    AppView.prototype.el = $('#equipmentapp');
    AppView.prototype.events = {
      'keyup .fields input': 'createOnEnter',
      'keyup .fields textarea': 'createOnEnter'
    };
    AppView.prototype.initialize = function() {
      this.asset_tag_number = this.$('#asset_tag_number');
      this.make = this.$('#make');
      this.model_number = this.$('#model_number');
      this.serial_number = this.$('#serial_number');
      this.notes = this.$('#notes');
      this.who_has_it = this.$('#who_has_it');
      Inventory.bind('add', this.addOne);
      Inventory.bind('refresh', this.addAll);
      return Inventory.bind('all', this.render);
    };
    AppView.prototype.addOne = function(equipment) {
      var view;
      view = new EquipmentView({
        model: equipment
      });
      return this.$('#equipment-list').append(view.render().el);
    };
    AppView.prototype.addAll = function() {
      return Inventory.each(this.addOne);
    };
    AppView.prototype.newAttributes = function() {
      return {
        asset_tag_number: this.$('#asset_tag_number').val(),
        make: this.$('#make').val(),
        model_number: this.$('#model_number').val(),
        serial_number: this.$('#serial_number').val(),
        notes: this.$('#notes').val(),
        who_has_it: this.$('#who_has_it').val(),
        order: Inventory.nextOrder()
      };
    };
    AppView.prototype.hasAttributes = function() {
      return this.$('#asset_tag_number').val() || this.$('#make').val() || this.$('#model_number').val() || this.$('#serial_number').val() || this.$('#notes').val() || this.$('#who_has_it').val();
    };
    AppView.prototype.createOnEnter = function(e) {
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
    };
    return AppView;
  })();
  window.Inventory = new EquipmentList();
  window.App = new AppView;
}).call(this);
