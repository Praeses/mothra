Equipment = Backbone.Model.extend
  EMPTY: "empty equipment...."

  initialize: ->
    unless @get 'content'
      @set 'content', @EMPTY

  toggle: ->
    @save done: !@get 'done'

  clear: ->
    @destroy()
    @view.remove()


EquipmentList = Backbone.Collection.extend
  model: Equipment
  localStorage: new Store 'equipments'

  done: ->
    @filter (equipment) -> 
      equipment.get 'done'
  
  remaining: ->
    @without.apply @, @done()

  nextOrder: ->
    return 1 unless @length
    return @last().get('order') + 1

  comparator: (equipment) ->
    equipment.get 'order'

Equipments = new EquipmentList()

EquipmentView = Backbone.View.extend
  tagName: 'li'
  template: _.template $('#item-template').html()

  events:
    'click .check':               'toggleDone'
    'dblclick div.todo-content':  'edit'
    'click span.todo-destroy':    'clear'
    'keypress .todo-input':       'updateOnEnter'

  initialize: ->
    _.bindAll @, 'render', 'close'
    @model.bind 'change', @render
    @model.view = @

  render: ->
    $(@el).html(@template(@model.toJSON()))
    @setContent()
    return @

  setContent: ->
    content = @model.get 'content'
    @$('.todo-content').text content
    @input = @$ '.todo-input'
    @input.bind 'blur', @close
    @input.val content

  toggleDone: ->
    @model.toggle()
  
  edit: ->
    $(@el).addClass 'editing'
    @input.focus()

  close: ->
    @model.save content: @input.val()
    $(@el).removeClass 'editing'

  updateOnEnter: (e) ->
    @close if e.keyCode == 13

  remove: ->
    $(@el).remove()

  clear: ->
    @model.clear()

AppView = Backbone.View.extend
  el: $ '#todoapp'

  statsTemplate: _.template $('#stats-template').html()

  events:
    'keypress #new-todo':   'createOnEnter'
    'keyup #new-todo':      'showTooltip'
    'click .todo-clear a':  'clearCompleted'

  initialize: ->
    _.bindAll @, 'addOne', 'addAll', 'render'
    @input = @$ '#new-todo'

    Equipments.bind 'add', @addOne
    Equipments.bind 'refresh', @addAll
    Equipments.bind 'all', @render

    Equipments.fetch()

  render: ->
    done = Equipments.done().length
    @$('#todo-stats').html(
      @statsTemplate 
        total:      Equipments.length
        done:       Equipments.done().length
        remaining:  Equipments.remaining().length
    )

  addOne: (equipment) ->
    view = new EquipmentView model: equipment
    @$('#todo-list').append view.render().el

  addAll: ->
    Equipments.each @addOne

  newAttributes: ->
    content:  @input.val()
    order:    Equipments.nextOrder()
    done:     false

  createOnEnter: (e) ->
    return null unless e.keyCode == 13
    Equipments.create @newAttributes()
    @input.val ''

  clearCompleted: ->
    _.each Equipments.done(), (equipment) -> equipment.clear()
    false

  showTooltip: (e) ->
    tooltip = @$ '.ui-tooltip-top'
    val = @input.val()
    tooltip.hide()
    clearTimeout @tooltipTimeout if @tooltipTimeout
    return null if val == '' or val == @input.attr 'placeholder'
    show = -> tooltip.show().show()
    @tooltipTimeout = _.delay show, 1000

App = new AppView
