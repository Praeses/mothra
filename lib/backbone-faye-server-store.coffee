# EventEmitter is Node.js events.
EventEmitter = require( 'events' ).EventEmitter
util = require 'util'
_und = require 'underscore'
# The Sync class will intercept messages from the client
# and if they are on the correct channel then we will
class Sync extends EventEmitter
  
  # When we create a new `Sync` class we are going to connect it to the database
  # and  hook up  some  events  when the  messages  are  received. Each  message
  # received  will fire  off an  event of  the same  name that  will need  to be
  # registered inorder to catch it.
  constructor: ->
    redis  = require('redis')
    @client = redis.createClient()
    _und.bindAll @

    # Hooking in to the `create` event
    @on 'create' , @create
    # Hooking in to the `read` event 
    @on 'read'   , @read
    # Hooking into the `readAll` event ( NOTE: this will call the `read` event )
    @on 'readAll' , @readAll
    # Hooking into the `update` event
    @on 'update' , @update
    # Hooking into the `delete` event
    @on 'delete' , @delete

  # The `incoming` function is an extention  of Faye. This function allows us to
  # view all  messages comming over the  faye stack and do  something with them.
  # The first thing we will want to do is filter out the message.
  incoming: (message, callback) ->
    # By convention all messages that we  are looking for will match the pattern
    # of `/models/and_stuff_we_want`. So any channel that starts with `/models/`
    # ( NOTE:  the slash  at the  start and  end ) we  will want  to keep  to do
    # something with.
    regex = /^\/models\/(\w+)/

    # Now test the channel with the given reg ex
    unless regex.test message.channel
      # If we don't like this channel then use pass it through to the callback
      return callback message
 
    unless message.data?
      return callback message

    # Now we know that the channel we are on is one we want to do something with
    # So we will fire off an event with  the name of the method ( e.g. `create`,
    # `read`, `update`, `destroy` ) and send along the data with it.
    @emit message.data.method, regex.exec( message.channel )[1], message.data.model
    
    # NOTE: we will also pass this message  along to the call back so others can
    # registers to the call back as well
    callback message

  key: (base_key, model) ->
    if model?
      "#{base_key}:#{model.id}"
    else
      base_key 

  create: (base_key, model) ->
    # Create
    that = @
    @client.incr base_key

    @client.get base_key, (err,obj) ->
      model.id = obj
      that.update base_key, model, 'create'

  read: (base_key, model) ->
    # Read
    that = @
    @client.hgetall @key( base_key, model ), (err,obj) ->
      that.publish base_key, obj, 'read'

  readAll: (base_key, collection) ->
    # Read All
    that = @
    @client.keys base_key + ':*', (err,keys) ->
      _und.each(keys, (key) -> 
        parts = key.split ':'
        that.read( parts[0], { id : parts[1] } ) )

  update: (base_key, model, method) ->
    @client.hmset @key( base_key, model ), model
    @publish base_key, model, ( method or 'update' )

  delete: (base_key, model) ->
    @out_log 'delete', base_key, model
    @client.del @key( base_key, model )
    @publish base_key, model, 'delete'

  publish: (channel, data, action) ->
    message = { model : data , method : action }
    @emit 'data', "/server/models/#{channel}", message

   


exports.Sync = Sync
