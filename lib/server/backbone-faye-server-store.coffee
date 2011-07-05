# The Sync
# --------
# The  `Sync`  class  will  handle  the  *CRUD*  from  the  server.  I  will  be
# intercepting any channel that begins with `models` then followed by the name of
# the collection to perform the *CRUD*  actions on. `Sync` uses `redis` for it's
# persistence layer

# Util for the `Sync` class
_und = require 'underscore'
class Sync
  
  # When we create a new `Sync` class we are going to connect it to the database
  # and  hook up  some  events  when the  messages  are  received. Each  message
  # received  will fire  off an  event of  the same  name that  will need  to be
  # registered inorder to catch it.
  constructor: ->
    redis   = require('redis')
    @client = redis.createClient()
    _und.bindAll @

  # Here we are going  to take in a `faye` object and add  this as an extention.
  # This will allow us to be completelty self contained and self managed.
  bind: (bayeux) ->
    @bayeux = bayeux
    @bayeux.addExtension @

  # The `incoming` function is an extention  of Faye. This function allows us to
  # view all  messages comming over the  faye stack and do  something with them.
  # The first thing we will want to do is filter out the message.
  incoming: (message, callback) ->
    # By convention all messages that we  are looking for will match the pattern
    # of `/models/and_stuff_we_want`. So any channel that starts with `/models/`
    # will be processed in the *CRUD* operations.
    regex = /^\/models\/(\w+)/

    # Now test the channel with the given reg ex
    unless regex.test message.channel
      # If we don't like this channel then use pass it through to the callback
      return callback message

    # Now we know that the channel we are on is one we want to do something with
    # So we will call  a method with on the `Sync` class that  has the same name
    # as  the action  that is  giong to  be performed  ( e.g.  `create`, `read`,
    # `update`, `destroy` ) and send along the data with it.
    @[message.data.method] regex.exec( message.channel )[1], message.data.model
    
    # NOTE: we will also pass this message  along to the call back so others can
    # registers to the call back as well.  This is important in `faye` as to not
    # block the communication
    callback message

  # All keys will have the similar pattern of `collection_name:id`.  This will ensure
  # that this pattern is followed.
  key: (base_key, model) -> "#{base_key}:#{model.id}"

  # ### Create
  # The *C* in CRUD.  Create a new object in the redis db.
  create: (base_key, model) ->
    that = @
    # Get the next id
    @client.incr base_key

    @client.get base_key, (err,obj) ->
      model.id = obj
      that.update base_key, model, 'create'

  # ### Read
  # Pull a  single record out  of the database  and send it  on it's way  to all
  # clients. There  is no `read  all` records. It turns  into a bunch  of single
  # reads. This is due to keeping things simple for version one.
  read: (base_key, model) ->
    that = @
    # The data is stored  in a hash ( which is great for  objects ). Here we are
    # pulling all fields for that hash and publishing them back to ALL clients.
    @client.hgetall @key( base_key, model ), (err,obj) ->
      that.publish base_key, obj, 'read'

  # ### Read All
  # Find all of the keys for this collection and read the back to the client one
  # by one. reusing as much code as possible.
  readAll: (base_key, collection) ->
    that = @
    @client.keys base_key + ':*', (err,keys) ->
      _und.each(keys, (key) -> 
        parts = key.split ':'
        that.read( parts[0], { id : parts[1] } ) )

  # ### Update
  # Update a single model.
  update: (base_key, model, method) ->
    @client.hmset @key( base_key, model ), model
    @publish base_key, model, ( method or 'update' )

  # ### Delete
  # Delete a single model
  
  delete: (base_key, model) ->
    that = @
    @client.del @key( base_key, model ), (err,obj) ->
      that.publish base_key, model, 'delete'

  # ### Publish
  # Publish a  model back  to the  collection. NOTE: this  is using  a different
  # channel to publish back on. We are  using two channels so that we won't read
  # on this channel and have a nice little loop.
  publish: (channel, data, action) ->
    message = { model : data , method : action }
    @bayeux.getClient().publish "/server/models/#{channel}", message

# Expose the `Sync` class to the outside world
exports.Sync = Sync
