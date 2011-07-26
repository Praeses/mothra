# The Equipment
# ---------
# The equipment  is at the  heart of *Mothra*. This  is what mothra  keeps track
# of...it is an  inventory application is model will hold  the methods that will
# control what equipment does. This is version one of the application and all it
# will do now is keep track of who checked it out with the fields below.
#
# Equipment has several fiels they are:
#
# -  asset\_tag\_number
# -  make
# -  model_number
# -  serial_number
# -  who\_has\_it
# -  notes

# Equipment can be reserved ( allowing some one to check it out )
# and equipment must be returned.
class Equipment extends Backbone.Model

  # We are only going to allow checking out a piece of equipment
  # if it isn't already checked out.
  # NOTE: This could change for simplicity.
  # NOTE: This doesn't do anything right now.
  checkout: (user) ->
    @save who_has_it: user !@get 'who_has_it'

# The Equipment List a.k.a Inventory
# ---------------------------------
# Equipment List  maintains the `CRUD` for  equipment...well...in backbone there
# is a  method called  `sync`. The  `sync` method is  what actual  initiates the
# `CRUD`. The sync  method is overriden using the included  `Store`. The `Store`
# contains logic  to preform the `CRUD`  methods. This store uses  `pub/sub/` on
# websockets. This way  all communication will be published to  all clients when
# any piece of `Equipment` is created, updated, or deleted.

# This is the definition of the Inventory
class EquipmentList extends Backbone.Collection
  # Defining the model this collection will use ( this is a must )
  model: Equipment
  # Defining how we want the collection to persist
  fayeStorage: new Store 'equipments'

  # helper to  keep order on  the page.  Yeah we have  to do some  special logic
  # inorder to figure out what the next order will be.
  nextOrder: ->
    return 1 unless @length
    @last().get('order') + 1

  # If we want to sort on the order this will be needed. I like it. It is simple
  # and does the job. It's an order field.
  comparator: (equipment) ->
    equipment.get 'order'

# The Equipment View
# ------------------
# Setting up the views  for the individual piece of equipment.  In this class we
# will define events that will occur on the elements and how to respond to them.

# A single `li` element for an individual piece of equipment
class EquipmentView extends Backbone.View
  tagName: 'li'
  # This is the template for the piece of equipment
  template: _.template $('#item-template').html()

  # AHHHHHHHhhhhhhhh!!!!......events.  They do stuff when you do stuff.
  # Therefore lots of stuff will get done....by events.
  events:
    'dblclick .equipment':       'edit'
    'keyup .fields input' :      'liveSave'
    'keyup .fields textarea':    'liveSave'
    'click .equipment-destroy':  'destroy'

  # Everything has a  starting point and the initialize method  starts this one.
  # Here we do some basic hookups and stuff.
  initialize: ->
    # When ever the model changes we will want to re-render this html element
    @model.bind 'change', @setContent
    @model.view = @

  # Perform this action once.  This will render the element on the page
  render: =>
    $(@el).html @template @model.toJSON()
    @setContent()
    return @

  # Set all the items on the page
  setContent: =>
    tags = [
      'asset_tag_number'
      'make'
      'model_number'
      'serial_number'
      'who_has_it'
      'notes'
    ]
    @set_input tag for tag in tags

  # Set the input for each  of the fields the meta way. Its a  lot of code and I
  # am lazy. So I do not want to write  that much code, I like methods to do the
  # work for me so that I do not have to do it that much. That's the way I roll.
  set_input: (name) =>
    @[name] = @$ ".#{name}"
    @[name].val @model.get name
    @$(".equipment-#{name}").text @model.get name


  toggleDone:  -> @model.toggle()
  edit:        -> $(@el).addClass 'editing'
  clear:       -> @model.clear()
  destroy:     => @model.destroy()

  # Create an object that  will contain all the properties to  be updated on the
  # piece of equipment.
  updatedAttributes: ->
    asset_tag_number:  @asset_tag_number.val()
    make:              @make.val()
    model_number:      @model_number.val()
    serial_number:     @serial_number.val()
    notes:             @notes.val()
    who_has_it:        @who_has_it.val()

  # Close the editing pane and update the model
  close: =>
    @model.save @updatedAttributes()
    $(@el).removeClass 'editing'

  # When the  user presses  any key  the piece  of equipment  will be  saved and
  # published out to all users. If the user presses the enter key then close the
  # editing pane.
  liveSave: (e) ->
    @model.save @updatedAttributes()
    @close() if e.keyCode is 13

# The App View
# ------------
# The app  view is  the main view  of the inventory  application. This  is where
# inventory will be crated and added to the list.

# Connecting the app to the `div`
class AppView extends Backbone.View
  el: $ '#equipmentapp'

  # Events to hook in to equipment creation.
  events:
    'keyup .fields input' :      'createOnEnter'
    'keyup .fields textarea':    'createOnEnter'

  initialize: ->
    @asset_tag_number = @$ '#asset_tag_number'
    @make             = @$ '#make'
    @model_number     = @$ '#model_number'
    @serial_number    = @$ '#serial_number'
    @notes            = @$ '#notes'
    @who_has_it       = @$ '#who_has_it'

    # Binding the  Inventory to  the UI. This  is how we  make some  magic. When
    # stuff occurs with the inventory we are going to do stuff with the UI.
    Inventory.bind 'add'     , @addOne
    Inventory.bind 'refresh' , @addAll
    Inventory.bind 'all'     , @render

  # Adding in logic to do when a single item is added to the view
  addOne: (equipment) =>
    view = new EquipmentView model: equipment
    @$('#equipment-list').append view.render().el

  # Adding in logic to add inventory when there is a refresh of all inventory
  addAll: => Inventory.each @addOne

  # Creating a hash of all the attributes on the form
  newAttributes: ->
    asset_tag_number:  @$( '#asset_tag_number' ).val()
    make:              @$( '#make' ).val()
    model_number:      @$( '#model_number' ).val()
    serial_number:     @$( '#serial_number' ).val()
    notes:             @$( '#notes' ).val()
    who_has_it:        @$( '#who_has_it' ).val()
    order:             Inventory.nextOrder()

  # Determining if  there are any  attributes there to save.  Do you like  how I
  # line up everything?
  hasAttributes: ->
    @$( '#asset_tag_number' ).val() or
    @$( '#make' ).val()             or
    @$( '#model_number' ).val()     or
    @$( '#serial_number' ).val()    or
    @$( '#notes' ).val()            or
    @$( '#who_has_it' ).val()

  # Creating a new record when there are attributes and the enter key is pressed
  createOnEnter: (e) ->
    return null unless @hasAttributes()
    return null unless e.keyCode is 13
    Inventory.create @newAttributes()
    @asset_tag_number.val('')
    @make.val('')
    @model_number.val('')
    @serial_number.val('')
    @notes.val('')
    @who_has_it.val('')

# The actual instance to perform the CRUD
window.Inventory = new EquipmentList()
# Starting the application
window.App = new AppView
