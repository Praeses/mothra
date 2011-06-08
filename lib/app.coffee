# This model will hold the methods that will control what equipment does.
# Equipment has several fiels they are:
#   - asset_tag_number 
#   - make 
#   - model_number 
#   - serial_number 
#   - who_has_it
#   - notes 
#
# Equipment can be reserved ( allowing some one to check it out )
# and equipment must be returned.
Equipment = Backbone.Model.extend

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
    'dblclick div.equipment':  'edit'
    'keypress .asset_tag_number':      'updateOnEnter'
    'keypress .make':                  'updateOnEnter'
    'keypress .model_number':          'updateOnEnter'
    'keypress .serial_number':         'updateOnEnter'
    'keypress .notes':                 'updateOnEnter'
    'keypress .who_has_it':            'updateOnEnter'

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
    @$('.equipment-asset_tag_number').text @model.get 'asset_tag_number'
    @$('.equipment-make').text @model.get 'make'
    @$('.equipment-model_number').text @model.get 'model_number'
    @$('.equipment-serial_number').text @model.get 'serial_number'
    @$('.equipment-who_has_it').text @model.get 'who_has_it'
    @$('.equipment-notes').text @model.get 'notes'

    @asset_tag_number = @$ '.asset_tag_number'
    @make             = @$ '.make'
    @model_number     = @$ '.model_number'
    @serial_number    = @$ '.serial_number'
    @who_has_it       = @$ '.who_has_it'
    @notes            = @$ '.notes'

    #@asset_tag_number.bind 'blur', @close
    #@make.bind 'blur', @close
    #@model_number.bind 'blur', @close
    #@serial_number.bind 'blur', @close
    #@who_has_it.bind 'blur', @close
    #@notes.bind 'blur', @close

    @asset_tag_number.val @model.get 'asset_tag_number'
    @make.val @model.get 'make'
    @model_number.val @model.get 'model_number'
    @serial_number.val @model.get 'serial_number'
    @who_has_it.val @model.get 'who_has_it'
    @notes.val @model.get 'notes'


  toggleDone: ->
    @model.toggle()
  
  edit: ->
    $(@el).addClass 'editing'

  updatedAttributes: ->
    asset_tag_number:  @asset_tag_number.val()
    make:              @make.val()
    model_number:      @model_number.val()
    serial_number:     @serial_number.val()
    notes:             @notes.val()
    who_has_it:        @who_has_it.val()

  close: ->
    @model.save @updatedAttributes()
    $(@el).removeClass 'editing'

  updateOnEnter: (e) ->
    # Hooking in the enter key
    @close() if e.keyCode is 13

  remove: ->
    $(@el).remove()

  clear: ->
    @model.clear()

AppView = Backbone.View.extend
  el: $ '#equipmentapp'

  statsTemplate: _.template $('#stats-template').html()

  events:
    'keypress #asset_tag_number':  'createOnEnter'
    'keypress #make':              'createOnEnter'
    'keypress #model_number':      'createOnEnter'
    'keypress #serial_number':     'createOnEnter'
    'keypress #notes':             'createOnEnter'
    'keypress #who_has_it':        'createOnEnter'

  initialize: ->
    _.bindAll @, 'addOne', 'addAll', 'render'
    @asset_tag_number = @$ '#asset_tag_number'
    @make             = @$ '#make'
    @model_number            = @$ '#model_number'
    @serial_number    = @$ '#serial_number'
    @notes            = @$ '#notes'
    @who_has_it       = @$ '#who_has_it'

    Inventory.bind 'add', @addOne
    Inventory.bind 'refresh', @addAll
    Inventory.bind 'all', @render

    Inventory.fetch()


  addOne: (equipment) ->
    view = new EquipmentView model: equipment
    @$('#equipment-list').append view.render().el

  addAll: ->
    Inventory.each @addOne

  newAttributes: ->
    asset_tag_number:  @$( '#asset_tag_number' ).val()
    make:              @$( '#make' ).val()
    model_number:      @$( '#model_number' ).val()
    serial_number:     @$( '#serial_number' ).val()
    notes:             @$( '#notes' ).val()
    who_has_it:        @$( '#who_has_it' ).val()
    order:             Inventory.nextOrder()

  createOnEnter: (e) ->
    return null unless e.keyCode is 13
    Inventory.create @newAttributes()
    @asset_tag_number.val('') 
    @make.val('')             
    @model_number.val('')           
    @serial_number.val('')
    @notes.val('')
    @who_has_it.val('')     


  showTooltip: (e) ->
    tooltip = @$ '.ui-tooltip-top'
    val = @input.val()
    tooltip.hide()
    clearTimeout @tooltipTimeout if @tooltipTimeout
    return null if val is '' or val is @input.attr 'placeholder'
    show = -> tooltip.show().show()
    @tooltipTimeout = _.delay show, 1000

App = new AppView