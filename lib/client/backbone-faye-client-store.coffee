# The Store 
# =========
# The Store is what will transfer the data back and forth between the client and
# the  server. Faye  is used  for communication.  Faye handles  all of  the hard
# stuff. It will  handle connection drops and reconnects. Also,  if data has not
# been sent in  a while Faye will  handle sending this data  when the connection
# has been re-established

# Connecting the store to the outside world
window.Store = class Store
  constructor: (channel, @options = { bayeux : '/faye'}) ->
    # Change the scope of `this` for the on_message method
    _.bindAll @, 'on_message'

    # There are two channels.  One for communication from the client to the
    # server and another from the server back to the client.
    @channel        = '/models/' + channel
    @server_channel = '/server/models/' + channel

    # Setup the Faye client.  By default it will listen on `/faye`.
    # All communication will go through this faye client.
    @bayeux = new Faye.Client @options.bayeux

    # To enable authentication we include the Auth class with the store. It is a
    # faye extention that will verify the  user and allow communication over the
    # faye pipe
    @auth = new Auth
    # Enabling the  auth is simple.  All that is needed  is to bind  the socket,
    # subscription and provide a callback when the auth fails
    @auth.bind @bayeux, @server_channel, @on_message

  # *write* will publish a message on  the model channel to the server. Messages
  # are simple `json` objects. There are two propertities to the message: method
  # and model. The  method expected are: `create`,  `update`, `read`, `readAll`,
  # and `destroy`. The model is either the collection or the single instance.
  write: (message) ->
    @bayeux.publish @channel, message

  # *on_message*  is where  we will  sync our  client side  models back  up. The
  # message  from the  server will  have all  the information  needed. Once  the
  # message  is received  it will  need to  trigger the  model update,  which is
  # handled nicely by backbone.
  on_message: (message) ->
    @[message.method] message.model

  # *read* handles two types. The first is where the model already exists in the
  # collection and the other is when the model doesn't exists. To handle both of
  # theses situations  all that is  needed to  do is check  to see if  the model
  # exists and then update it or create it
  read: (model) ->
    if @collection.get( model )
      @update model
    else
      @create model

  # *create* a  new model in the  collection. Backbone will fire  off `add` events
  # once this method is called. This will update the UI if they are hooked in.
  create: (model) -> @collection.add model
  # *update*  an  existing model  in  the  collection.  Backbone will  fire  off
  # `change` events when this operation is made.
  update: (model) -> @collection.get( model ).set model 
  # *delete* a model from the collection and remove the view.  The store will call view remove
  # because most models will be connected to a view, but will fail gracefully if it does not have
  # a model associated with it.  And then remove it from the collection.
  delete: (model) -> @collection.get( model ).view?.remove() and @collection.remove( model ) 

# Backbone sync OVERRIDE
# ----------------------
# The  sync method  is  what needs  to  be overridden  inorder  for backbone  to
# communicate  with the  server. Again  all communication  is going  to go  over
# `Faye` so all that  is needed here is to publish the  message accross the wire
# and we are complete. The callbacks won't do anything right now due to how faye
# handles communication.

# Backbone.sync takes in the method that will be performed, the model that called the 
# action, and two callbacks.  One for success and one for failure.
Backbone.sync = (method, model, success, error) ->
  # This way  we well  will easily  know if  the client  is requesting  a single
  # object or an array of objects.
  # Grab the collection type so that we can perform operations on it
  if model.fayeStorage?
    method           = 'readAll'
    store            = model.fayeStorage
    store.collection = model
  else
    store            = model.collection.fayeStorage
    store.collection = model.collection

  # Wrap what we want to send to the  server in an object NOTE: Other params may
  # be needed to help identify more about what is going on here.
  message = 
    method: method
    model:  model

  # Very simple  pass through  for the  faye server.  No work  is needed  on the
  # client side for any of the operations. We will just pass it through and then
  # update the records on the return message from the server.
  store.write message

