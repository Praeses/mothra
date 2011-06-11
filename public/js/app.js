(function() {
  var App, AppView, ButtonView, Equipment, EquipmentList, EquipmentView, Inventory, button;
  Equipment = Backbone.Model.extend({
    checkout: function(user) {
      return this.save({
        who_has_it: user(!this.get('who_has_it'))
      });
    }
  });
  EquipmentList = Backbone.Collection.extend({
    model: Equipment,
    localStorage: new Store('equipments'),
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
      'keypress .asset_tag_number': 'updateOnEnter',
      'keypress .make': 'updateOnEnter',
      'keypress .model_number': 'updateOnEnter',
      'keypress .serial_number': 'updateOnEnter',
      'keypress .notes': 'updateOnEnter',
      'keypress .who_has_it': 'updateOnEnter'
    },
    initialize: function() {
      _.bindAll(this, 'render', 'close');
      this.model.bind('change', this.render);
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
    updateOnEnter: function(e) {
      if (e.keyCode === 13) {
        return this.close();
      }
    },
    remove: function() {
      return $(this.el).remove();
    },
    clear: function() {
      return this.model.clear();
    }
  });
  AppView = Backbone.View.extend({
    el: $('#equipmentapp'),
    statsTemplate: _.template($('#stats-template').html()),
    events: {
      'keypress #asset_tag_number': 'createOnEnter',
      'keypress #make': 'createOnEnter',
      'keypress #model_number': 'createOnEnter',
      'keypress #serial_number': 'createOnEnter',
      'keypress #notes': 'createOnEnter',
      'keypress #who_has_it': 'createOnEnter'
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
  ButtonView = Backbone.View.extend({
    render: function() {
      var canvases;
      canvases = $('.checkout');
      return canvases.each(function(i, canvas) {
        var a, cost_r, ctx, drawDrop, drawFrame, droping, f_t, img, rt, running_interval;
        ctx = canvas.getContext('2d');
        ctx.translate(250, 50);
        img = new Image();
        img.src = '../images/checkout.png';
        rt = 0;
        a = 1.5;
        cost_r = null;
        running_interval = null;
        droping = false;
        f_t = 0;
        drawFrame = function() {
          ctx.clearRect(-400, -400, 800, 800);
          ctx.rotate(Math.cos(rt) * a);
          rt = rt + .02;
          if (a > 0) {
            a = a - 0.001;
          }
          if (rt >= (Math.PI * 2)) {
            rt = 0;
          }
          ctx.rotate(-Math.cos(rt) * a);
          return ctx.drawImage(img, 0, 0, 200, 50);
        };
        drawDrop = function() {
          var displacement, displacement_last, g, volocity, volocity_last;
          f_t = f_t + 1;
          g = 9.8;
          ctx.clearRect(-400, -400, 800, 800);
          ctx.rotate(Math.cos(rt) * a);
          volocity = f_t * g;
          volocity_last = (f_t - 1) * g;
          displacement = (volocity * volocity) / (2 * g);
          displacement_last = (volocity_last * volocity_last) / (2 * g);
          ctx.translate((displacement - displacement_last) / 30, 0);
          ctx.rotate(-Math.cos(rt + .005) * a);
          return ctx.drawImage(img, 0, 0, 200, 50);
        };
        img.onload = function() {
          return drawFrame();
        };
        return canvas.onclick = function() {
          var start_drop, start_swing, stop_drop;
          start_swing = function() {
            ctx.canvas.width = 800;
            ctx.canvas.height = 800;
            ctx.translate(250, 50);
            return setInterval(drawFrame, 10);
          };
          start_drop = function() {
            return setInterval(drawDrop, 10);
          };
          stop_drop = function() {
            clearInterval(running_interval);
            return $('.checkout').remove();
          };
          if (running_interval === null) {
            return running_interval = start_swing();
          } else if (droping === false) {
            droping = true;
            clearInterval(running_interval);
            running_interval = start_drop();
            return setTimeout(stop_drop, 3000);
          }
        };
      });
    }
  });
  button = new ButtonView;
  _.delay(button.render, 1000);
}).call(this);
