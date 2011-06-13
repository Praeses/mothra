require 'faye'

class Store
  constructor: (@channel, @options = { bayeux : '/backbone-faye'}) ->
    # Setup the Faye client.  By default it will listen on `/backbone-faye`.
    @bayeux   = new Faye.Client @options.bayeux
    # Subscribe to the channel for this store.  An example would be
    # using the plural name of the model for the channel
    # This way we can have each collection seperated on a different 
    # channel to help simplify the communication to the server.
    @bayeux.subscribe @channel, on_message

  # Helper to write a message to the server.
  write: (message, success, error) ->
    message = message.toJSON() if message.toJSON() is 'function'
    # NOTE: need to figure out a way to determine if this worked
    # or not.  This should be in the documentation for the faye
    # protocal.
    @bayeux.publish @channel, message

  # This is where we will sync our client side models back up.
  # The message from the server will have all the information 
  # needed.
  on_message: (data) ->
    message = JSON.parse data
    key = message.channel or message.collection or message.key
    # Now we know that we have a good message from the server
    if message.channel?
      publish = if message.data is Object
        message.data
      else
        JSON.parse message.data

    # Triggering the correct event will update the given model(s)
    # in the collection.  This will occur when ever anyone updates
    # any model in the system.  Either client side or server side.
    @trigger "sync:#{ key }:data", publish

Backbone.sync = (method, model, success, error) ->
  # Wrap what we want to send to the server in an object
  # NOTE: Other params may be needed to help identify more 
  # about what is going on here.
  messsage = 
    method: method
    model: model

  # Very simple pass through for the faye server.  No work
  # is needed on the client side for any of the operations.
  # We will just pass it through and then update the records on
  # the return message from the server.
  model.fayeStorage.write message, success, error



