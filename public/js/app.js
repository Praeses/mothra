(function() {
  var App, AppView, Equipment, EquipmentList, EquipmentView, Inventory;
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
  Inventory = new EquipmentList();
  EquipmentView = Backbone.View.extend({
    tagName: 'li',
    template: _.template($('#item-template').html()),
    events: {
      'dblclick div.equipment': 'edit',
      'keyup #fields input': 'liveSave',
      'keyup #fields textarea': 'liveSave',
      'click .equipment-destroy': 'destroy'
    },
    initialize: function() {
      _.bindAll(this, 'render', 'close', 'setContent', 'destroy');
      this.model.bind('change', this.setContent);
      return this.model.view = this;
    },
    render: function() {
      $(this.el).html(this.template(this.model.toJSON()));
      this.setContent();
      return this;
    },
    setContent: function() {
      this.$('.equipment-asset_tag_number').text(this.model.get('asset_tag_number'));
      this.$('.equipment-make').text(this.model.get('make'));
      this.$('.equipment-model_number').text(this.model.get('model_number'));
      this.$('.equipment-serial_number').text(this.model.get('serial_number'));
      this.$('.equipment-who_has_it').text(this.model.get('who_has_it'));
      this.$('.equipment-notes').text(this.model.get('notes'));
      this.asset_tag_number = this.$('.asset_tag_number');
      this.make = this.$('.make');
      this.model_number = this.$('.model_number');
      this.serial_number = this.$('.serial_number');
      this.who_has_it = this.$('.who_has_it');
      this.notes = this.$('.notes');
      this.asset_tag_number.val(this.model.get('asset_tag_number'));
      this.make.val(this.model.get('make'));
      this.model_number.val(this.model.get('model_number'));
      this.serial_number.val(this.model.get('serial_number'));
      this.who_has_it.val(this.model.get('who_has_it'));
      return this.notes.val(this.model.get('notes'));
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
      'keyup #fields input': 'createOnEnter',
      'keyup #fields textarea': 'createOnEnter'
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
      Inventory.bind('all', this.render);
      return Inventory.fetch();
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
    createOnEnter: function(e) {
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
    },
    showTooltip: function(e) {
      var show, tooltip, val;
      tooltip = this.$('.ui-tooltip-top');
      val = this.input.val();
      tooltip.hide();
      if (this.tooltipTimeout) {
        clearTimeout(this.tooltipTimeout);
      }
      if (val === '' || val === this.input.attr('placeholder')) {
        return null;
      }
      show = function() {
        return tooltip.show().show();
      };
      return this.tooltipTimeout = _.delay(show, 1000);
    }
  });
  App = new AppView;
  $('img').each(function(i, c) {
    return c.onclick = function() {
      return $(c).ImageDrop();
    };
  });
}).call(this);
