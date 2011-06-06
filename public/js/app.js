(function() {
  var App, AppView, Equipment, EquipmentList, EquipmentView, Equipments;
  Equipment = Backbone.Model.extend({
    EMPTY: "empty equipment....",
    initialize: function() {
      if (!this.get('content')) {
        return this.set('content', this.EMPTY);
      }
    },
    toggle: function() {
      return this.save({
        done: !this.get('done')
      });
    },
    clear: function() {
      this.destroy();
      return this.view.remove();
    }
  });
  EquipmentList = Backbone.Collection.extend({
    model: Equipment,
    localStorage: new Store('equipments'),
    done: function() {
      return this.filter(function(equipment) {
        return equipment.get('done');
      });
    },
    remaining: function() {
      return this.without.apply(this, this.done());
    },
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
  Equipments = new EquipmentList();
  EquipmentView = Backbone.View.extend({
    tagName: 'li',
    template: _.template($('#item-template').html()),
    events: {
      'click .check': 'toggleDone',
      'dblclick div.todo-content': 'edit',
      'click span.todo-destroy': 'clear',
      'keypress .todo-input': 'updateOnEnter'
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
      var content;
      content = this.model.get('content');
      this.$('.todo-content').text(content);
      this.input = this.$('.todo-input');
      this.input.bind('blur', this.close);
      return this.input.val(content);
    },
    toggleDone: function() {
      return this.model.toggle();
    },
    edit: function() {
      $(this.el).addClass('editing');
      return this.input.focus();
    },
    close: function() {
      this.model.save({
        content: this.input.val()
      });
      return $(this.el).removeClass('editing');
    },
    updateOnEnter: function(e) {
      if (e.keyCode === 13) {
        return this.close;
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
    el: $('#todoapp'),
    statsTemplate: _.template($('#stats-template').html()),
    events: {
      'keypress #new-todo': 'createOnEnter',
      'keyup #new-todo': 'showTooltip',
      'click .todo-clear a': 'clearCompleted'
    },
    initialize: function() {
      _.bindAll(this, 'addOne', 'addAll', 'render');
      this.input = this.$('#new-todo');
      Equipments.bind('add', this.addOne);
      Equipments.bind('refresh', this.addAll);
      Equipments.bind('all', this.render);
      return Equipments.fetch();
    },
    render: function() {
      var done;
      done = Equipments.done().length;
      return this.$('#todo-stats').html(this.statsTemplate({
        total: Equipments.length,
        done: Equipments.done().length,
        remaining: Equipments.remaining().length
      }));
    },
    addOne: function(equipment) {
      var view;
      view = new EquipmentView({
        model: equipment
      });
      return this.$('#todo-list').append(view.render().el);
    },
    addAll: function() {
      return Equipments.each(this.addOne);
    },
    newAttributes: function() {
      return {
        content: this.input.val(),
        order: Equipments.nextOrder(),
        done: false
      };
    },
    createOnEnter: function(e) {
      if (e.keyCode !== 13) {
        return null;
      }
      Equipments.create(this.newAttributes());
      return this.input.val('');
    },
    clearCompleted: function() {
      _.each(Equipments.done(), function(equipment) {
        return equipment.clear();
      });
      return false;
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
}).call(this);
