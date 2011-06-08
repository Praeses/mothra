# This model will hold the methods that will control what equipment does.
# Equipment has several fiels they are:
#   - asset_tag_number 
#   - make 
#   - model 
#   - serial_number 
#   - who_has_it
#   - notes 
#
# Equipment can be reserved ( allowing some one to check it out )
# and equipment must be returned.
Equipment = Backbone.Model.extend

  initialize: ->

  checkout: (user)->
    # We are only going to allow checking out a piece of equipment 
    # if it isn't already checked out.
    # NOTE: This could change for simplicity
    @save who_has_it: user !@get 'who_has_it'

# Equipment List maintains the CRUD for equipment.  In this model the
# `Store` is defined.  Right now it is a local store which will need to be
# rewritten to use `Redis` in `pub/sub` mode.
EquipmentList = Backbone.Collection.extend
  # Defining the model this collection will use ( this is a must )
  model: Equipment
  # Defining how we want the collection to persist
  localStorage: new Store 'equipments'

  # helper to keep order on the page
  nextOrder: ->
    return 1 unless @length
    return @last().get('order') + 1

  # Default compare
  comparator: (equipment) ->
    equipment.get 'order'

# The actual instance to perform the CRUD
Inventory = new EquipmentList()

# Setting up the views for the individual piece of equipment.
# In this class we will define events that will occur on the elements
# and how to respond to them.
EquipmentView = Backbone.View.extend
  tagName: 'li'
  # This is the template for the piece of equipment
  template: _.template $('#item-template').html()

  events:
    'click .check':                    'toggleDone'
    'dblclick div.equipment-content':  'edit'
    'click span.equipment-destroy':    'clear'
    'keypress .equipment-input':       'updateOnEnter'

  initialize: ->
    _.bindAll @, 'render', 'close'
    # When ever the model changes we will want to re-render this html element
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
    # Hooking in the enter key
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
    @asset_tag_number = @$ '#asset_tag_number'
    @make             = @$ '#make'
    @model            = @$ '#model'
    @serial_number    = @$ '#serial_number'
    @notes            = @$ '#notes'
    @who_has_it       = @$ '#who_has_it'

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
    asset_tag_number: 
    make: 
    model: 
    serial_number: 
    notes: 
    who_has_it: 
    order:    Inventory.nextOrder()

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
