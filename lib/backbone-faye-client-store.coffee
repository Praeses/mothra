# The Store 
# =========
# The Store is what will transfer the data back and forth between the client and
# the  server. Faye  is used  for communication.  Faye handles  all of  the hard
# stuff. It will  handle connection drops and reconnects. Also,  if data has not
# been sent in  a while Faye will  handle sending this data  when the connection
# has been re-established
window.Store = class Store
  constructor: (channel, @options = { bayeux : '/faye'}) ->
    @channel = '/models/' + channel
    # Setup the Faye client.  By default it will listen on `/faye`.
    # All communication will go through this faye client.
    @bayeux   = new Faye.Client @options.bayeux
    # Subscribe  to the  channel  for  this store.  An  example  would be  using
    # the  plural name  of  the model  for  the  channel This  way  we can  have
    # each  collection seperated  on a  different channel  to help  simplify the
    # communication to the server.
    @bayeux.subscribe @channel, @on_message

  # Publishing  a message  to the  server. If  the message  is a  `function` the
  # system will  first convert it  to json and  then send the  message. Messages
  # should be json.
  write: (message, success, error) ->
    # message = message.toJSON() if message.toJSON() is 'function'
    # NOTE: need to  figure out a way  to determine if this worked  or not. This
    # should be in the documentation for the faye protocal.
    @bayeux.publish @channel, message

  # This is where we will sync our  client side models back up. The message from
  # the  server will  have  all  the information  needed.  Once  the message  is
  # received it will need to trigger the model update.
  on_message: (data) ->
    message = JSON.parse data
    # Grab the key from the message. This will  tell us if the message was for a
    # collection update, model update, or another type of communication.
    key = message.channel or message.collection or message.key
    
    # If the message is from the channel then  we need to pull out the json from
    # the message.
    if message.channel?
      publish = if message.data is Object
        message.data
      else
        JSON.parse message.data

    # Triggering  the  correct event  will  update  the  given model(s)  in  the
    # collection. This  will occur  when ever  anyone updates  any model  in the
    # system. Either client side or server side.
    @trigger "sync:#{ key }:data", publish

# Backbone#sync
# =============
#
# The  sync method  is  what needs  to  be overridden  inorder  for backbone  to
# communicate  with the  server. Again  all communication  is going  to go  over
# `Faye` so all that  is needed here is to publish the  message accross the wire
# and we are complete. The callbacks won't do anything right now due to how faye
# handles communication.
Backbone.sync = (method, model, success, error) ->
  # This way  we well  will easily  know if  the client  is requesting  a single
  # object or an array of objects.
  method = 'readAll' if model.fayeStorage? 
  store  = model.fayeStorage or model.collection.fayeStorage
  # Wrap what we want to send to the  server in an object NOTE: Other params may
  # be needed to help identify more about what is going on here.
  message = 
    method: method
    model:  model

  # Very simple  pass through  for the  faye server.  No work  is needed  on the
  # client side for any of the operations. We will just pass it through and then
  # update the records on the return message from the server.
  store.write message, success, error

