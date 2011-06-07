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

Inventory = new EquipmentList()

EquipmentView = Backbone.View.extend
  tagName: 'li'
  template: _.template $('#item-template').html()

  events:
    'click .check':               'toggleDone'
    'dblclick div.equipment-content':  'edit'
    'click span.equipment-destroy':    'clear'
    'keypress .equipment-input':       'updateOnEnter'

  initialize: ->
    _.bindAll @, 'render', 'close'
    @model.bind 'change', @render
    @model.view = @

  render: ->
    $(@el).html @template @model.toJSON()
    @setContent()
    return @

  setContent: ->
    content = @model.get 'content'
    @$('.equipment-content').text content
    @input = @$ '.equipment-input'
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
  el: $ '#equipmentapp'

  statsTemplate: _.template $('#stats-template').html()

  events:
    'keypress #new-equipment':   'createOnEnter'
    'keyup #new-equipment':      'showTooltip'
    'click .equipment-clear a':  'clearCompleted'

  initialize: ->
    _.bindAll @, 'addOne', 'addAll', 'render'
    @input = @$ '#new-equipment'

    Inventory.bind 'add', @addOne
    Inventory.bind 'refresh', @addAll
    Inventory.bind 'all', @render

    Inventory.fetch()

  render: ->
    done = Inventory.done().length
    @$('#equipment-stats').html(
      @statsTemplate 
        total:      Inventory.length
        done:       Inventory.done().length
        remaining:  Inventory.remaining().length
    )

  addOne: (equipment) ->
    view = new EquipmentView model: equipment
    @$('#equipment-list').append view.render().el

  addAll: ->
    Inventory.each @addOne

  newAttributes: ->
    content:  @input.val()
    order:    Inventory.nextOrder()
    done:     false

  createOnEnter: (e) ->
    return null unless e.keyCode == 13
    Inventory.create @newAttributes()
    @input.val ''

  clearCompleted: ->
    _.each Inventory.done(), (equipment) -> equipment.clear()
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
